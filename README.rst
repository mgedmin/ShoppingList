ShoppingList README
===================

.. image:: https://travis-ci.org/mgedmin/ShoppingList.svg?branch=master
    :target: https://travis-ci.org/mgedmin/ShoppingList

Small web-based shopping list application for me:

* There is one and only one shopping list per deployment
* It can be accessed (and edited) from multiple browsers, desktop and mobile
* There are no user accounts and no access control (but you can use Apache's)
* There are no update notifications yet: you have to manually reload the
  page to see the changes if anyone else edited it


Running a development version
-----------------------------

After cloning this repository do ::

    make run

Make should take care of everything.  You need make (obviously), python,
virtualenv, and an Internet connection (to download Pyramid etc. from PyPI).


Deployment
----------

Here's a sample Apache config for mod_wsgi deployment::

  WSGIScriptAlias /list "/opt/ShoppingList/pyramid.wsgi"
  WSGIDaemonProcess shoppinglist user=www-data group=www-data processes=2 threads=5 \
    maximum-requests=1000 umask=0007 display-name=wsgi-shoppinglist \
    python-path=/opt/ShoppingList/lib/python3.7/site-packages
  WSGIProcessGroup shoppinglist
  WSGIPassAuthorization on

If you also want password-protection, add ::

  <Location /list>
    AuthType Basic
    AuthName "example.com"
    AuthUserFile /etc/apache2/shoppinglist.passwd
    Require valid-user
  </Location>

and be sure to use HTTPS.

You'll want to create a database writable to the 'www-data' user in the ``var``
subdirectory (``production.ini`` looks for it there)::

  sudo make prod-db

