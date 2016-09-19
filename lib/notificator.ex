defmodule Studio.Notificator do
	require Logger
	use Silverb, [
		{"@ttl", :timer.minutes(5)},
		{"@server_names", (Application.get_env(:pmaker, :servers) |> Enum.map(fn(%{module: module}) -> module end))},
		{"@timex_format", "{YYYY}-{0M}-{0D}"}, # {0h24}:{0m}:{0s}
	]
	use ExActor.GenServer, export: :studio_notificator
	definit do
		{:ok, nil, 5000}
	end
	definfo :timeout do
		case Studio.Storage.get_overdue_sessions do
			[] -> :ok
			lst = [%Studio.Proto.Session{}|_] ->
				message = %Pmaker.Response{data: (%Studio.Proto.Response{status: :RS_warn, message: get_msg_text(lst), state: %Studio.Proto.FullState{hash: ""}} |> Studio.encode), encode: false}
				Enum.each(@server_names, &(Pmaker.send2all(message, &1)))
		end
		{:noreply, nil, @ttl}
	end

	defp get_msg_text([%Studio.Proto.Session{time_from: time_from}]), do: "есть не закрытая вовремя репетиция за #{ Timex.format!(time_from, @timex_format) }"
	defp get_msg_text(lst = [%Studio.Proto.Session{time_from: time_from}|_]), do: "есть не закрытая вовремя репетиция за #{ Timex.format!(time_from, @timex_format) } и ещё #{ length(lst) - 1 } других"


end
