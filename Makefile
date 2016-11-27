all:
	mix deps.get && mix compile
rebuild:
	git submodule update --init --recursive
	cd ./priv/studio_ui_admin && make rebuild
	cd ./priv/studio_ui_observer && make rebuild
	cd ./priv/studio_ui_iframe && make rebuild
