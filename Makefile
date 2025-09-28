.PHONY: test lint format clean install-dependencies-for-test build

test:
	@echo "Running tests..."
	busted

lint:
	@echo "Checking code style..."
	stylua --check .

check: lint test
	@echo "All checks completed successfully!"

format:
	@echo "Formatting code..."
	stylua .

install-dependencies-for-test:
	luarocks install --local busted

ROCKSPEC_FILE = $(shell ls | grep '\.rockspec$$' | head -1)

build:
	@echo "Validating rockspec..."
	luarocks pack $(ROCKSPEC_FILE)
	luarocks make --local

# `$ make build` is same as install
install-to-local:
	$(MAKE) build

install-dependencies-for-upload:
	luarocks install --local dkjson

upload:
	luarocks upload $(ROCKSPEC_FILE) --api-key=$(LUAROCKS_CHOTTO_LUA_API_KEY)

clean:
	@echo "Cleaning up..."
	rm -f luacov.*.out
	rm -f *.log

# TODO: Support pure Linux and macOS
open-repo:
	explorer.exe https://github.com/aiya000/chotto.lua

open-luarocks:
	explorer.exe https://luarocks.org/modules/aiya000/chotto
