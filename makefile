FPC ?= fpc
BUILD_DIR ?= build
SOURCE_DIR ?= src
FPC_FLAGS ?= -v0web -Sic -FE$(BUILD_DIR) -Fu$(SOURCE_DIR)
O_LEVEL ?= 1

build: prepare
	$(FPC) $(FPC_FLAGS) -O$(O_LEVEL) -opncli endpoints/cli.pp

build-library: prepare
	$(FPC) $(FPC_FLAGS) -O$(O_LEVEL) endpoints/lib.pas

test: build
	prove

debug: prepare
	$(FPC) -g -gl $(FPC_FLAGS) -odebcli endpoints/cli.pp
	gdb -ex "run -p 2+2" $(BUILD_DIR)/debcli

prepare:
	mkdir -p $(BUILD_DIR)

clean:
	rm -Rf $(BUILD_DIR)

