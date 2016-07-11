defmodule Studio.Pmaker.Bullet.Admin do
	use Silverb
	def decode(some) when is_binary(some) do
		case Studio.decode(some) do
			data = %Studio.Proto.Request{} -> {:ok, data}
			error -> {:error, error}
		end
	end
	def encode(some), do: Studio.encode(some)
	def handle_pmaker(%Pmaker.Request{ok: true, data: req = %Studio.Proto.Request{}}) do
		#
		#	TODO !!!
		#
		%Pmaker.Response{
			data: process_request(req),
			encode: false
		}
	end

	defp process_request(req = %{}) do
		case Studio.Utils.auth(req) do
			resp = %Studio.Proto.Response{status: :RS_error} -> Studio.encode(resp)
			%Studio.Proto.Response{} -> Studio.Loaders.Superadmin.get_serialized
		end
	end
end
