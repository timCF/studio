defmodule Studio.Loaders.Superadmin do
	use Silverb, [
		{"@refresh_message", (%Studio.Proto.Response{status: :RS_refresh, message: "", state: %Studio.Proto.FullState{hash: ""}} |> Studio.encode)},
		{"@server_names", (Application.get_env(:pmaker, :servers) |> Enum.map(fn(%{module: module}) -> module end))}
	]
	use Cachex, [ttl: 1000, export: true, serialize_on_init: false]
	defp read_callback(_) do
		data = %Studio.Proto.FullState{sessions: sessions, sessions_template: sessions_template} = Studio.Storage.fullstate
		data = %Studio.Proto.FullState{data | sessions: Enum.sort(sessions, fn(%Studio.Proto.Session{time_from: ts1}, %Studio.Proto.Session{time_from: ts2}) -> ts1 < ts2 end),
							sessions_template: Enum.sort(sessions_template, fn(%Studio.Proto.SessionTemplate{min_from: ts1}, %Studio.Proto.SessionTemplate{min_from: ts2}) -> ts1 < ts2 end)}
		hash = Studio.hash(data)
		%{data: %Studio.Proto.Response{status: :RS_ok_state, message: "", state: %Studio.Proto.FullState{data | hash: hash}}, hash: hash}
	end
	defp serialize_callback(%{}) do
		data = %Pmaker.Response{data: @refresh_message, encode: false}
		Enum.each(@server_names, &(Pmaker.send2all(data, &1)))
		""
	end
end
