defmodule Studio.Updater.Template do
	require Logger
	use Silverb, [
		{"@ttl", 1000}
	]
	use ExActor.GenServer, export: :studio_updater_template
	definit do
		{:ok, nil, @ttl}
	end
	defcall await(), timeout: 3600000, state: state do
		{:reply, :ok, state, @ttl}
	end
	definfo :timeout, state: state do
		case Studio.Loaders.Superadmin.get(:data) do
			^state -> {:noreply, state, @ttl}
			newstate ->
				_ = Logger.info("#{__MODULE__} auto upd start")
				_ = auto_handle_sessions_template(newstate)
				_ = Logger.info("#{__MODULE__} auto upd end")
				{:noreply, newstate, @ttl}
		end
	end

	defmacrop do_work(body) do
		quote location: :keep do
			Studio.Worker.do_work(fn() -> unquote(body) end)
		end
	end

	defp auto_handle_sessions_template(nil), do: :ok
	defp auto_handle_sessions_template(%Studio.Proto.Response{state: state = %Studio.Proto.FullState{}}) do
		%Studio.Proto.FullState{sessions_template: lst} = Studio.Utils.enabled_only(state)
		Enum.each(lst, fn(templ = %Studio.Proto.SessionTemplate{week_day: wd, active_from: active_from}) ->
			Studio.Utils.future_dates_seq(wd)
			|> Stream.filter(fn(date) -> Timex.DateTime.to_seconds(date) >= Timex.DateTime.to_seconds(active_from) end)
			|> Enum.each(fn(date) ->
				session = Studio.Utils.session_from_template(templ, date)
				case Studio.Storage.can_session_be_saved(session) do
					check = %Studio.Checks.Session{action: cmd} when (cmd in [:save, :update]) ->
						case Studio.Storage.can_session_be_saved_auto(session) do
							false ->
								:ok
							true ->
								case process_users_session(check, session, %Studio.Proto.Response{}) do
									%Studio.Proto.Response{status: :RS_error, message: message} -> Logger.error("ERROR on autoupdate #{message}")
									%Studio.Proto.Response{} -> :ok
								end
						end
					%Studio.Checks.Session{} ->
						:ok
				end
				|> do_work
			end)
		end)
	end

	defp process_users_session(%Studio.Checks.Session{action: :error, message: message}, %Studio.Proto.Session{}, resp = %Studio.Proto.Response{}) do
		%Studio.Proto.Response{resp | status: :RS_error, message: message}
	end
	defp process_users_session(%Studio.Checks.Session{action: :save}, session = %Studio.Proto.Session{}, resp = %Studio.Proto.Response{}) do
		case Studio.Storage.save_session(session) do
			:ok -> %Studio.Proto.Response{resp | status: :RS_notice, message: "репетиция сохранена"}
			{:error, error} -> %Studio.Proto.Response{resp | status: :RS_error, message: "ошибка при сохранении репетиции, запишите её и обратитесь к разработчику #{inspect error}"}
		end
	end
	defp process_users_session(%Studio.Checks.Session{action: :update, session_id: sid}, session = %Studio.Proto.Session{}, resp = %Studio.Proto.Response{}) when is_integer(sid) do
		case %Studio.Proto.Session{session | id: sid} |> Studio.Storage.update_session do
			:ok -> %Studio.Proto.Response{resp | status: :RS_notice, message: "репетиция обновлена"}
			{:error, error} -> %Studio.Proto.Response{resp | status: :RS_error, message: "ошибка при обновлении репетиции, запишите её и обратитесь к разработчику #{inspect error}"}
		end
	end

end
