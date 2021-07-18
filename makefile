FPC ?= fpc
BUILD_DIR ?= build
SOURCE_DIR ?= src
FPC_FLAGS ?= "-FE$(BUILD_DIR) -Fu$(SOURCE_DIR)"
O_LEVEL ?= -

test: build
	$(BUILD_DIR)/cli

build: prepare
	$(FPC) $(FPC_FLAGS) -O$(O_LEVEL) endpoints/cli.pas

build-library: prepare
	$(FPC) $(FPC_FLAGS) -O$(O_LEVEL) endpoints/lib.pas

prepare:
	mkdir -p $(BUILD_DIR)

clean:
	rm -Rf $(BUILD_DIR)

