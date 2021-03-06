Enum.each([Studio.Pmaker.Bullet.Admin, Studio.Pmaker.Bullet.Observer], fn(module) ->

	defmodule module do
		require Logger
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
		def handle_pmaker(req = %Pmaker.Request{}) do
			#Logger.info("REQUEST #{inspect req}")
			resp = handle_pmaker_proc(req)
			#Logger.info("RESPONSE #{inspect resp}")
			resp
		end

		defp handle_pmaker_proc(%Pmaker.Request{ok: true, data: %Studio.Proto.Request{cmd: :CMD_ping}}) do
			%Pmaker.Response{data: @ping_message, encode: false}
		end
		defp handle_pmaker_proc(%Pmaker.Request{ok: true, data: req = %Studio.Proto.Request{client_kind: :CK_admin}}) do
			case Studio.Utils.auth(req) do
				resp = %Studio.Proto.Response{status: :RS_error} -> %Pmaker.Response{data: resp}
				resp = %Studio.Proto.Response{} -> %Pmaker.Response{data: process_request(req, resp)}
			end
		end
		defp handle_pmaker_proc(%Pmaker.Request{ok: true, data: req = %Studio.Proto.Request{client_kind: :CK_observer}}) do
			%Pmaker.Response{data: Studio.Utils.auth(req)}
		end

		defp process_request(%Studio.Proto.Request{cmd: :CMD_get_state}, resp = %Studio.Proto.Response{}), do: resp
		defp process_request(%Studio.Proto.Request{cmd: cmd, subject: %Studio.Proto.FullState{sessions: [session = %Studio.Proto.Session{}]}}, resp = %Studio.Proto.Response{}) when (cmd in [:CMD_new_session, :CMD_edit_session]) do
			Studio.Worker.session_new_edit(session, cmd, resp)
		end
		defp process_request(%Studio.Proto.Request{cmd: :CMD_band_new_edit, subject: %Studio.Proto.FullState{bands: [band = %Studio.Proto.Band{}]}}, resp = %Studio.Proto.Response{}) do
			Studio.Worker.band_new_edit(band, resp)
		end
		defp process_request(%Studio.Proto.Request{cmd: :CMD_week_template_new_edit, subject: %Studio.Proto.FullState{sessions_template: [data = %Studio.Proto.SessionTemplate{}]}}, resp = %Studio.Proto.Response{}) do
			Studio.Worker.session_template_new_edit(data, resp)
		end
		defp process_request(%Studio.Proto.Request{cmd: :CMD_week_template_new_edit_from_session, subject: %Studio.Proto.FullState{sessions_template: [data = %Studio.Proto.SessionTemplate{}]}}, resp = %Studio.Proto.Response{}) do
			Studio.Worker.session_template_new_edit(data, resp)
		end
		defp process_request(%Studio.Proto.Request{cmd: :CMD_week_template_disable, subject: %Studio.Proto.FullState{sessions_template: [%Studio.Proto.SessionTemplate{id: id}]}}, resp = %Studio.Proto.Response{}) when is_integer(id) do
			Studio.Worker.delete_from_table(id, "sessions_template", resp)
		end
		defp process_request(%Studio.Proto.Request{cmd: :CMD_statistics, statistics: sr = %Studio.Proto.StatisticsRequest{}}, %Studio.Proto.Response{}) do
			%Studio.Proto.Response{status: :RS_statistics, message: "", state: %Studio.Proto.FullState{hash: ""}, statistics: Studio.Storage.statistics(sr)}
		end
		defp process_request(%Studio.Proto.Request{cmd: :CMD_new_transaction, subject: %Studio.Proto.FullState{transactions: [tr = %Studio.Proto.Transaction{}]}}, resp = %Studio.Proto.Response{}) do
			:ok = Tinca.memo(&Studio.Storage.new_transaction/1, [tr], 60000)
			%Studio.Proto.Response{resp | status: :RS_notice, message: "транзакция проведена"}
		end

	end

end)
