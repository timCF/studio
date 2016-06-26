defmodule Studio.Loaders.Superadmin do
	use Silverb
	use Cachex, [ttl: 1000, export: true, serialize_on_init: false]
	defp read_callback(_) do
		data = Studio.Storage.fullstate
		hash = Studio.hash(data)
		%{data: %Studio.Proto.ResponseState{data | hash: hash}, hash: hash}
	end
	defp serialize_callback(%{data: data}), do: Studio.encode(data)
end
