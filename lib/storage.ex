defmodule Studio.Storage do
	use Silverb, [
		# WARNING !!! these fields always are enums, timestamps, booleans in mysql !!!
		{"@mysql_enums", [:band_kind, :week_day, :kind, :status, :ordered_by]},
		{"@mysql_timestamps", [:stamp]},
		{"@mysql_unixtime", [:time_from, :time_to]},
		{"@mysql_booleans", [:enabled, :fixprice, :can_order, :callback]},
		{"@mysql_structs", %{
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
			}}
	]

	defp transform_values(data = %{}) do
		Enum.reduce(data, %{}, fn
			# TODO : add contacts
			{k,v}, acc when (k in @mysql_enums) -> Map.put(acc, k, String.to_atom(v))
			{k,{:datetime,v}}, acc when (k in @mysql_timestamps) -> Map.put(acc, k, Timex.DateTime.from(v))
			{k,v}, acc when (k in @mysql_unixtime) -> Map.put(acc, k, Timex.DateTime.from_seconds(v))
			{k,0}, acc when (k in @mysql_booleans) -> Map.put(acc, k, false)
			{k,1}, acc when (k in @mysql_booleans) -> Map.put(acc, k, true)
			{k,v}, acc -> Map.put(acc, k, v)
		end)
	end

	defp unmarshal_struct(data = %{}, tab) do
		acc = Map.get(@mysql_structs, tab)
		true = ((acc |> Map.from_struct |> Map.keys |> Enum.sort) == (data |> Map.keys |> Enum.sort))
		Enum.reduce(data, acc, fn({k, v}, acc) -> Map.update!(acc, k, fn(_) -> v end) end)
	end

	def gettab(tab) do
		"SELECT * FROM #{tab};"
		|> Sqlx.exec([], :studio)
		|> Enum.map(&(&1 |> transform_values |> unmarshal_struct(tab)))
	end

end
