defmodule Studio.Updater do
	require Logger
	use Silverb, [
		{"@ttl", 1000}
	]
	use ExActor.GenServer, export: :studio_updater
	definit do
		{:ok, nil, @ttl}
	end
	defcall await(), timeout: 3600000, state: state do
		{:reply, :ok, state, @ttl}
	end
	definfo :timeout, state: state do
		newstate = Studio.Loaders.Superadmin.get(:data)
		_ = auto_derive_prices(state, newstate)
		{:noreply, newstate, @ttl}
	end

	defp auto_derive_prices(state, state), do: :ok
	defp auto_derive_prices(nil, %Studio.Proto.Response{state: state = %Studio.Proto.FullState{sessions: sessions}}) do
		Logger.info("#{__MODULE__} auto upd start (INIT)")
		:rpc.pmap({__MODULE__, :auto_derive_prices_process}, [state], sessions)
		|> Enum.each(fn
			:ok -> :ok
			sess = %Studio.Proto.Session{} -> _ = Studio.Worker.do_work(fn() -> Studio.Storage.maybe_update_session_amount(sess) end)
		end)
		Logger.info("#{__MODULE__} auto upd end (INIT)")
	end
	defp auto_derive_prices(%Studio.Proto.Response{state: %Studio.Proto.FullState{sessions: old_sessions}}, %Studio.Proto.Response{state: state = %Studio.Proto.FullState{sessions: sessions}}) do
		Logger.info("#{__MODULE__} auto upd start")
		:rpc.pmap({__MODULE__, :auto_derive_prices_process}, [state], cut_off_extra_sessions(old_sessions, sessions))
		|> Enum.each(fn
			:ok -> :ok
			sess = %Studio.Proto.Session{} -> _ = Studio.Worker.do_work(fn() -> Studio.Storage.maybe_update_session_amount(sess) end)
		end)
		Logger.info("#{__MODULE__} auto upd end")
	end
	defp auto_derive_prices(_, _), do: :ok

	def auto_derive_prices_process(sess = %Studio.Proto.Session{status: status}, state = %Studio.Proto.FullState{}) when (status in [:SS_awaiting_last, :SS_awaiting_first]) do
		derived_amount = Studio.Utils.derive_session_price(sess, state)
		case %Studio.Proto.Session{sess | amount: derived_amount, price: derived_amount} do
			^sess -> :ok
			new_sess -> new_sess
		end
	end
	def auto_derive_prices_process(%Studio.Proto.Session{}, %Studio.Proto.FullState{}), do: :ok

	defp cut_off_extra_sessions(old_sess, new_sess) do
		[old_sess_map, new_sess_map] = Enum.map([old_sess, new_sess], fn(lst) -> Enum.group_by(lst, fn(%Studio.Proto.Session{band_id: id}) -> id end)  end)
		Stream.filter(new_sess_map, fn({id, lst}) ->
			case Map.get(old_sess_map, id) do
				^lst -> false
				_ -> true
			end
		end)
		|> Stream.flat_map(fn({_, lst}) -> lst end)
		|> Enum.filter(fn(%Studio.Proto.Session{status: status}) -> (status in [:SS_awaiting_last, :SS_awaiting_first]) end)
	end

end
