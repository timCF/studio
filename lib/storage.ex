defmodule Studio.Storage do
	use Pipe
	require Logger
	use Silverb, [
		# WARNING !!! these fields always are enums, timestamps, booleans in mysql !!!
		{"@mysql_enums", [:band_kind, :week_day, :kind, :status, :ordered_by]},
		{"@mysql_timestamps", [:stamp, :time_from, :time_to, :active_from]},
		{"@mysql_unixtime", []},
		{"@mysql_booleans", [:enabled, :fixprice, :can_order, :callback]},
		{"@mysql_jsons", [:contacts, :instruments_ids]},
		{"@mysql_structs", %{
				"contacts" => %Studio.Proto.Contacts{},
				"admins" => %Studio.Proto.Admin{},
				"locations" => %Studio.Proto.Location{},
				"rooms" => %Studio.Proto.Room{},
				"discount_const" => %Studio.Proto.DiscountConst{},
				"instruments" => %Studio.Proto.Instrument{},
				"stuff2sell" => %Studio.Proto.Stuff2Sell{},
				"transactions" => %Studio.Proto.Transaction{},
				"bands" => %Studio.Proto.Band{},
				"sessions" => %Studio.Proto.Session{},
				"sessions_template" => %Studio.Proto.SessionTemplate{},
			}},
		{"@mysql_tabs", [
			"admins",
			"locations",
			"rooms",
			"discount_const",
			"instruments",
			"stuff2sell",
			"transactions",
			"bands",
			"sessions",
			"sessions_template",
			]},
		{"@mysql_tabs_unlim", [
			"transactions",
			"sessions",
			]},
		{"@end_status", ["SS_closed_auto","SS_closed_ok","SS_canceled_hard"]}, # if alreaty was payment
		{"@allowed_session_structs", [Studio.Proto.Session, Studio.Proto.SessionTemplate]},
	]

	defp transform_values(data = %{}) do
		Enum.reduce(data, %{}, fn
			{k,v}, acc when (k in @mysql_enums) -> Map.put(acc, k, String.to_atom(v))
			{k,{:datetime,v}}, acc when (k in @mysql_timestamps) -> Map.put(acc, k, Timex.DateTime.from(v))
			{k,v}, acc when (k in @mysql_timestamps) -> Map.put(acc, k, Timex.DateTime.set(v, [timezone: Studio.timezone]))
			# {k,v}, acc when (k in @mysql_unixtime) -> Map.put(acc, k, Timex.DateTime.from_seconds(v))
			{k,0}, acc when (k in @mysql_booleans) -> Map.put(acc, k, false)
			{k,1}, acc when (k in @mysql_booleans) -> Map.put(acc, k, true)
			{k,v}, acc when (k in @mysql_jsons) ->
				case Jazz.decode!(v, [keys: :atoms]) do
					map = %{} -> Map.put(acc, k, unmarshal_struct(map, Atom.to_string(k)))
					lst when is_list(lst) -> Map.put(acc, k, lst)
				end
			{k,v}, acc -> Map.put(acc, k, v)
		end)
	end

	defp untransform_values(data = %{}) do
		Map.from_struct(data)
		|> Enum.reduce(%{}, fn
			{k,v}, acc when (k in @mysql_enums) -> Map.put(acc, k, Maybe.maybe_to_string(v))
			{k,v}, acc when is_integer(v) and (k in @mysql_timestamps) -> Map.put(acc, k, (Timex.DateTime.from_milliseconds(v) |> Timex.Timezone.convert(Studio.timezone) |> Timex.format!("{ISO:Extended}")))
			# {k,v}, acc when (k in @mysql_unixtime) -> Map.put(acc, k, Timex.DateTime.from_seconds(v))
			# {k,0}, acc when (k in @mysql_booleans) -> Map.put(acc, k, false)
			# {k,1}, acc when (k in @mysql_booleans) -> Map.put(acc, k, true)
			{k,v}, acc when is_list(v) and (k in @mysql_jsons) -> Map.put(acc, k, Jazz.encode!(v))
			{k,v}, acc when is_map(v) and (k in @mysql_jsons) -> Map.put(acc, k, Jazz.encode!( Map.from_struct(v) ))
			{k,v}, acc -> Map.put(acc, k, v)
		end)
	end

	defp unmarshal_struct(data = %{}, tab) do
		acc = Map.get(@mysql_structs, tab)
		true = ((acc |> Map.from_struct |> Map.keys |> Enum.sort) == (data |> Map.keys |> Enum.sort))
		Enum.reduce(data, acc, fn({k, v}, acc) -> Map.update!(acc, k, fn(_) -> v end) end)
	end

	#
	#	public
	#

	def timex_fields, do: (@mysql_timestamps ++ @mysql_unixtime)

	def gettab(tab, condition) do
		"SELECT * FROM #{tab} #{condition};"
		|> Sqlx.exec([], :studio)
		|> Enum.map(&(&1 |> Map.delete(:created_at) |> transform_values |> unmarshal_struct(tab)))
	end

	# returns %{start: ts1, end: ts2} map
	def range(n, metric) when is_integer(n) and (n > 0) and is_binary(metric) do
		[res] = "SELECT CAST(DATE_ADD(NOW(), INTERVAL ? #{metric}) AS CHAR) AS start, CAST(DATE_ADD(NOW(), INTERVAL ? #{metric}) AS CHAR) AS end;" |> Sqlx.exec([ (-1 * n), n ], :studio)
		res
	end

	defp get_ts_field("transactions"), do: "stamp"
	defp get_ts_field("sessions"), do: "time_from"

	def fullstate do
		%{start: tss, end: tse} = range(1, "MONTH")
		Enum.reduce(@mysql_tabs, %Studio.Proto.FullState{}, fn
			tab, acc when (tab in @mysql_tabs_unlim) ->
				condition = "#{get_ts_field(tab)} > '#{tss}' AND #{get_ts_field(tab)} < '#{tse}'"
				condition = case tab do
											"sessions" -> "(#{condition}) OR ((#{get_ts_field(tab)} >= '#{tse}') AND (ordered_by != 'SO_auto'))"
											_ -> condition
										end
				Map.update!(acc, String.to_atom(tab), fn(_) -> gettab(tab, "WHERE "<>condition<>" ORDER BY id DESC") end)
			tab, acc -> Map.update!(acc, String.to_atom(tab), fn(_) -> gettab(tab, "") end)
		end)
	end

	# checks session can be saved / updated ... action is :save | :update | :error
	def can_session_be_saved(session = %Studio.Proto.Session{time_from: tf, time_to: tt, band_id: band_id}) when (tf < tt) do
		tf = Studio.ts2mysql(tf)
		tt = Studio.ts2mysql(tt)
		"""
		SELECT id, band_id, room_id, instruments_ids, status FROM sessions WHERE
			(
				(time_from >= ? AND time_to <= ?) OR
				(time_from >= ? AND time_from < ?) OR
				(time_to > ? AND time_to <= ?)
			)
			AND
			(
				(status IN (?)) OR
				((band_id = ?) AND (status = ?))
			);
		"""
		|> Sqlx.exec([tf,tt,tf,tt,tf,tt,["SS_awaiting_first","SS_closed_ok"],band_id,"SS_canceled_soft"], :studio)
		|> Enum.map(fn(el) -> Map.update!(el, :instruments_ids, &Jazz.decode!/1) end)
		|> can_session_be_saved_process(session)
	end
	def can_session_be_saved(%Studio.Proto.Session{}), do: %Studio.Checks.Session{action: :error, message: "введены неверные данные"}

	def can_session_be_saved_auto(%Studio.Proto.Session{time_from: tf, time_to: tt, band_id: band_id, room_id: room_id}) when (tf < tt) do
		tf = Studio.ts2mysql(tf)
		tt = Studio.ts2mysql(tt)
		case	"""
					SELECT id FROM sessions WHERE
						(
							(time_from <= ? AND time_to >= ?) OR
							(time_from >= ? AND time_to <= ?) OR
							(time_from >= ? AND time_from < ?) OR
							(time_to > ? AND time_to <= ?)
						)
						AND band_id = ?
						AND ( (room_id = ?) OR ((room_id != ?) AND (status = ?)) );
					"""
					|> Sqlx.exec([tf,tt,tf,tt,tf,tt,tf,tt,band_id,room_id,room_id,"SS_awaiting_first"], :studio) do
				[] -> true
				_ -> false
		end
	end
	def can_session_be_saved_auto(some) do
		_ = Logger.error("can_session_be_saved_auto wrong data #{inspect some}")
		false
	end

	#
	#	these functions are generic for sessions and session_templates
	#
	defp can_session_be_saved_process([], session = %{:__struct__ => struct}) when (struct in @allowed_session_structs) do
		%Studio.Checks.Session{action: :save, message: "", session_id: nil}
		|> maybe_set_session_id(session)
	end
	defp can_session_be_saved_process(lst = [_|_], session = %{:__struct__ => struct}) when (struct in @allowed_session_structs) do
		(
			pipe_matching %Studio.Checks.Session{action: nil},
			%Studio.Checks.Session{action: nil}
			|> maybe_set_session_id(session)
			|> check_instruments_overlap(lst, session)
			|> check_rooms_overlap(lst, session)
		)
		|> maybe_deny_future(session)
	end
	defp maybe_set_session_id(acc = %Studio.Checks.Session{}, %Studio.Proto.Session{id: id}) when is_integer(id), do: %Studio.Checks.Session{acc | session_id: id}
	defp maybe_set_session_id(acc = %Studio.Checks.Session{}, %{}), do: acc
	defp check_instruments_overlap(acc = %Studio.Checks.Session{}, lst = [_|_], %{:__struct__ => struct, band_id: bid, instruments_ids: iids}) when (struct in @allowed_session_structs) do
		Stream.filter(lst, fn(%{band_id: band_id}) -> (band_id != bid) end)
		|> Enum.reduce_while(acc, fn(%{instruments_ids: instruments_ids}, acc = %Studio.Checks.Session{}) ->
			case Enum.filter(instruments_ids, fn(id) -> Enum.member?(iids, id) end) do
				[] -> {:cont, acc}
				[_|_] -> {:halt, %Studio.Checks.Session{acc | action: :error, message: "выбранные инструменты уже используются в это время"}}
			end
		end)
	end
	defp check_rooms_overlap(acc = %Studio.Checks.Session{}, lst = [_|_], %{:__struct__ => struct, band_id: bid, room_id: rid}) when (struct in @allowed_session_structs) do
		case Enum.filter(lst, fn(%{band_id: band_id, room_id: room_id}) -> (band_id != bid) and (room_id == rid) end) do
			[_|_] -> %Studio.Checks.Session{acc | action: :error, message: "другая группа уже репетирует в это время"}
			[] ->
				case Enum.filter(lst, fn(%{band_id: band_id}) -> (band_id == bid) end) do
					[] -> %Studio.Checks.Session{acc | action: :save}
					[%{status: status}] when (status in @end_status) -> %Studio.Checks.Session{acc | action: :error, message: "репетиция в это время уже закрыта"}
					[%{id: id, status: status}] -> %Studio.Checks.Session{acc | action: :update, session_id: id, db_sess_status: Maybe.to_atom(status)}
					# this case for session template
					[%{id: id}] -> %Studio.Checks.Session{acc | action: :update, session_id: id}
					[_|_] -> %Studio.Checks.Session{acc | action: :error, message: "данная группа уже репетирует в это время более одной сессии"}
				end
		end
	end
	defp maybe_deny_future(acc = %Studio.Checks.Session{}, %Studio.Proto.Session{status: :SS_closed_ok, time_from: tf}) do
		case (tf |> Timex.DateTime.from_milliseconds |> Timex.Timezone.convert(Studio.timezone) |> Timex.DateTime.to_seconds) > (Studio.now |> Timex.DateTime.to_seconds) do
			true -> %Studio.Checks.Session{acc | action: :error, message: "сессии из будущего закрывать запрещено"}
			false -> acc
		end
	end
	defp maybe_deny_future(acc = %Studio.Checks.Session{}, %{:__struct__ => struct}) when (struct in @allowed_session_structs), do: acc
	#
	#	these functions are generic for sessions and session_templates
	#

	def save_session(session = %Studio.Proto.Session{}) do
		session = untransform_values(session) |> Map.delete(:id) |> Map.delete(:stamp)
		keys = Map.keys(session)
		case	"INSERT INTO sessions (#{ ["created_at"|keys] |> Enum.join(",") }) VALUES (?);"
				|> Sqlx.exec([[ (Studio.now |> Timex.format!("{YYYY}-{0M}-{0D} {0h24}:{0m}:{0s}")) | Enum.map(keys, &(Map.get(session,&1))) ]], :studio) do
			%{error: []} -> :ok
			error -> {:error, error}
		end
	end

	def update_session(raw_session = %Studio.Proto.Session{id: id, status: this_status}) when is_integer(id) do
		session = untransform_values(raw_session) |> Map.delete(:stamp)
		keys = Map.keys(session)
		[%{status: prev_status}] = Sqlx.exec("SELECT status FROM sessions WHERE id = ?;", [id], :studio)
		case Sqlx.insert_duplicate([session], keys, [id], "sessions", :studio) do
			%{error: []} ->
				case (Maybe.maybe_to_string(prev_status) == Maybe.maybe_to_string(this_status)) do
					true -> :ok
					false -> update_session_apply_balance(raw_session)
				end
			error -> {:error, error}
		end
	end

	defp update_session_apply_balance(%Studio.Proto.Session{status: status, amount: amount, price: price, band_id: band_id}) when (status in [:SS_canceled_hard, :SS_closed_ok]) do
		result_diff = (case status do ; :SS_canceled_hard -> abs(price) ; _ -> (abs(price) - abs(amount)) ; end)
		case "UPDATE bands SET balance = (balance - (?)) WHERE id = ?;" |> Sqlx.exec([result_diff, band_id], :studio) do
			%{error: []} -> :ok
			error -> {:error, error}
		end
	end
	defp update_session_apply_balance(%Studio.Proto.Session{}), do: :ok

	def can_band_be_saved(%Studio.Proto.Band{id: id, name: name, person: person, contacts: %Studio.Proto.Contacts{phones: [_|_]}}) do
		case "SELECT id FROM bands WHERE name = ? AND person = ?;" |> Sqlx.exec([name, person], :studio) do
			[] -> true
			[%{id: ^id}] when is_integer(id) and (id > 0) -> true
			[_|_] -> "группа с именем '#{name}' и контактным лицом '#{person}' уже существует"
		end
	end

	def band_new(data = %Studio.Proto.Band{}) do
		data = untransform_values(data) |> Map.delete(:id) |> Map.delete(:stamp)
		keys = Map.keys(data)
		case	"INSERT INTO bands (#{ Enum.join(keys, ",") }) VALUES (?);"
				|> Sqlx.exec([ Enum.map(keys, &(Map.get(data,&1))) ], :studio) do
			%{error: []} -> :ok
			error -> {:error, error}
		end
	end
	def band_update(data = %Studio.Proto.Band{}) do
		data = %{id: id} = untransform_values(data) |> Map.delete(:stamp)
		keys = Map.keys(data)
		case Sqlx.insert_duplicate([data], keys, [id], "bands", :studio) do
			%{error: []} -> :ok
			error -> {:error, error}
		end
	end

	defmacrop non_neg_integer(some) do
		quote location: :keep do
			(is_integer(unquote(some)) and (unquote(some) >= 0))
		end
	end

	def can_session_template_be_saved(data = %Studio.Proto.SessionTemplate{min_from: mf, min_to: mt, week_day: wd}) when (non_neg_integer(mf) and non_neg_integer(mt) and (mt > mf)) do
		"""
		SELECT id, band_id, room_id, instruments_ids FROM sessions_template WHERE
			(
				(min_from >= ? AND min_to <= ?) OR
				(min_from >= ? AND min_from < ?) OR
				(min_to > ? AND min_to <= ?)
			)
			AND week_day = ?;
		"""
		|> Sqlx.exec([mf,mt,mf,mt,mf,mt,Atom.to_string(wd)], :studio)
		|> Enum.map(fn(el) -> Map.update!(el, :instruments_ids, &Jazz.decode!/1) end)
		|> can_session_be_saved_process(data)
	end
	def can_session_template_be_saved(%Studio.Proto.SessionTemplate{}), do: %Studio.Checks.Session{action: :error, message: "введены неверные данные"}

	def generic_data_new(data = %{}, table) when is_binary(table) do
		data = untransform_values(data) |> Map.delete(:id) |> Map.delete(:stamp)
		keys = Map.keys(data)
		case	"INSERT INTO #{table} (#{ Enum.join(keys, ",") }) VALUES (?);"
				|> Sqlx.exec([ Enum.map(keys, &(Map.get(data,&1))) ], :studio) do
			%{error: []} -> :ok
			error -> {:error, error}
		end
	end
	def generic_data_update(data = %{}, table) when is_binary(table) do
		data = %{id: id} = untransform_values(data) |> Map.delete(:stamp)
		keys = Map.keys(data)
		case Sqlx.insert_duplicate([data], keys, [id], table, :studio) do
			%{error: []} -> :ok
			error -> {:error, error}
		end
	end

	def delete_from_table(id, table, resp = %Studio.Proto.Response{}) when (non_neg_integer(id) and is_binary(table)) do
		case "DELETE FROM #{table} WHERE id = ?;" |> Sqlx.exec([id], :studio) do
			%{error: []} -> %Studio.Proto.Response{resp | status: :RS_notice, message: "запись из таблицы #{table} удалена"}
			error -> %Studio.Proto.Response{resp | status: :RS_error, message: "ошибка при удалении записи из таблицы #{table}, запишите её и обратитесь к разработчику #{inspect error}"}
		end
	end

	def delete_auto_sessions_like_this(templ = %Studio.Proto.SessionTemplate{week_day: wd}) do
		Studio.Utils.future_dates_seq(wd)
		|> Enum.each(fn(date) ->
			%Studio.Proto.Session{
				week_day: ^wd,
				room_id: room_id,
				band_id: band_id,
				status: status = :SS_awaiting_first,
				ordered_by: ob = :SO_auto
			} = Studio.Utils.session_from_template(templ, date)
			%{error: []} = """
			DELETE FROM sessions WHERE
				week_day = ? AND
				room_id = ? AND
				band_id = ? AND
				status = ? AND
				ordered_by = ?;
			"""
			|> Sqlx.exec([Atom.to_string(wd), room_id, band_id, Atom.to_string(status), Atom.to_string(ob)], :studio)
		end)
	end

	def maybe_update_session_amount(%Studio.Proto.Session{id: id, week_day: wd, room_id: room_id, instruments_ids: instruments_ids, band_id: band_id, status: status, amount: amount, price: price, ordered_by: ob, transaction_id: transaction_id}) do
		%{error: []} = """
		UPDATE sessions
		SET
			amount = ?,
			price = ?
		WHERE
			id = ? AND
			week_day = ? AND
			room_id = ? AND
			instruments_ids = ? AND
			band_id = ? AND
			status = ? AND
			ordered_by = ? AND
			transaction_id = ?;
		"""
		|> Sqlx.exec([amount, price, id, Atom.to_string(wd), room_id, Jazz.encode!(instruments_ids), band_id, Atom.to_string(status), Atom.to_string(ob), transaction_id], :studio)
	end

	def statistics(sr = %Studio.Proto.StatisticsRequest{time_from: time_from, time_to: time_to}) do
		"""
		SELECT
			amount, price, status FROM sessions
		WHERE
			time_from >= ? AND
			time_to <= ?
			#{make_location_pred(sr)};
		"""
		|> Sqlx.exec([Studio.ts2mysql(time_from), Studio.ts2mysql(time_to)], :studio)
		|> Enum.reduce(%Studio.Proto.Statistics{cash_prices: 0, cash_input: 0, sessions_all: 0, sessions_opened: 0, sessions_closed: 0, sessions_cancel_soft: 0, sessions_cancel_hard: 0}, fn
			%{status: "SS_awaiting_first"}, acc = %Studio.Proto.Statistics{sessions_all: sa, sessions_opened: so} ->
				%Studio.Proto.Statistics{acc | sessions_all: sa + 1, sessions_opened: so + 1}
			%{status: "SS_closed_ok", price: price, amount: amount}, acc = %Studio.Proto.Statistics{sessions_all: sa, sessions_closed: sc, cash_prices: cash_prices, cash_input: cash_input} ->
				%Studio.Proto.Statistics{acc | sessions_all: sa + 1, sessions_closed: sc + 1, cash_prices: cash_prices + price, cash_input: cash_input + amount}
			%{status: "SS_canceled_soft"}, acc = %Studio.Proto.Statistics{sessions_all: sa, sessions_cancel_soft: sc} ->
				%Studio.Proto.Statistics{acc | sessions_all: sa + 1, sessions_cancel_soft: sc + 1}
			%{status: "SS_canceled_hard", price: price}, acc = %Studio.Proto.Statistics{sessions_all: sa, sessions_cancel_hard: sc, cash_prices: cash_prices} ->
				%Studio.Proto.Statistics{acc | sessions_all: sa + 1, sessions_cancel_hard: sc + 1, cash_prices: cash_prices + price}
			some = %{}, acc = %Studio.Proto.Statistics{sessions_all: sa} ->
				_ = Logger.error("unexpected statistics element #{inspect some}")
				%Studio.Proto.Statistics{acc | sessions_all: sa + 1}
		end)
		|> statistics_transactions(sr)
	end

	defp statistics_transactions(acc = %Studio.Proto.Statistics{}, %Studio.Proto.StatisticsRequest{time_from: time_from, time_to: time_to, location_id: location_id}) do
		"""
		SELECT
			cash_in, cash_out FROM transactions
		WHERE
			stamp >= ? AND
			stamp <= ?
			#{(case is_integer(location_id) do ; true -> " AND location_id = #{Integer.to_string(location_id)};" ; false -> ";" ; end)}
		"""
		|> Sqlx.exec([Studio.ts2mysql(time_from), Studio.ts2mysql(time_to)], :studio)
		|> Enum.reduce(%Studio.Proto.Statistics{acc | transactions_cash_prices: 0, transactions_cash_input: 0},
			fn(%{cash_in: cash_in, cash_out: cash_out}, acc = %Studio.Proto.Statistics{transactions_cash_prices: transactions_cash_prices, transactions_cash_input: transactions_cash_input}) ->
				%Studio.Proto.Statistics{acc | transactions_cash_prices: transactions_cash_prices + cash_out, transactions_cash_input: transactions_cash_input + cash_in}
			end)
		|> statistics_finalize
	end

	defp statistics_finalize(acc = %Studio.Proto.Statistics{cash_prices: cash_prices, cash_input: cash_input, transactions_cash_prices: transactions_cash_prices, transactions_cash_input: transactions_cash_input}) do
		%Studio.Proto.Statistics{acc | all_cash_prices: (cash_prices + transactions_cash_prices), all_cash_input: (cash_input + transactions_cash_input)}
	end

	defp make_location_pred(%Studio.Proto.StatisticsRequest{room_id: room_id}) when is_integer(room_id), do: "AND room_id = #{Integer.to_string(room_id)}"
	defp make_location_pred(%Studio.Proto.StatisticsRequest{location_id: location_id}) when is_integer(location_id) do
		%Studio.Proto.Response{state: %Studio.Proto.FullState{rooms: rooms = [_|_]}} = Studio.Loaders.Superadmin.get(:data)
		"AND room_id IN (#{ Stream.filter_map(rooms, fn(%Studio.Proto.Room{location_id: id}) -> id == location_id end, fn(%Studio.Proto.Room{id: id}) -> Integer.to_string(id) end) |> Enum.join(",") })"
	end
	defp make_location_pred(%Studio.Proto.StatisticsRequest{}), do: ""

	def get_overdue_sessions do
		"""
		SELECT #{ %Studio.Proto.Session{} |> Map.from_struct |> Map.keys |> Enum.join(",") }
		FROM sessions
		WHERE
			status = ? AND
			time_to < DATE_ADD(NOW(), INTERVAL ? HOUR);
		"""
		|> Sqlx.exec(["SS_awaiting_first", -1], :studio)
		|> Enum.map(&(&1 |> transform_values |> unmarshal_struct("sessions")))
	end

	# this case subject_id is band_id
	def new_transaction(tr = %Studio.Proto.Transaction{amount: amount, cash_in: cin, cash_out: cout, subject_id: id, kind: kind}) when (amount == (cin - cout)) and (kind in [:TK_band_room, :TK_band_instrument, :TK_band_deposit, :TK_band_punishment, :TK_sell, :TK_bonus]) do
		data = untransform_values(tr)
		%{error: []} = Sqlx.exec("UPDATE bands SET balance = balance + ? WHERE id = ?;", [amount, id], :studio)
		%{error: []} = Sqlx.insert([data], Enum.filter_map(data, fn({_,v}) -> v != nil end, fn({k,_}) -> k end), "transactions", :studio)
		:ok
	end

end
