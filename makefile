LAZBUILD ?= lazbuild

build:
	$(LAZBUILD) --build-mode=release cli.lpi

debug:
	$(LAZBUILD) --build-mode=debug cli.lpi

test:
	$(LAZBUILD) t/tests.lpi

