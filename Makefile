PYTHON = python
pypackage = ShoppingList
egg_link = lib/python*/site-packages/$(pypackage).egg-link

all: bin/pcreate bin/pserve $(egg_link) bin/pytest bin/flake8 ShoppingList.db

run: bin/pserve $(egg_link) ShoppingList.db
	bin/pserve development.ini --reload

test: bin/pytest $(egg_link)
	bin/pytest --cov

lint: bin/flake8
	bin/flake8 *.py $(pypackage)

prod-db: var/ShoppingList.db

var/ShoppingList.db: ShoppingList.db var
	install -m 644 -o www-data -g www-data ShoppingList.db var/ShoppingList.db

var:
	install -m 755 -o www-data -g www-data -d var || rmdir var

update-all-packages: bin/pip
	bin/pip install -U pip setuptools wheel
	bin/pip install -U --upgrade-strategy=eager pytest pytest-cov flake8 watchdog -e .
	make
	make update-requirements

update-requirements: bin/pip
	PYTHONPATH= bin/pip freeze | grep -v '^-e .*$(pypackage)$$' > requirements.txt

update:
	git pull
	make
	touch pyramid.wsgi

clean:
	find -name '*.pyc' -delete

dist: bin/python
	bin/python setup.py sdist

distclean: clean
	rm -rf bin/ dist/ include/ lib/ *.egg-info/ build/ local/
	rm -f .coverage tags

ShoppingList.db: $(egg_link)
	test -f $@ || bin/init_ShoppingList_db development.ini

$(egg_link): bin/python setup.py
	bin/pip install -e .

bin/pcreate bin/pserve: bin/pip
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
