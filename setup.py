import os

from setuptools import setup, find_packages


here = os.path.abspath(os.path.dirname(__file__))


def read(filename):
    with open(os.path.join(here, filename)) as fp:
        return fp.read()


README = read("README.rst")
CHANGES = read("CHANGES.rst")


requires = [
    "SQLAlchemy < 2",
    "markupsafe",
    "plaster_pastedeploy",
    "pyramid",
    "pyramid_debugtoolbar",
    "pyramid_mako",
    "pyramid_retry",
    "pyramid_tm",
    "transaction",
    "waitress",
    "zope.sqlalchemy",
]

tests_require = [
    "WebTest",
]

setup(
    name="ShoppingList",
    version="0.3",
    description="A very simple shopping list webapp",
    long_description=README + "\n\n" + CHANGES,
    classifiers=[
        "Programming Language :: Python :: 3.9",
        "Programming Language :: Python :: 3.10",
        "Programming Language :: Python :: 3.11",
        "Programming Language :: Python :: 3.12",
        "Framework :: Pyramid",
        "Topic :: Internet :: WWW/HTTP",
        "Topic :: Internet :: WWW/HTTP :: WSGI :: Application",
    ],
    author="Marius Gedminas",
    author_email="marius@gedmin.as",
    url="https://github.com/mgedmin/ShoppingList",
    keywords="web wsgi pyramid shopping list",
    packages=find_packages(),
    include_package_data=True,
    zip_safe=False,
    test_suite="shoppinglist",
    install_requires=requires,
    extras_require={"testing": tests_require},
    entry_points={
        "paste.app_factory": ["main = shoppinglist:main"],
        "console_scripts": [
            "init_ShoppingList_db = shoppinglist.scripts.initializedb:main"
        ],
    },
)
