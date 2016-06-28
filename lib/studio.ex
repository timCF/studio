defmodule Studio.Proto do
	use Protobuf, from: Path.expand("#{Exutils.priv_dir(:studio)}/studio_proto/studio.proto", __DIR__)
end
defmodule Studio do
	use Application
	use Silverb, [
		{"@timex_fields", Studio.Storage.timex_fields}
	]
	require Exutils

	# See http://elixir-lang.org/docs/stable/elixir/Application.html
	# for more information on OTP Applications
	def start(_type, _args) do
		import Supervisor.Spec, warn: false
		Enum.each([:studio_superadmin], &(:ok = :pg2.create(&1)))

		children = [
			worker(Studio.Loaders.Superadmin, [])
		# Define workers and child supervisors to be supervised
		# worker(Studio.Worker, [arg1, arg2, arg3]),
		]

		# See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
		# for other strategies and supported options
		opts = [strategy: :one_for_one, name: Studio.Supervisor]
		Supervisor.start_link(children, opts)
	end

	def hash(some), do: (some |> :erlang.term_to_binary |> :erlang.md5 |> Base.encode64)
	def encode(res = %Studio.Proto.Response{state: state = %Studio.Proto.FullState{}}) do
		%Studio.Proto.Response{res | state: (Map.to_list(state) |> Enum.reduce(%{}, fn({k,v}, acc) -> Map.put(acc, k, encode_process(v)) end))}
		|> Studio.Proto.Response.encode
	end
	def decode(bin) when is_binary(bin) do
		case Studio.Proto.Request.decode(bin) |> Exutils.try_catch do
			req = %Studio.Proto.Request{} -> req
			error -> "error on decoding req #{inspect error} #{inspect :erlang.get_stacktrace}"
		end
	end

	defp encode_process(lst) when is_list(lst) do
		Enum.map(lst, fn
			data = %{} ->
				Map.to_list(data)
				|> Enum.reduce(%{}, fn
					{k,v}, acc when (k in @timex_fields) -> Map.put(acc, k, Timex.to_unix(v))
					{k,v}, acc -> Map.put(acc, k, encode_process(v))
				end)
			data ->
				data
		end)
	end
	defp encode_process(some), do: some

end
