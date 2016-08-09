# use only one worker to prevent collisions
defmodule Studio.Worker do
	require Logger
	use Silverb, [
		{"@ttl", 5000}
	]
	use ExActor.GenServer, export: :studio_worker
	defstruct autostamp: nil
	definit do
		{:ok, %Studio.Worker{}, @ttl}
	end
	definfo :timeout, state: state = %Studio.Worker{} do
		{:noreply, maybe_auto(Studio.now, state), @ttl}
	end
	defcall session_new_edit(session = %Studio.Proto.Session{}, _, resp = %Studio.Proto.Response{}), state: state = %Studio.Worker{} do
		{
			:reply,
			(Studio.Storage.can_session_be_saved(session) |> process_users_session(session, resp)),
			maybe_auto(Studio.now, state),
			@ttl
		}
	end
	defcall band_new_edit(band = %Studio.Proto.Band{}, resp = %Studio.Proto.Response{}), state: state = %Studio.Worker{} do
		{
			:reply,
			(Studio.Storage.can_band_be_saved(band) |> process_band_new_edit(band, resp)),
			maybe_auto(Studio.now, state),
			@ttl
		}
	end
	defcall session_template_new_edit(data = %Studio.Proto.SessionTemplate{}, resp = %Studio.Proto.Response{}), state: state = %Studio.Worker{} do
		{
			:reply,
			(Studio.Storage.can_session_template_be_saved(data) |> process_session_template_new_edit(data, resp)),
			maybe_auto(Studio.now, state),
			@ttl
		}
	end
	defcall delete_from_table(id, table, resp = %Studio.Proto.Response{}), state: state = %Studio.Worker{} do
		_ = if (table == "sessions_template"), do: rm_future_auto_sessions(id)
		{
			:reply,
			Studio.Storage.delete_from_table(id, table,resp),
			maybe_auto(Studio.now, state),
			@ttl
		}
	end

	defp maybe_auto(current, state = %Studio.Worker{autostamp: nil}) do
		_ = autoupdate()
		%Studio.Worker{state | autostamp: current}
	end
	defp maybe_auto(current, state = %Studio.Worker{autostamp: last}) do
		case (Timex.Comparable.diff(current, last, :seconds) * 1000) >= @ttl do
			true ->
				_ = autoupdate()
				%Studio.Worker{state | autostamp: current}
			false ->
				state
		end
	end

	defp autoupdate do
		case Studio.Loaders.Superadmin.get(:data) do
			nil -> :ok
			%Studio.Proto.Response{state: state = %Studio.Proto.FullState{}} ->
				%Studio.Proto.FullState{sessions_template: lst} = Studio.Utils.enabled_only(state)
				Enum.each(lst, fn(templ = %Studio.Proto.SessionTemplate{week_day: wd}) ->
					Studio.Utils.future_dates_seq(wd)
					|> Enum.each(fn(date) ->
						session = Studio.Utils.session_from_template(templ, date)
						case Studio.Storage.can_session_be_saved(session) do
							check = %Studio.Checks.Session{action: :save} ->
								case process_users_session(check, session, %Studio.Proto.Response{}) do
									%Studio.Proto.Response{status: :RS_error, message: message} -> Logger.error("ERROR on autoupdate #{message}")
									%Studio.Proto.Response{} -> :ok
								end
							%Studio.Checks.Session{} ->
								:ok
						end
					end)
				end)
		end
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

	defp process_band_new_edit(true, band = %Studio.Proto.Band{id: id}, resp = %Studio.Proto.Response{}) when is_integer(id) and (id > 0) do
		case Studio.Storage.band_update(band) do
			:ok -> %Studio.Proto.Response{resp | status: :RS_notice, message: "группа обновлена"}
			{:error, error} -> %Studio.Proto.Response{resp | status: :RS_error, message: "ошибка при обновлении группы, запишите её и обратитесь к разработчику #{inspect error}"}
		end
	end
	defp process_band_new_edit(true, band = %Studio.Proto.Band{}, resp = %Studio.Proto.Response{}) do
		case Studio.Storage.band_new(band) do
			:ok -> %Studio.Proto.Response{resp | status: :RS_notice, message: "группа сохранена"}
			{:error, error} -> %Studio.Proto.Response{resp | status: :RS_error, message: "ошибка при сохранении группы, запишите её и обратитесь к разработчику #{inspect error}"}
		end
	end
	defp process_band_new_edit(bin, %Studio.Proto.Band{}, resp = %Studio.Proto.Response{}) when is_binary(bin) do
		%Studio.Proto.Response{resp | status: :RS_error, message: bin}
	end

	defp process_session_template_new_edit(%Studio.Checks.Session{action: :error, message: message}, %Studio.Proto.SessionTemplate{}, resp = %Studio.Proto.Response{}) do
		%Studio.Proto.Response{resp | status: :RS_error, message: message}
	end
	defp process_session_template_new_edit(%Studio.Checks.Session{action: :save}, data = %Studio.Proto.SessionTemplate{}, resp = %Studio.Proto.Response{}) do
		case Studio.Storage.generic_data_new(data, "sessions_template") do
			:ok -> %Studio.Proto.Response{resp | status: :RS_notice, message: "постоянная репетиция сохранена"}
			{:error, error} -> %Studio.Proto.Response{resp | status: :RS_error, message: "ошибка при сохранении, запишите её и обратитесь к разработчику #{inspect error}"}
		end
	end
	defp process_session_template_new_edit(%Studio.Checks.Session{action: :update, session_id: sid}, data = %Studio.Proto.SessionTemplate{}, resp = %Studio.Proto.Response{}) when is_integer(sid) do
		case %Studio.Proto.SessionTemplate{data | id: sid} |> Studio.Storage.generic_data_update("sessions_template") do
			:ok -> %Studio.Proto.Response{resp | status: :RS_notice, message: "постоянная репетиция обновлена"}
			{:error, error} -> %Studio.Proto.Response{resp | status: :RS_error, message: "ошибка при обновлении, запишите её и обратитесь к разработчику #{inspect error}"}
		end
	end

	defp rm_future_auto_sessions(id) do
		%Studio.Proto.Response{state: %Studio.Proto.FullState{sessions_template: lst}} = Studio.Loaders.Superadmin.get(:data)
		[st = %Studio.Proto.SessionTemplate{id: ^id}] = Enum.filter(lst, fn(%Studio.Proto.SessionTemplate{id: this_id}) -> this_id == id end)
		:ok = Studio.Storage.delete_auto_sessions_like_this(st)
	end

end
