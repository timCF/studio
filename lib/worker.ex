# use only one worker to prevent collisions
defmodule Studio.Worker do
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
		#
		#	TODO
		#
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
