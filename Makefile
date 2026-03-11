# µJS (muJS) - Build targets
# https://mujs.org

SRC     = lib/mu.js
DIST    = dist/mu.min.js
TERSER  = npx terser

.PHONY: doc all clean dist publish size check hash

# Default target: documentation
doc:
	@echo "$$(tput bold)Usage:$$(tput sgr0)"
	@echo "  make all       $$(tput dim)Build minified version of the µJS library.$$(tput sgr0)"
	@echo "  make dist      $$(tput dim)Create 'dist' directory and minify the µJS library$$(tput sgr0)."
	@echo "  make size      $$(tput dim)Display file sizes$$(tput sgr0)."
	@echo "  make check     $$(tput dim)Check what npm would publish$$(tput sgr0)."
	@echo "  make publish   $$(tput dim)Publish to NPM (builds first)$$(tput sgr0)."
	@echo "  make clean     $$(tput dim)Clean generated files.$$(tput sgr0)"

# Build minified version
all: dist

# Create dist directory and minify
dist: $(DIST)

$(DIST): $(SRC)
	@mkdir -p dist
	$(TERSER) $(SRC) -o $(DIST) -c -m --comments false -f 'preamble="/* µJS (muJS) - mujs.org */"'
	@echo "Built $(DIST)"
	@make -s size

# Display file sizes
size: $(DIST)
	@echo "---"
	@echo "Source:  $$(wc -c < $(SRC)) bytes"
	@echo "Min:     $$(wc -c < $(DIST)) bytes"
	@echo "Gzip:    $$(gzip -c $(DIST) | wc -c) bytes"

# Dry-run: check what npm would publish
check:
	npm pack --dry-run

# Publish to npm (builds first)
publish: dist
	npm publish

# Clean generated files
clean:
	rm -rf dist

# Compute the SHA384 hash
hash: dist
	@echo "sha384-$$(cat dist/mu.min.js | openssl dgst -sha384 -binary | openssl base64 -A)"

