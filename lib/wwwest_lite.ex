defmodule Studio.WwwestLite do
	use Silverb
	require WwwestLite
	WwwestLite.callback_module do
		def handle_wwwest_lite(%{cmd: "echo", args: some, post_body: post_body}), do: %{ans: some, post_body: post_body} |> WwwestLite.encode
		def handle_wwwest_lite(%{cmd: "time"}), do: %{ans: Exutils.makestamp} |> WwwestLite.encode
	end
end

#
#	TODO
#
