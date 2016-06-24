defmodule Studio do
	use Application
	use Silverb

	defmodule Proto do
		use Protobuf, from: Path.expand("#{Exutils.priv_dir(:studio)}/studio_proto/studio.proto", __DIR__)
	end

	# See http://elixir-lang.org/docs/stable/elixir/Application.html
	# for more information on OTP Applications
	def start(_type, _args) do
	import Supervisor.Spec, warn: false

	children = [
	# Define workers and child supervisors to be supervised
	# worker(Studio.Worker, [arg1, arg2, arg3]),
	]

	# See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
	# for other strategies and supported options
	opts = [strategy: :one_for_one, name: Studio.Supervisor]
	Supervisor.start_link(children, opts)
	end
end
