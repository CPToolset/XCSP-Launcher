# Variables
VERSION := $(shell (git describe --tags --abbrev=0 2>/dev/null || echo "v0.1.0-alpha"))
DIST_DIR := dist
PKG_NAME := xcsp-launcher
BIN_NAME := xcsp
SRC := bin/main.py

DESCRIPTION := "A unified launcher for XCSP-compatible solvers"
MAINTAINER := "TOOTATIS team <contact@tootatis.dev>"
LICENSE := "LGPLv3+"
VENDOR := "University of Luxembourg"
URL := "https://tootatis.dev"

PACKAGING_DIR := .packaging

# Trouve toutes les dépendances installées
COLLECT_ALL := $(shell python3 -c "import pkg_resources; print(' '.join(f'--collect-all={d.project_name}' for d in pkg_resources.working_set if d.project_name not in ['pip', 'setuptools', 'wheel']))")
HIDDEN_IMPORTS := $(shell python3 -c "import pathlib; print(' '.join(f'--hidden-import={p.as_posix().replace('/', '.').replace('.py', '')}' for p in pathlib.Path('xcsp').rglob('*.py') if '__init__' not in p.name))")

# Cibles principales
all: build pyinstaller

# Compilation Python -> binaire avec PyInstaller
build:
	export PYTHONPATH=$$PYTHONPATH:.
	python3 -m pip install pyinstaller build twine
	python3 -m build

pyinstaller: build
	pyinstaller --onefile --name $(BIN_NAME) --paths=. $(HIDDEN_IMPORTS) ${SRC} $(COLLECT_ALL)

# Création du .deb avec fpm
deb: $(DIST_DIR)/$(BIN_NAME)
	echo ${VERSION}
	sudo gem install --no-document fpm || true
	mkdir -p package/usr/local/bin
	mkdir -p package/usr/share/$(PKG_NAME)/configs
	mkdir -p package/usr/share/$(PKG_NAME)/tools
	cp $(DIST_DIR)/$(BIN_NAME) package/usr/local/bin/
	cp -r configs/* package/usr/share/$(PKG_NAME)/configs/
	cp xcsp/tools/xcsp3-solutionChecker-2.5.jar package/usr/share/$(PKG_NAME)/tools/xcsp3-solutionChecker-2.5.jar
	cd package && fpm -s dir -t deb -n $(PKG_NAME) -v $(VERSION:v%=%)  \
	--description ${DESCRIPTION} \
	--maintainer ${MAINTAINER} \
	--license ${LICENSE} \
	--vendor ${VENDOR} \
	--url ${URL} \
	--prefix=/ \
	./usr/local/bin/$(BIN_NAME) ./usr/share/$(PKG_NAME)/configs ./usr/share/$(PKG_NAME)/tools
	cp package/*.deb .
	rm -rf package

# Créer une Formula Homebrew à partir du tar.gz
brew: $(DIST_DIR)/$(BIN_NAME)
	@echo "Building Homebrew formula..."

	# Générer un tar.gz contenant juste l'exécutable et les configs
	mkdir -p brew_tmp/bin brew_tmp/share/xcsp-launcher/configs brew_tmp/share/xcsp-launcher/tools
	cp $(DIST_DIR)/$(BIN_NAME) brew_tmp/bin/xcsp-macos
	cp $(DIST_DIR)/${BIN_NAME} $(DIST_DIR)/xcsp-macos
	cp -r configs/* brew_tmp/share/xcsp-launcher/configs/
	cp xcsp/tools/xcsp3-solutionChecker-2.5.jar brew_tmp/share/xcsp-launcher/tools/xcsp3-solutionChecker-2.5.jar

	# Créer archive
	tar -czvf xcsp-$(VERSION:v%=%)-macos.tar.gz -C brew_tmp .

	{ \
		sha256=$$(shasum -a 256 xcsp-$(VERSION:v%=%)-macos.tar.gz | awk '{print $$1}'); \
		url="https://github.com/CPToolset/xcsp-launcher/releases/download/$(VERSION)/xcsp-$(VERSION:v%=%)-macos.tar.gz"; \
		sed \
			-e "s|__URL__|$$url|" \
			-e "s|__SHASUM__|$$sha256|" \
			.packaging/homebrew/xcsp.rb.template > .packaging/homebrew/xcsp.rb; \
	}

	# Nettoyer temporaire
	rm -rf brew_tmp

publish-brew: xcsp-*-macos.tar.gz
	@echo "Publishing Homebrew Formula..."
	git clone https://github.com/CPToolset/homebrew-xcsp-launcher.git brew-tap
	mkdir -p brew-tap/Formula/
	cp .packaging/homebrew/xcsp.rb brew-tap/Formula/xcsp.rb
	cd brew-tap && git add Formula/ && git commit -m "Update formula for version $(VERSION)" && git push
	rm -rf brew-tap

pacman: $(DIST_DIR)/$(BIN_NAME)
	mkdir -p package/usr/bin
	cp $(DIST_DIR)/$(BIN_NAME) package/usr/bin/xcsp
	export SHELL=/bin/bash && cd package && fpm -s dir -t pacman -n $(PKG_NAME) -v $(VERSION:v%=%) \
	--description $(DESCRIPTION) \
	--license $(LICENSE) \
	--maintainer $(MAINTAINER) \
	--url $(URL) \
	--prefix=/ ./usr/bin/xcsp
	cp package/*.pkg.tar.* .
	rm -rf package
rpm: $(DIST_DIR)/$(BIN_NAME)
	mkdir -p package/usr/bin
	cp $(DIST_DIR)/$(BIN_NAME) package/usr/bin/xcsp
	cd package && fpm -s dir -t rpm -n $(PKG_NAME) -v $(VERSION:v%=%) \
	--description $(DESCRIPTION) \
	--license $(LICENSE) \
	--maintainer $(MAINTAINER) \
	--url $(URL) \
	--prefix=/ ./usr/bin/xcsp
	cp package/*.rpm .
	rm -rf package



# Création du snap (suppose que snapcraft est installé)
snap: pyinstaller
	snapcraft

# Création du package Chocolatey
choco:
	choco pack chocolatey/xcsp-launcher.nuspec

# Nettoyage
clean:
	rm -rf build dist *.spec package *.deb *.snap *.tar.gz


$(DIST_DIR)/$(BIN_NAME): pyinstaller
xcsp-*-macos.tar.gz: brew

.PHONY: all build deb snap choco clean
