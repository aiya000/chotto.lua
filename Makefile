.PHONY: test lint format clean install-dependencies-for-test build

test:
	@echo "Running tests..."
	busted

lint:
	@echo "Checking code style..."
	stylua --check .

format:
	@echo "Formatting code..."
	stylua .

install-dependencies-for-test:
	luarocks install --local busted

build:
	@echo "Validating rockspec..."
	luarocks pack chotto.lua-main-1.rockspec
	luarocks make --local

clean:
	@echo "Cleaning up..."
	rm -f luacov.*.out
	rm -f *.log

check: lint test
	@echo "All checks completed successfully!"
