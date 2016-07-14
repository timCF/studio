all:
	mix deps.get && mix compile
	cd ./priv/studio_ui_admin && brunch b
rebuild:
	git submodule init
	git submodule update
	mix deps.get && mix compile
	cd ./priv/studio_ui_admin && make rebuild && brunch b
