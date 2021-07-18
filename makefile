FPC ?= fpc
BUILD_DIR ?= build
SOURCE_DIR ?= src
FPC_FLAGS ?= "-v0we -FE$(BUILD_DIR) -Fu$(SOURCE_DIR)"
O_LEVEL ?= -

build: prepare
	$(FPC) $(FPC_FLAGS) -O$(O_LEVEL) endpoints/cli.pas

build-library: prepare
	$(FPC) $(FPC_FLAGS) -O$(O_LEVEL) endpoints/lib.pas

run: build
	$(BUILD_DIR)/cli

check: prepare
	$(FPC) $(FPC_FLAGS) -vh endpoints/cli.pas

prepare:
	mkdir -p $(BUILD_DIR)

clean:
	rm -Rf $(BUILD_DIR)

