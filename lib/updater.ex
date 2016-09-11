defmodule Studio.Updater do
	require Logger
	use Silverb, [
		{"@ttl", 1000}
	]
	use ExActor.GenServer, export: :studio_updater
	definit do
		{:ok, nil, @ttl}
	end
	definfo :timeout do
		_ = Studio.Loaders.Superadmin.get(:data) |> auto_derive_prices
		{:noreply, nil, @ttl}
	end

	defp auto_derive_prices(nil), do: :ok
	defp auto_derive_prices(%Studio.Proto.Response{state: state = %Studio.Proto.FullState{sessions: sessions}}) do
		Logger.info("auto upd start")
		:rpc.pmap({__MODULE__, :auto_derive_prices_process}, [state], sessions)
		|> Enum.each(fn
			:ok -> :ok
			sess = %Studio.Proto.Session{} -> _ = Studio.Worker.do_work(fn() -> Studio.Storage.maybe_update_session_amount(sess) end)
		end)
		Logger.info("auto upd end")
	end

	def auto_derive_prices_process(sess = %Studio.Proto.Session{status: status}, state = %Studio.Proto.FullState{}) when (status in [:SS_awaiting_last, :SS_awaiting_first]) do
		derived_amount = Studio.Utils.derive_session_price(sess, state)
		case %Studio.Proto.Session{sess | amount: derived_amount, price: derived_amount} do
			^sess -> :ok
			new_sess -> new_sess
		end
	end
	def auto_derive_prices_process(%Studio.Proto.Session{}, %Studio.Proto.FullState{}), do: :ok

end
