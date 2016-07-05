defmodule Studio.WwwestLite do
	use Silverb
	require Logger
	require WwwestLite
	WwwestLite.callback_module do
		def handle_wwwest_lite(%{post_body: pb}) do
			case Studio.decode(pb) do
				req = %Studio.Proto.Request{} ->
					case get_pg2(req) do
						#
						#	TODO
						#
						pg2 ->
							try do
								:ok = :pg2.join(pg2, self)
								process_request(req)
							catch
								error ->
									message = "web error #{inspect error} #{inspect :erlang.get_stacktrace}"
									Logger.error(message)
									message
							rescue
								error ->
									message = "web error #{inspect error} #{inspect :erlang.get_stacktrace}"
									Logger.error(message)
									message
							after
								:ok = :pg2.leave(pg2, self)
							end
					end
				error -> error
			end
		end
	end

	defp get_pg2(req = %{}) do
		#
		#	TODO
		#
		:studio_superadmin
	end

	defp process_request(req = %{}) do
		case Studio.Utils.auth(req) do
			resp = %Studio.Proto.Response{status: :RS_error} -> Studio.encode(resp)
			%Studio.Proto.Response{} -> Studio.Loaders.Superadmin.get_serialized
		end
		#
		#	TODO long polling
		#
	end

end
