# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

# This configuration is loaded before any dependency and is restricted
# to this project. If another project depends on this project, this
# file won't be loaded nor affect the parent project. For this reason,
# if you want to provide default values for your application for
# 3rd-party users, it should be done in your "mix.exs" file.

# You can configure for your application as:
#
#     config :studio, key: :value
#
# And access this configuration in your application as:
#
#     Application.get_env(:studio, :key)
#
# Or configure a 3rd-party app:
#
#     config :logger, level: :info
#

# It is also possible to import configuration files, relative to this
# directory. For example, you can emulate configuration per environment
# by uncommenting the line below and defining dev.exs, test.exs and such.
# Configuration from the imported file will override the ones defined
# here (which is why it is important to import them last).
#
#     import_config "#{Mix.env}.exs"

config :sqlx,
	timeout: 60000,
	pools:	[
				studio: [
							size: 10,
							user: 'root',
							password: '',
							host: '127.0.0.1',
							database: 'studio',
							encoding: :utf8
						]
			]

config :pmaker,
	# basic_auth: %{login: "login", password: "password"}, # if needed
	# can run multiple servers on one OTP app
	servers: [
		%{
			module: "BulletAdmin", # just server name
			app: :studio, # main app ( for loading resources etc )
			port: 7772, # webserver port
			kind: :bullet, # :bullet | :cowboy
			decode: :callback, # nil | :json | :callback
			encode: :callback, # nil | :json | :callback
			crossdomain: true, # true | false
			callback_module: Studio.Pmaker.Bullet.Admin, # where are callbacks functions :
			# mandatory &handle_pmaker/1 gets %Pmaker.Request{}, returns %Pmaker.Response{}
			# optional &decode/1 returns {:ok, term} | {:error, error}
			# optional &encode/1
			priv_path: "/studio_ui_admin/public" # path in priv dir for resource loader
		},
		%{
			module: "BulletObserver", # just server name
			app: :studio, # main app ( for loading resources etc )
			port: 7773, # webserver port
			kind: :bullet, # :bullet | :cowboy
			decode: :callback, # nil | :json | :callback
			encode: :callback, # nil | :json | :callback
			crossdomain: true, # true | false
			callback_module: Studio.Pmaker.Bullet.Observer, # where are callbacks functions :
			# mandatory &handle_pmaker/1 gets %Pmaker.Request{}, returns %Pmaker.Response{}
			# optional &decode/1 returns {:ok, term} | {:error, error}
			# optional &encode/1
			priv_path: "/studio_ui_observer/public" # path in priv dir for resource loader
			},
			%{
				module: "BulletIframe", # just server name
				app: :studio, # main app ( for loading resources etc )
				port: 7774, # webserver port
				kind: :bullet, # :bullet | :cowboy
				decode: :callback, # nil | :json | :callback
				encode: :callback, # nil | :json | :callback
				crossdomain: true, # true | false
				callback_module: Studio.Pmaker.Bullet.Observer, # where are callbacks functions :
				# mandatory &handle_pmaker/1 gets %Pmaker.Request{}, returns %Pmaker.Response{}
				# optional &decode/1 returns {:ok, term} | {:error, error}
				# optional &encode/1
				priv_path: "/studio_ui_iframe/public" # path in priv dir for resource loader
			}
	]
