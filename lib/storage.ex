defmodule Studio.Storage do
	use Silverb, [
		# WARNING !!! these fields always are enums, timestamps, booleans in mysql !!!
		{"@mysql_enums", [:band_kind, :week_day, :kind, :status, :ordered_by]},
		{"@mysql_timestamps", [:stamp, :time_from, :time_to]},
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
			"bands",
			"sessions",
			]},
	]

	defp transform_values(data = %{}) do
		Enum.reduce(data, %{}, fn
			{k,v}, acc when (k in @mysql_enums) -> Map.put(acc, k, String.to_atom(v))
			{k,{:datetime,v}}, acc when (k in @mysql_timestamps) -> Map.put(acc, k, Timex.DateTime.from(v))
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
		|> Enum.map(&(&1 |> transform_values |> unmarshal_struct(tab)))
	end

	# returns %{start: ts1, end: ts2} map
	def range(n, metric) when is_integer(n) and (n > 0) and is_binary(metric) do
		[res] = "SELECT CAST(DATE_ADD(NOW(), INTERVAL ? #{metric}) AS CHAR) AS start, CAST(DATE_ADD(NOW(), INTERVAL ? #{metric}) AS CHAR) AS end;" |> Sqlx.exec([ (-1 * n), n ], :studio)
		res
	end

	def fullstate do
		%{start: tss, end: tse} = range(1, "MONTH")
		condition = "WHERE stamp > '#{tss}' AND stamp < '#{tse}'"
		Enum.reduce(@mysql_tabs, %Studio.Proto.ResponseState{}, fn
			tab, acc when (tab in @mysql_tabs_unlim) -> Map.update!(acc, String.to_atom(tab), fn(_) -> gettab(tab, condition) end)
			tab, acc -> Map.update!(acc, String.to_atom(tab), fn(_) -> gettab(tab, "") end)
		end)
	end

end
