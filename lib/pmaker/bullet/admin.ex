defmodule Studio.Pmaker.Bullet.Admin do
	use Silverb, [
		{"@ping_message", (%Studio.Proto.Response{status: :RS_ok_void, message: "", state: %Studio.Proto.FullState{hash: ""}} |> Studio.encode)}
	]

	def decode(some) when is_binary(some) do
		case Studio.decode(some) do
			data = %Studio.Proto.Request{} -> {:ok, data}
			error -> {:error, error}
		end
	end
	def encode(some), do: Studio.encode(some)
	def handle_pmaker(%Pmaker.Request{ok: true, data: %Studio.Proto.Request{cmd: :CMD_ping}}) do
		%Pmaker.Response{data: @ping_message, encode: false}
	end
	def handle_pmaker(%Pmaker.Request{ok: true, data: req = %Studio.Proto.Request{}}) do
		case Studio.Utils.auth(req) do
			resp = %Studio.Proto.Response{status: :RS_error} -> %Pmaker.Response{data: resp}
			resp = %Studio.Proto.Response{} -> %Pmaker.Response{data: process_request(req, resp)}
		end
	end

	defp process_request(%Studio.Proto.Request{cmd: :CMD_get_state}, resp = %Studio.Proto.Response{}), do: resp
	defp process_request(%Studio.Proto.Request{cmd: cmd, subject: %Studio.Proto.FullState{sessions: [session = %Studio.Proto.Session{}]}}, resp = %Studio.Proto.Response{}) when (cmd in [:CMD_new_session, :CMD_edit_session]) do
		Studio.Worker.session_new_edit(session, cmd)
		#
		#	TODO
		#
		resp
	end

end
