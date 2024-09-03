LAZBUILD ?= lazbuild

build:
	$(LAZBUILD) --build-mode=release cli.lpi

debug:
	$(LAZBUILD) --build-mode=debug cli.lpi

test: build
	$(LAZBUILD) t/tests.lpi

