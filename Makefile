# Extract version from Dockerfile, removing the 'v' prefix
VERSION := $(shell grep "FROM ghcr.io/astral-sh/uv:" Dockerfile | cut -d: -f2 | cut -d@ -f1)

ARCH ?= amd64
ARCHITECTURES := amd64 arm64

.PHONY: all
all: $(ARCHITECTURES)

$(ARCHITECTURES):
	@echo "ARCH=$@"
	@$(MAKE) build ARCH=$@

.PHONY: build
build: output/uv_$(VERSION)_$(ARCH).deb

tmp/$(ARCH).tar.gz: tmp
	$(eval DL_ARCH := $(if $(filter amd64,$(ARCH)),x86_64,aarch64))
	curl -sLo tmp/$(ARCH).tar.gz "https://github.com/astral-sh/uv/releases/download/$(VERSION)/uv-$(DL_ARCH)-unknown-linux-gnu.tar.gz"
	grep tmp/$(ARCH).tar.gz SHA256SUM > tmp/$(ARCH).tar.gz.sha256sum
	sha256sum -c tmp/$(ARCH).tar.gz.sha256sum

tmp/$(ARCH)/uv: tmp/$(ARCH).tar.gz
	mkdir -p tmp/$(ARCH)
	tar -C tmp/$(ARCH) --strip-components=1 -xzf tmp/$(ARCH).tar.gz
	touch tmp/$(ARCH)/uv

tmp/$(ARCH).yaml: tmp
	sed -e "s/VERSION/$(VERSION)/g" -e "s/ARCH/$(ARCH)/g" nfpm.yaml > tmp/$(ARCH).yaml

output/uv_$(VERSION)_$(ARCH).deb: tmp/$(ARCH)/uv tmp/$(ARCH).yaml output
	nfpm package -p deb -f tmp/$(ARCH).yaml -t output/

output:
	mkdir -p output
tmp:
	mkdir -p tmp

.PHONY: clean
clean:
	rm -rf tmp output
