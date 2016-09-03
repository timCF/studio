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
		Enum.each(sessions, fn
			sess = %Studio.Proto.Session{status: status} when (status in [:SS_awaiting_last, :SS_awaiting_first]) ->
				new_sess = %Studio.Proto.Session{sess | amount: Studio.Utils.derive_session_price(sess, state)}
				_ = Studio.Worker.do_work(fn() -> Studio.Storage.maybe_update_session_amount(new_sess) end)
			%Studio.Proto.Session{} ->
				:ok
		end)
	end

end
