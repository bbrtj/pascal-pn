FPC ?= fpc
BUILD_DIR ?= build
SOURCE_DIR ?= src
FPC_FLAGS ?= "-FE$(BUILD_DIR) -Fu$(SOURCE_DIR)"

test: build
	./rpncli

build: prepare
	$(FPC) $(FPC_FLAGS) rpncli.pas

build-library: prepare
	$(FPC) $(FPC_FLAGS) rpnlib.pas

prepare:
	mkdir -p $(BUILD_DIR)

clean:
	rm -Rf $(BUILD_DIR)

