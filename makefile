FPC ?= fpc

run: build
	./rpncli

build:
	$(FPC) rpncli.pas

build-library:
	$(FPC) rpnlib.pas


