PYTHON = python3
pypackage = ShoppingList
static_assets = shoppinglist/static/*.css shoppinglist/static/*.js
static_manifest = shoppinglist/static/SHA256SUMS
scripts = bin/pserve bin/pytest bin/flake8 bin/python
db = ShoppingList.db
default_targets = $(scripts) $(static_manifest) $(db)

.PHONY: all
all: $(default_targets)         ##: build the thing

include help.mk
HELP_WIDTH = 30

.PHONY: run
run: $(db) $(static_manifest)   ##: start a local dev server
	uv run pserve development.ini --reload

.PHONY: test
test:                           ##: run tests
	uv run pytest --cov

.PHONY: lint
lint:                           ##: run flake8
	uv run flake8 shoppinglist/

.PHONY: tags
tags:                           ##: run ctags
	ctags -R shoppinglist

.PHONY: prod-db
prod-db: var/ShoppingList.db    ##: create new production sqlite DB if missing

var/ShoppingList.db: $(db) var
	install -m 644 -o www-data -g www-data $(db) var/ShoppingList.db

var:
	install -m 755 -o www-data -g www-data -d var || rmdir var

.PHONY: update-all-packages
update-all-packages:            ##: upgrade all Python packages to latest versions
	uv sync --upgrade
	$(MAKE) update-requirements

.PHONY: update-requirements
update-requirements:            ##: re-generate requirements.txt from uv.lock
	uv export --format requirements.txt --no-dev --no-emit-project --no-hashes -o requirements.txt


JQUERY_VERSION = 1.11.1
JQUERY_MOBILE_VERSION = 1.4.5

.PHONY: update-assets
update-assets:                  ##: download JavaScript assets, with versions
                                ##: specified in the Makefile
	wget -O shoppinglist/static/jquery.min.js https://code.jquery.com/jquery-$(JQUERY_VERSION).min.js
	wget -O shoppinglist/static/jquery.mobile.min.js https://code.jquery.com/mobile/$(JQUERY_MOBILE_VERSION)/jquery.mobile-$(JQUERY_MOBILE_VERSION).min.js
	wget -O shoppinglist/static/jquery.mobile.min.css https://code.jquery.com/mobile/$(JQUERY_MOBILE_VERSION)/jquery.mobile-$(JQUERY_MOBILE_VERSION).min.css
	mkdir -p shoppinglist/static/images/icons-png
	wget -O shoppinglist/static/images/ajax-loader.gif https://code.jquery.com/mobile/$(JQUERY_MOBILE_VERSION)/images/ajax-loader.gif
	wget -O shoppinglist/static/images/icons-png/grid-white.png https://code.jquery.com/mobile/$(JQUERY_MOBILE_VERSION)/images/icons-png/grid-white.png
	cd shoppinglist/static && sha256sum *.css *.js > SHA256SUMS

.PHONY: update
update:                         ##: pull updated version from git and restart gracefully
	git pull
	make
	touch pyramid.wsgi

.PHONY: clean
clean:                          ##: remove some build artefacts
	find -name '*.pyc' -delete

.PHONY: dist
dist:                           ##: build a source distribution in dist/
	uv build --sdist

.PHONY: distclean
distclean: clean                ##: remove all build artefacts
	rm -rf bin/ dist/ include/ lib/ *.egg-info/ build/ local/ .venv/
	rm -f .coverage tags

ShoppingList.db:
	test -f $@ || uv run init_ShoppingList_db development.ini

shoppinglist/static/SHA256SUMS: $(static_assets)
	cd shoppinglist/static && sha256sum *.css *.js > SHA256SUMS

.PHONY: update-static-manifest
update-static-manifest:         ##: re-generate manifest of static assets
                                ##: (usually this happens automatically)
	$(MAKE) -B $(static_manifest)

bin/pserve bin/pytest bin/flake8 bin/python:
	uv sync
	@mkdir -p bin
	ln -sfrt bin/ .venv/$@

.venv:
	uv sync

.PHONY: recreate-virtualenv
recreate-virtualenv:            ##: re-create the virtualenv
                                ##: (after e.g. upgrading system Python)
	rm -r .venv
	$(MAKE)
