FPC ?= fpc
BUILD_DIR ?= build
SOURCE_DIR ?= src
FPC_FLAGS ?= "-v0we -FE$(BUILD_DIR) -Fu$(SOURCE_DIR)"
O_LEVEL ?= 1

build: prepare
	$(FPC) $(FPC_FLAGS) -O$(O_LEVEL) endpoints/cli.pas

build-library: prepare
	$(FPC) $(FPC_FLAGS) -O$(O_LEVEL) endpoints/lib.pas

debug: prepare
	$(FPC) -g -gl $(FPC_FLAGS) endpoints/cli.pas
	gdb -ex run $(BUILD_DIR)/cli

prepare:
	mkdir -p $(BUILD_DIR)

clean:
	rm -Rf $(BUILD_DIR)

