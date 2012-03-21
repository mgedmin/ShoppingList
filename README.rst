ShoppingList README
===================

Small web-based shopping list application for me.


Running a development version
-----------------------------

After cloning this repository do ::

    make run

Make should take care of everything.  You need make (obviously), python,
virtualenv, and an Internet connection (to download Pyramid etc. from PyPI).


Security
--------

There is none.  Use a front-end server like Apache with mod_wsgi to prevent
unauthorized access.  Do not use ``make run`` or ``bin/pserve development.ini``
on a multi-user machine.

But, hey, it's just a shopping list.


Deployment
----------

Here's a sample Apache config::

  WSGIScriptAlias /list "/opt/ShoppingList/pyramid.wsgi"
  WSGIDaemonProcess shoppinglist user=buildbot group=buildbot processes=2 threads=5 \
    maximum-requests=1000 umask=0007 display-name=wsgi-shoppinglist \
    python-path=/opt/ShoppingList/lib/python2.6/site-packages
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
