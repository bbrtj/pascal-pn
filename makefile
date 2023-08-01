FPC ?= fpc
BUILD_DIR ?= build
SOURCE_DIR ?= src
FPC_FLAGS ?= -v0web -Sic -FE$(BUILD_DIR) -Fu$(SOURCE_DIR)
O_LEVEL ?= 1
TEST_RUNNER ?= prove
TEST_VERBOSE ?= 0
TEST_FLAG ?= $$(if [ $(TEST_VERBOSE) == 1 ]; then echo "--verbose"; fi)

build: prepare
	$(FPC) $(FPC_FLAGS) -O$(O_LEVEL) -opncli endpoints/cli.pp

build-library: prepare
	$(FPC) $(FPC_FLAGS) -O$(O_LEVEL) endpoints/lib.pas

build-test: prepare
	$(FPC) $(FPC_FLAGS) -Fut/lib -Fut/pascal-tap/src -FU$(BUILD_DIR) -ot/tests.t t/tests.t.pas

test: build build-test
	$(TEST_RUNNER) t t/cli $(TEST_FLAG)

debug: prepare
	$(FPC) -g -gl $(FPC_FLAGS) -odebcli endpoints/cli.pp
	gdb -ex "run -p 2+2" $(BUILD_DIR)/debcli

prepare:
	mkdir -p $(BUILD_DIR)

clean:
	rm -Rf $(BUILD_DIR)

