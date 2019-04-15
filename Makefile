PYTHON = python
pypackage = ShoppingList
egg_link = lib/python*/site-packages/$(pypackage).egg-link
static_assets = shoppinglist/static/*.css shoppinglist/static/*.js

.PHONY: all
all: bin/pserve $(egg_link) bin/pytest bin/flake8 ShoppingList.db shoppinglist/static/SHA256SUMS

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

prod-db: var/ShoppingList.db

var/ShoppingList.db: ShoppingList.db var
	install -m 644 -o www-data -g www-data ShoppingList.db var/ShoppingList.db

var:
	install -m 755 -o www-data -g www-data -d var || rmdir var

.PHONY: update-all-packages
update-all-packages: bin/pip
	bin/pip install -U pip setuptools wheel
	bin/pip install -U --upgrade-strategy=eager pytest pytest-cov flake8 watchdog -e .
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
	rm -rf bin/ dist/ include/ lib/ *.egg-info/ build/ local/
	rm -f .coverage tags

ShoppingList.db: | $(egg_link)
	test -f $@ || bin/init_ShoppingList_db development.ini

shoppinglist/static/SHA256SUMS: $(static_assets)
	cd shoppinglist/static && sha256sum *.css *.js > SHA256SUMS

.PHONY: update-static-manifest
update-static-manifest:
	make -B shoppinglist/static/SHA256SUMS

$(egg_link): bin/python setup.py
	bin/pip install -e .[testing] watchdog

bin/pserve: bin/pip
	bin/pip install pyramid watchdog

bin/pytest: bin/pip
	bin/pip install pytest pytest-cov

bin/flake8: bin/pip
	bin/pip install flake8

bin/python bin/pip:
	virtualenv -p $(PYTHON) .

.PHONY: recreate-virtualenv
recreate-virtualenv:
	make -B bin/python
