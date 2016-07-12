defmodule Studio.Utils do
	use Silverb
	def auth(%Studio.Proto.Request{login: login, password: password, client_kind: :CK_admin}) do
		case Studio.Loaders.Superadmin.get(:data) do
			nil -> Studio.error("данные не найдены, возможно проблемы на сервере")
			%Studio.Proto.Response{state: %Studio.Proto.FullState{admins: admins}} when is_list(admins) ->
				case Enum.filter(admins, (fn ; %Studio.Proto.Admin{login: ^login, password: ^password, enabled: true} -> true ; %Studio.Proto.Admin{} -> false ; end)) do
					admins = [%Studio.Proto.Admin{login: ^login, password: ^password, enabled: true}] -> %Studio.Proto.Response{status: :RS_ok_state, message: "", state: %Studio.Proto.FullState{admins: admins}}
					[] -> Studio.error("пользователь не авторизован")
				end
		end
	end
end
