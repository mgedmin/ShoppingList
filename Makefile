PYTHON = python3
pypackage = ShoppingList
egg_link = .venv/lib/python*/site-packages/$(pypackage).egg-link
static_assets = shoppinglist/static/*.css shoppinglist/static/*.js

.PHONY: all
all: bin/pserve $(egg_link) bin/pytest bin/flake8 ShoppingList.db shoppinglist/static/SHA256SUMS

.PHONY: help
help:
	@echo "make             build the thing"
	@echo "make run         start a local dev server"
	@echo "make test        run tests"
	@echo "make lint        run flake8"
	@echo "make tags        run ctags"
	@echo "make prod-db     create new production sqlite DB if missing"
	@echo "make update-all-packages"
	@echo "                 upgrade all Python packages in requirements.txt"
	@echo "                 to latest upstream versions"
	@echo "make update-requirements"
	@echo "                 re-generate requirement.txt from currently"
	@echo "                 installed package versions"
	@echo "make update-assets"
	@echo "                 download JavaScript assets, versions specified"
	@echo "                 in the Makefile:"
	@echo "                   JQUERY_VERSION = $(JQUERY_VERSION)"
	@echo "                   JQUERY_MOBILE_VERSION = $(JQUERY_MOBILE_VERSION)"
	@echo "make update      pull updated version from git"
	@echo "make clean       remove some build artefacts"
	@echo "make dist        build a source distribution in dist/"
	@echo "make distclean   remove all build artefacts"
	@echo "make update-static-manifest"
	@echo "                 re-generate manifest of static assets"
	@echo "                 (usually this happens automatically)"
	@echo "make recreate-virtualenv"
	@echo "                 re-create the virtualenv"
	@echo "                 (after e.g. upgrading system Python)"

.PHONY: run
run: bin/pserve $(egg_link) ShoppingList.db shoppinglist/static/SHA256SUMS
	bin/pserve development.ini --reload

.PHONY: test
test: bin/pytest $(egg_link)
	bin/pytest --cov

.PHONY: lint
lint: bin/flake8
	bin/flake8 *.py $(pypackage)

.PHONY: tags
tags:
	ctags -R shoppinglist

.PHONY: prod-db
prod-db: var/ShoppingList.db

var/ShoppingList.db: ShoppingList.db var
	install -m 644 -o www-data -g www-data ShoppingList.db var/ShoppingList.db

var:
	install -m 755 -o www-data -g www-data -d var || rmdir var

.PHONY: update-all-packages
update-all-packages: bin/pip
	bin/pip install -U pip setuptools wheel
	bin/pip install -U --upgrade-strategy=eager pytest pytest-cov flake8 watchdog -e .[testing]
	make
	make update-requirements

.PHONY: update-requirements
update-requirements: bin/pip
	PYTHONPATH= bin/pip freeze | grep -v '^-e .*$(pypackage)$$' > requirements.txt


JQUERY_VERSION = 1.11.1
JQUERY_MOBILE_VERSION = 1.4.5

.PHONY: update-assets
update-assets:
	wget -O shoppinglist/static/jquery.min.js https://code.jquery.com/jquery-$(JQUERY_VERSION).min.js
	wget -O shoppinglist/static/jquery.mobile.min.js https://code.jquery.com/mobile/$(JQUERY_MOBILE_VERSION)/jquery.mobile-$(JQUERY_MOBILE_VERSION).min.js
	wget -O shoppinglist/static/jquery.mobile.min.css https://code.jquery.com/mobile/$(JQUERY_MOBILE_VERSION)/jquery.mobile-$(JQUERY_MOBILE_VERSION).min.css
	mkdir -p shoppinglist/static/images/icons-png
	wget -O shoppinglist/static/images/ajax-loader.gif https://code.jquery.com/mobile/$(JQUERY_MOBILE_VERSION)/images/ajax-loader.gif
	wget -O shoppinglist/static/images/icons-png/grid-white.png https://code.jquery.com/mobile/$(JQUERY_MOBILE_VERSION)/images/icons-png/grid-white.png
	cd shoppinglist/static && sha256sum *.css *.js > SHA256SUMS

.PHONY: update
update:
	git pull
	make
	touch pyramid.wsgi

.PHONY: clean
clean:
	find -name '*.pyc' -delete

.PHONY: dist
dist: bin/python
	bin/python setup.py sdist

.PHONY: distclean
distclean: clean
	rm -rf bin/ dist/ include/ lib/ *.egg-info/ build/ local/ .venv/
	rm -f .coverage tags

ShoppingList.db: | $(egg_link)
	test -f $@ || bin/init_ShoppingList_db development.ini

shoppinglist/static/SHA256SUMS: $(static_assets)
	cd shoppinglist/static && sha256sum *.css *.js > SHA256SUMS

.PHONY: update-static-manifest
update-static-manifest:
	make -B shoppinglist/static/SHA256SUMS

$(egg_link): bin/python setup.py
	bin/pip install -e .[testing] watchdog -c requirements.txt

bin/pserve: bin/pip
	bin/pip install pyramid watchdog -c requirements.txt
	ln -sfrt bin/ .venv/$@
	touch -c $@

bin/pytest: bin/pip
	bin/pip install pytest pytest-cov -c requirements.txt
	ln -sfrt bin/ .venv/$@
	touch -c $@

bin/flake8: bin/pip
	bin/pip install flake8 -c requirements.txt
	ln -sfrt bin/ .venv/$@
	touch -c $@

bin/python bin/pip: | bin .venv
	ln -sfrt bin/ .venv/$@

bin:
	mkdir $@

.venv:
	virtualenv -p $(PYTHON) .venv
	.venv/bin/pip install -U pip

.PHONY: recreate-virtualenv
recreate-virtualenv:
	make -B bin/python
