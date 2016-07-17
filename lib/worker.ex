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
	defcall session_new_edit(session = %Studio.Proto.Session{}, _), state: state = %Studio.Worker{} do
		%Studio.Checks.Session{} = Studio.Storage.can_session_be_saved(session) |> IO.inspect
		#
		#	TODO
		#
		{:reply, :ok, maybe_auto(Studio.now, state), @ttl}
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

end
