defmodule Studio.Loaders.Superadmin do
	use Silverb
	use Cachex, [ttl: 1000, export: true, serialize_on_init: false]
	defp read_callback(_) do
		data = Studio.Storage.fullstate
		hash = Studio.hash(data)
		%{data: %Studio.Proto.Response{status: :RS_ok_state, message: "", state: %Studio.Proto.FullState{data | hash: hash}}, hash: hash}
	end
	defp serialize_callback(%{data: data}) do
		serialized = Studio.encode(data)
		#
		#	TODO : only call clients 2 refresh update 
		#
		:pg2.get_members(:studio_superadmin) |> Enum.each(&(send({:new_state, serialized}, &1)))
		serialized
	end
end
