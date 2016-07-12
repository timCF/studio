defmodule Studio.Loaders.Superadmin do
	use Silverb, [
		{"@refresh_message", (%Studio.Proto.Response{status: :RS_refresh, message: "", state: %Studio.Proto.FullState{hash: ""}} |> Studio.encode)}
	]
	use Cachex, [ttl: 1000, export: true, serialize_on_init: false]
	defp read_callback(_) do
		data = Studio.Storage.fullstate
		hash = Studio.hash(data)
		%{data: %Studio.Proto.Response{status: :RS_ok_state, message: "", state: %Studio.Proto.FullState{data | hash: hash}}, hash: hash}
	end
	defp serialize_callback(%{}) do
		%Pmaker.Response{
			data: @refresh_message,
			encode: false
		}
		|> Pmaker.send2all("BulletAdmin")
		""
	end
end
