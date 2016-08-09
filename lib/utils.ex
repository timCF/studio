defmodule Studio.Utils do
	use Silverb
	def date2wd(date) do
		"WD_#{((date |> Timex.days_to_beginning_of_week) + 1) |> Integer.to_string}"
		|> String.to_atom
	end
	def auth(%Studio.Proto.Request{login: login, password: password, client_kind: :CK_admin}) do
		case Studio.Loaders.Superadmin.get(:data) do
			nil -> Studio.error("данные не найдены, возможно проблемы на сервере")
			resp = %Studio.Proto.Response{state: fullstate = %Studio.Proto.FullState{admins: admins}} when is_list(admins) ->
				case Enum.filter(admins, (fn ; %Studio.Proto.Admin{login: ^login, password: ^password, enabled: true} -> true ; %Studio.Proto.Admin{} -> false ; end)) do
					admins = [%Studio.Proto.Admin{login: ^login, password: ^password, enabled: true}] -> %Studio.Proto.Response{resp | status: :RS_ok_state, message: "", state: %Studio.Proto.FullState{fullstate | admins: admins} |> enabled_only}
					[] -> Studio.error("пользователь не авторизован")
				end
		end
	end
	def auth(%Studio.Proto.Request{client_kind: :CK_observer}) do
		case Studio.Loaders.Superadmin.get(:data) do
			nil -> Studio.error("данные не найдены, возможно проблемы на сервере")
			resp = %Studio.Proto.Response{state: fullstate = %Studio.Proto.FullState{}} -> %Studio.Proto.Response{resp | status: :RS_ok_state, message: "", state: %Studio.Proto.FullState{fullstate | admins: []} |> enabled_only}
		end
	end
	def enabled_only(state = %Studio.Proto.FullState{}) do
		Map.from_struct(state)
		|> Map.keys
		|> Enum.reduce(state, fn(k, acc = %Studio.Proto.FullState{}) ->
			Map.update!(acc, k, fn
				lst = [_|_] ->
					Enum.filter(lst, fn
						%{enabled: false} -> false
						_ -> true
					end)
				some ->
					some
			end)
		end)
	end
	def future_dates_seq(wd) do
		now = Timex.DateTime.today
		Stream.map(0..30, &(Timex.shift(now, [days: &1])))
		|> Enum.filter(&(wd == Studio.Utils.date2wd(&1)))
	end
	def session_from_template(%Studio.Proto.SessionTemplate{min_from: min_from, min_to: min_to, week_day: wd, room_id: room_id, instruments_ids: instruments_ids, band_id: band_id, description: description}, date) do
		%Studio.Proto.Session{
			time_from: 1000 * (Timex.shift(date, [minutes: min_from]) |> Timex.DateTime.to_seconds),
			time_to: 1000 * (Timex.shift(date, [minutes: min_to]) |> Timex.DateTime.to_seconds),
			week_day: wd,
			room_id: room_id,
			instruments_ids: instruments_ids,
			band_id: band_id,
			callback: false,
			status: :SS_awaiting_first,
			amount: 0,
			description: description,
			ordered_by: :SO_auto,
			admin_id_open: 0,
			admin_id_close: 0,
		}
	end
end
defmodule Studio.Checks.Session do
	defstruct action: nil, # :save | :update | :error
			message: "",
			session_id: nil
end
