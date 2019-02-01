import os

from setuptools import setup, find_packages


here = os.path.abspath(os.path.dirname(__file__))


def read(filename):
    with open(os.path.join(here, filename)) as fp:
        return fp.read()


README = read("README.rst")
CHANGES = read("CHANGES.rst")


requires = [
    "pyramid",
    "SQLAlchemy",
    "transaction",
    "pyramid_tm",
    "pyramid_debugtoolbar",
    "zope.sqlalchemy",
    "waitress",
]

setup(
    name="ShoppingList",
    version="0.2",
    description="ShoppingList",
    long_description=README + "\n\n" + CHANGES,
    classifiers=[
        "Programming Language :: Python",
        "Framework :: Pylons",
        "Topic :: Internet :: WWW/HTTP",
        "Topic :: Internet :: WWW/HTTP :: WSGI :: Application",
    ],
    author="Marius Gedminas",
    author_email="marius@gedmin.as",
    url="https://github.com/mgedmin/ShoppingList",
    keywords="web wsgi bfg pylons pyramid",
    packages=find_packages(),
    include_package_data=True,
    zip_safe=False,
    test_suite="shoppinglist",
    install_requires=requires,
    entry_points={
        "paste.app_factory": ["main = shoppinglist:main"],
        "console_scripts": [
            "init_ShoppingList_db = shoppinglist.scripts.initializedb:main"
        ],
    },
)
