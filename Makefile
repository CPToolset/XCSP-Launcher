# Variables
VERSION := $(shell git describe --tags --abbrev=0)
DIST_DIR := dist
PKG_NAME := xcsp
SRC := bin/main.py

# Trouve toutes les dépendances installées
# (filtre pour ignorer les libs système si besoin)
COLLECT_ALL := $(shell python3 -c "import pkg_resources; print(' '.join(f'--collect-all={d.project_name}' for d in pkg_resources.working_set if d.project_name not in ['pip', 'setuptools', 'wheel']))")
HIDDEN_IMPORTS := $(shell find xcsp -name '*.py' | sed -E 's|/|.|g' | sed -E 's|\.py$$||' | grep -v '__init__' | awk '{print "--hidden-import=" $$0}' | tr '\n' ' ')



# Cibles principales
all: build pyinstaller deb snap choco

# Compilation Python -> binaire avec PyInstaller
build:
	export PYTHONPATH=$PYTHONPATH:.
	python3 -m pip install pyinstaller build twine
	pyinstaller --onefile --name $(PKG_NAME) --paths=. $(HIDDEN_IMPORTS)  ${SRC} $(COLLECT_ALL)
	python3 -m build

print-hidden-imports:
	@echo $(HIDDEN_IMPORTS)

pyinstaller:
	pyinstaller --onefile --name $(PKG_NAME) --paths=. $(HIDDEN_IMPORTS)  ${SRC} $(COLLECT_ALL)

package:
ifeq ($(OS), Linux)
	make deb
	make snap
endif
ifeq ($(OS), Darwin)
	make brew
endif
ifeq ($(OS), Windows_NT)
	make choco
endif

# Création du .deb avec fpm
deb:
	gem install --no-document fpm || true
	mkdir -p package/usr/local/bin
	mkdir -p package/usr/share/xcsp-launcher/configs
	cp $(DIST_DIR)/$(PKG_NAME) package/usr/local/bin/
	cp -r configs/* package/usr/share/$(PKG_NAME)/configs/
	chmod +x scripts/postinst
	fpm -s dir -t deb -n $(PKG_NAME) -v $(VERSION:v%=%) --prefix=/ --after-install scripts/postinst package/usr/local/bin/$(PKG_NAME) package/usr/share/$(PKG_NAME)/configs
	rm -rf package

# Création du snap (suppose que snapcraft est installé)
snap:
	snapcraft

# Création du package Chocolatey
choco:
	cd tools && choco pack

# Nettoyage
clean:
	rm -rf build dist *.spec package *.deb *.snap

.PHONY: all build deb snap choco clean
