LAZBUILD ?= lazbuild
FPC ?= fpc
FPC_FLAGS ?= -v0web -Sic -Fusrc
TEST_RUNNER ?= prove

build:
	$(LAZBUILD) --build-mode=release cli.lpi

build-test:
	mkdir -p t/build
	$(FPC) $(FPC_FLAGS) -g -gl -Fut/lib -Fut/pascal-tap/src -FUt/build -FEt/build -ot/tests.t t/tests.t.pas

test: build build-test
	$(TEST_RUNNER) t t/cli

