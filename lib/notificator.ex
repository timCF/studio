defmodule Studio.Notificator do
	require Logger
	use Silverb, [
		{"@ttl", :timer.minutes(5)},
		{"@server_names", (Application.get_env(:pmaker, :servers) |> Enum.map(fn(%{module: module}) -> module end))},
		{"@timex_format", "{YYYY}-{0M}-{0D}"}, # {0h24}:{0m}:{0s}
	]
	use ExActor.GenServer, export: :studio_notificator
	definit do
		{:ok, nil, 5000}
	end
	definfo :timeout do
		case Studio.Storage.get_overdue_sessions do
			[] -> :ok
			lst = [%Studio.Proto.Session{}|_] ->
				%Studio.Proto.Response{state: %Studio.Proto.FullState{rooms: rooms, locations: locations}} = Studio.Loaders.Superadmin.get(:data)
				locations_of_rooms = Enum.reduce(rooms, %{}, fn(%Studio.Proto.Room{id: id, location_id: lid}, acc = %{}) -> Map.put(acc, id, lid) end)
				Enum.group_by(lst, fn(%Studio.Proto.Session{room_id: rid}) -> Map.get(locations_of_rooms, rid) end)
				|> Enum.each(fn({lid, lst = [_|_]}) ->
					message = %Pmaker.Response{data: (%Studio.Proto.Response{status: :RS_warn,
						destination_location_id: [lid],
						message: get_location_text(locations, lid)<>" "<>get_msg_text(lst),
						state: %Studio.Proto.FullState{hash: ""}} |> Studio.encode), encode: false}
					Enum.each(@server_names, &(Pmaker.send2all(message, &1)))
				end)
		end
		{:noreply, nil, @ttl}
	end

	defp get_msg_text([%Studio.Proto.Session{time_from: time_from}]), do: "есть не закрытая вовремя репетиция за #{ Timex.format!(time_from, @timex_format) }"
	defp get_msg_text(lst = [%Studio.Proto.Session{time_from: time_from}|_]), do: "есть не закрытая вовремя репетиция за #{ Timex.format!(time_from, @timex_format) } и ещё #{ length(lst) - 1 } других"

	defp get_location_text(locations = [_|_], lid) do
		[%Studio.Proto.Location{name: name}] = Enum.filter(locations, fn(%Studio.Proto.Location{id: id}) -> id == lid end)
		"на базе #{name}"
	end

end
