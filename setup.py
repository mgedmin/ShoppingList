import os

from setuptools import setup, find_packages

here = os.path.abspath(os.path.dirname(__file__))
README = open(os.path.join(here, 'README.rst')).read()
CHANGES = open(os.path.join(here, 'CHANGES.rst')).read()

requires = [
    'pyramid',
    'SQLAlchemy',
    'transaction',
    'pyramid_tm',
    'pyramid_debugtoolbar',
    'zope.sqlalchemy',
    'waitress',
    ]

setup(name='ShoppingList',
      version='0.0',
      description='ShoppingList',
      long_description=README + '\n\n' +  CHANGES,
      classifiers=[
        "Programming Language :: Python",
        "Framework :: Pylons",
        "Topic :: Internet :: WWW/HTTP",
        "Topic :: Internet :: WWW/HTTP :: WSGI :: Application",
        ],
      author='Marius Gedminas',
      author_email='marius@gedmin.as',
      url='https://github.com/mgedmin/ShoppingList',
      keywords='web wsgi bfg pylons pyramid',
      packages=find_packages(),
      include_package_data=True,
      zip_safe=False,
      test_suite='shoppinglist',
      install_requires=requires,
      entry_points="""\
      [paste.app_factory]
      main = shoppinglist:main
      [console_scripts]
      initialize_ShoppingList_db = shoppinglist.scripts.initializedb:main
      """,
      )

