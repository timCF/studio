defmodule Studio.Utils do
	use Silverb
	def date2wd(date) do
		"WD_#{((date |> Timex.days_to_beginning_of_week) + 1) |> Integer.to_string}"
		|> String.to_atom
	end
	def auth(%Studio.Proto.Request{login: login, password: password, client_kind: :CK_admin}) do
		case Studio.Loaders.Superadmin.get(:data) do
			nil -> Studio.error("данные не найдены, возможно проблемы на сервере")
			resp = %Studio.Proto.Response{state: fullstate = %Studio.Proto.FullState{admins: admins}} when is_list(admins) ->
				case Enum.filter(admins, (fn ; %Studio.Proto.Admin{login: ^login, password: ^password, enabled: true} -> true ; %Studio.Proto.Admin{} -> false ; end)) do
					admins = [%Studio.Proto.Admin{login: ^login, password: ^password, enabled: true}] -> %Studio.Proto.Response{resp | status: :RS_ok_state, message: "", state: %Studio.Proto.FullState{fullstate | admins: admins} |> enabled_only}
					[] -> Studio.error("пользователь не авторизован")
				end
		end
	end
	def auth(%Studio.Proto.Request{client_kind: :CK_observer}) do
		case Studio.Loaders.Superadmin.get(:data) do
			nil -> Studio.error("данные не найдены, возможно проблемы на сервере")
			resp = %Studio.Proto.Response{state: fullstate = %Studio.Proto.FullState{}} -> %Studio.Proto.Response{resp | status: :RS_ok_state, message: "", state: %Studio.Proto.FullState{fullstate | admins: []} |> enabled_only}
		end
	end
	def enabled_only(state = %Studio.Proto.FullState{}) do
		Map.from_struct(state)
		|> Map.keys
		|> Enum.reduce(state, fn(k, acc = %Studio.Proto.FullState{}) ->
			Map.update!(acc, k, fn
				lst = [_|_] ->
					Enum.filter(lst, fn
						%{enabled: false} -> false
						_ -> true
					end)
				some ->
					some
			end)
		end)
	end
	def future_dates_seq(wd) do
		now = Timex.DateTime.today( Studio.timezone )
		Stream.map(0..60, &(Timex.shift(now, [days: &1])))
		|> Enum.filter(&(wd == Studio.Utils.date2wd(&1)))
	end
	def session_from_template(%Studio.Proto.SessionTemplate{min_from: min_from, min_to: min_to, week_day: wd, room_id: room_id, instruments_ids: instruments_ids, band_id: band_id, description: description}, date) do
		%Studio.Proto.Session{
			time_from: 1000 * (Timex.shift(date, [minutes: min_from]) |> Timex.DateTime.to_seconds),
			time_to: 1000 * (Timex.shift(date, [minutes: min_to]) |> Timex.DateTime.to_seconds),
			week_day: wd,
			room_id: room_id,
			instruments_ids: instruments_ids,
			band_id: band_id,
			callback: false,
			status: :SS_awaiting_first,
			amount: 0,
			price: 0,
			description: description,
			ordered_by: :SO_auto,
			admin_id_open: 0,
			admin_id_close: 0,
			transaction_id: 0
		}
	end

	def derive_session_price(this_session = %Studio.Proto.Session{room_id: room_id, band_id: band_id}, %Studio.Proto.FullState{rooms: rooms, sessions: sessions, discount_const: discount_const, bands: bands, instruments: instruments}) do
		[this_room = %Studio.Proto.Room{}] = Enum.filter(rooms, fn(%Studio.Proto.Room{id: id}) -> id == room_id end)
		[this_band = %Studio.Proto.Band{}] = Enum.filter(bands, fn(%Studio.Proto.Band{id: id}) -> id == band_id end)
		derive_instruments_price(this_session, instruments) + derive_session_price_process(this_session, this_band, this_room, get_max_sessions_num_around(this_session, sessions), discount_const)
	end
	defp get_max_sessions_num_around(%Studio.Proto.Session{id: id, band_id: band_id, time_from: time_from}, sessions) do
		Stream.map((-30)..0, fn(n) -> ((0+n)..(30+n)) |> Enum.map(&(Timex.DateTime.shift(time_from, [days: &1]))) end)
		|> Stream.map(fn(seq) ->
			(Enum.filter(sessions, fn
				%Studio.Proto.Session{id: ^id} ->
					false
				%Studio.Proto.Session{band_id: ^band_id, time_from: this_time, status: status} when (status in [:SS_awaiting_first, :SS_closed_ok]) ->
					Enum.any?(seq, &(Timex.DateTime.to_days(&1) == Timex.DateTime.to_days(this_time)))
				%Studio.Proto.Session{} ->
					false
			end) |> length) + 1
		end)
		|> Enum.max
	end

	defmacrop maybe_filter_discount(lst, field, val2dim) do
		quote location: :keep do
			case Enum.filter(unquote(lst), fn(%Studio.Proto.DiscountConst{ unquote(field) => val }) -> val != unquote(val2dim) end) do
				[] -> unquote(lst)
				newlst = [_|_] -> newlst
			end
		end
	end

	defmacrop maximize_discount_by(lst, field) do
		quote location: :keep do
			%Studio.Proto.DiscountConst{ unquote(field) => trueval } = Enum.max_by(unquote(lst), fn(%Studio.Proto.DiscountConst{ unquote(field) => val }) -> val end)
			Enum.filter(unquote(lst), fn(%Studio.Proto.DiscountConst{ unquote(field) => val }) -> val == trueval end)
		end
	end

	defp derive_session_price_process(%Studio.Proto.Session{time_from: time_from = %Timex.DateTime{hour: hour, minute: minute}, time_to: time_to, week_day: swd}, %Studio.Proto.Band{kind: bk}, %Studio.Proto.Room{id: this_room, price_base: price_base}, sessions_around_num, discount_const) when is_list(discount_const) do
		min_from = (60 * hour) + minute
		[true_discount] = Enum.filter(discount_const, fn
			%Studio.Proto.DiscountConst{min_from: mf, number_from: nf, room_id: room_id, week_day: wd, band_kind: ^bk}
				when ((mf <= min_from) and (nf <= sessions_around_num) and ((room_id == 0) or (room_id == this_room)) and ((wd == :WD_default) or (wd == swd))) -> true
			%Studio.Proto.DiscountConst{} -> false
		end)
		|> maybe_filter_discount(:room_id, 0)
		|> maybe_filter_discount(:week_day, :WD_default)
		|> maximize_discount_by(:min_from)
		|> maximize_discount_by(:number_from)
		session_duration = Timex.diff(time_from, time_to, :hours)
		case true_discount do
			%Studio.Proto.DiscountConst{amount: amount, fixprice: true} -> amount * (session_duration / 3)
			%Studio.Proto.DiscountConst{amount: amount, fixprice: false} -> (price_base - amount) * (session_duration / 3)
		end
		|> round
		|> abs
	end
	defp derive_instruments_price(%Studio.Proto.Session{instruments_ids: ids}, instruments) do
		Stream.filter(instruments, fn(%Studio.Proto.Instrument{id: id}) -> Enum.member?(ids, id) end)
		|> Enum.reduce(0, fn(%Studio.Proto.Instrument{price: price}, acc) -> price + acc end)
	end

end
defmodule Studio.Checks.Session do
	defstruct action: nil, # :save | :update | :error
			message: "",
			session_id: nil
end
