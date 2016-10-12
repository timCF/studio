# use only one worker to prevent collisions
defmodule Studio.Worker do
	require Logger
	require Uelli
	use Silverb, [
		{"@ttl", 5000},
		{"@callt", 3600000},
	]
	use ExActor.GenServer, export: :studio_worker
	defstruct autostamp: nil
	definit do
		{:ok, %Studio.Worker{}, @ttl}
	end
	definfo :timeout, state: state = %Studio.Worker{} do
		{:noreply, state, @ttl}
	end
	defcall session_new_edit(session = %Studio.Proto.Session{}, _, resp = %Studio.Proto.Response{}), state: state = %Studio.Worker{}, timeout: @callt do
		{
			:reply,
			(Studio.Storage.can_session_be_saved(session) |> process_users_session(session, resp)),
			state,
			@ttl
		}
	end
	defcall band_new_edit(band = %Studio.Proto.Band{}, resp = %Studio.Proto.Response{}), state: state = %Studio.Worker{}, timeout: @callt do
		{
			:reply,
			(Studio.Storage.can_band_be_saved(band) |> process_band_new_edit(band, resp)),
			state,
			@ttl
		}
	end
	defcall session_template_new_edit(data = %Studio.Proto.SessionTemplate{}, resp = %Studio.Proto.Response{}), state: state = %Studio.Worker{}, timeout: @callt do
		{
			:reply,
			(Studio.Storage.can_session_template_be_saved(data) |> process_session_template_new_edit(data, resp)),
			state,
			@ttl
		}
	end
	defcall delete_from_table(id, table, resp = %Studio.Proto.Response{}), state: state = %Studio.Worker{}, timeout: @callt do
		%Studio.Proto.Response{state: %Studio.Proto.FullState{sessions_template: lst}} = Studio.Loaders.Superadmin.get(:data)
		[st = %Studio.Proto.SessionTemplate{id: ^id}] = Enum.filter(lst, fn(%Studio.Proto.SessionTemplate{id: this_id}) -> this_id == id end)
		result = Studio.Storage.delete_from_table(id, table,resp)
		_ = if (table == "sessions_template") do
			_ = purge_sessions_from_template(st)
		end
		{
			:reply,
			result,
			state,
			@ttl
		}
	end
	defcall do_work(lambda), state: state = %Studio.Worker{}, timeout: @callt do
		{
			:reply,
			lambda.(),
			state,
			@ttl
		}
	end

	#
	#	TODO : this is bad, very bad practice, I know :(((
	#
	defp purge_sessions_from_template(st = %Studio.Proto.SessionTemplate{}) do
		spawn(fn() ->
			Enum.each(1..5, fn(_) ->
				_ = Studio.Loaders.Superadmin.await() |> Uelli.try_catch
				_ = Studio.Loaders.Superadmin.await() |> Uelli.try_catch
				_ = Studio.Updater.Template.await() |> Uelli.try_catch
				_ = Studio.Updater.await() |> Uelli.try_catch
				_ = Studio.Worker.do_work(fn() -> Studio.Storage.delete_auto_sessions_like_this(st) end) |> Uelli.try_catch
				_ = :timer.sleep(1000)
			end)
		end)
	end

	defp process_users_session(%Studio.Checks.Session{action: :error, message: message}, %Studio.Proto.Session{}, resp = %Studio.Proto.Response{}) do
		%Studio.Proto.Response{resp | status: :RS_error, message: message}
	end
	defp process_users_session(%Studio.Checks.Session{action: action, session_id: sid}, session = %Studio.Proto.Session{}, resp = %Studio.Proto.Response{}) when is_integer(sid) and (action in [:update, :save]) do
		case %Studio.Proto.Session{session | id: sid} |> Studio.Storage.update_session do
			:ok -> %Studio.Proto.Response{resp | status: :RS_notice, message: "репетиция обновлена"}
			{:error, error} -> %Studio.Proto.Response{resp | status: :RS_error, message: "ошибка при обновлении репетиции, запишите её и обратитесь к разработчику #{inspect error}"}
		end
	end
	defp process_users_session(%Studio.Checks.Session{action: :save}, session = %Studio.Proto.Session{}, resp = %Studio.Proto.Response{}) do
		case Studio.Storage.save_session(session) do
			:ok -> %Studio.Proto.Response{resp | status: :RS_notice, message: "репетиция сохранена"}
			{:error, error} -> %Studio.Proto.Response{resp | status: :RS_error, message: "ошибка при сохранении репетиции, запишите её и обратитесь к разработчику #{inspect error}"}
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
			:ok ->
				_ = purge_sessions_from_template(data)
				%Studio.Proto.Response{resp | status: :RS_notice, message: "постоянная репетиция сохранена"}
			{:error, error} -> %Studio.Proto.Response{resp | status: :RS_error, message: "ошибка при сохранении, запишите её и обратитесь к разработчику #{inspect error}"}
		end
	end
	defp process_session_template_new_edit(%Studio.Checks.Session{action: :update, session_id: sid}, data = %Studio.Proto.SessionTemplate{}, resp = %Studio.Proto.Response{}) when is_integer(sid) do
		case %Studio.Proto.SessionTemplate{data | id: sid} |> Studio.Storage.generic_data_update("sessions_template") do
			:ok ->
				_ = purge_sessions_from_template(data)
				%Studio.Proto.Response{resp | status: :RS_notice, message: "постоянная репетиция обновлена"}
			{:error, error} -> %Studio.Proto.Response{resp | status: :RS_error, message: "ошибка при обновлении, запишите её и обратитесь к разработчику #{inspect error}"}
		end
	end

end
