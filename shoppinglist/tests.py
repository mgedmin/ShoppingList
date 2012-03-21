import unittest
import transaction

from pyramid import testing
from pyramid.httpexceptions import HTTPNotFound

from .models import DBSession

class TestMyView(unittest.TestCase):
    def setUp(self):
        self.config = testing.setUp()
        from sqlalchemy import create_engine
        engine = create_engine('sqlite://')
        from .models import (
            Base,
            ListItem,
            )
        DBSession.configure(bind=engine)
        Base.metadata.create_all(engine)
        with transaction.manager:
            DBSession.add(ListItem('bread'))
            DBSession.add(ListItem('juice', checked=True))

    def tearDown(self):
        DBSession.remove()
        testing.tearDown()

    def test_main_view(self):
        from .views import main_view
        request = testing.DummyRequest()
        info = main_view(request)
        self.assertEqual(len(info['items']), 2)

    def test_list_items(self):
        from .views import list_items
        request = testing.DummyRequest()
        info = list_items(request)
        self.assertEqual(len(info['items']), 2)

    def test_add_item(self):
        from .models import ListItem
        from .views import add_item
        request = testing.DummyRequest(post=dict(title='apples '))
        info = add_item(request)
        self.assertEqual(info['success'], 'added "apples"')
        item = DBSession.query(ListItem).filter_by(id=info['id']).one()
        self.assertEqual(item.title, 'apples')

    def test_add_item_no_title(self):
        from .views import add_item
        request = testing.DummyRequest()
        info = add_item(request)
        self.assertEqual(info['error'], "'title' parameter blank or missing")

    def test_add_item_blank_title(self):
        from .views import add_item
        request = testing.DummyRequest(post=dict(title=' '))
        info = add_item(request)
        self.assertEqual(info['error'], "'title' parameter blank or missing")

    def test_remove_item(self):
        from .models import ListItem
        from .views import remove_item
        item = DBSession.query(ListItem).filter_by(title='juice').one()
        request = testing.DummyRequest()
        request.matchdict['id'] = unicode(item.id)
        info = remove_item(request)
        self.assertEqual(info['success'], 'removed "juice"')
        self.assertEqual(DBSession.query(ListItem).count(), 1)

    def test_remove_item_not_found(self):
        from .views import remove_item
        request = testing.DummyRequest()
        request.matchdict['id'] = u'12345xyzzy'
        info = remove_item(request)
        self.assertTrue(isinstance(info, HTTPNotFound))

    def test_check_item(self):
        from .models import ListItem
        from .views import check_item
        item = DBSession.query(ListItem).filter_by(title='bread').one()
        request = testing.DummyRequest()
        request.matchdict['id'] = unicode(item.id)
        info = check_item(request)
        self.assertEqual(info['success'], 'checked "bread"')
        self.assertEqual(item.checked, True)

    def test_check_item_not_found(self):
        from .views import check_item
        request = testing.DummyRequest()
        request.matchdict['id'] = u'12345xyzzy'
        info = check_item(request)
        self.assertTrue(isinstance(info, HTTPNotFound))

    def test_uncheck_item(self):
        from .models import ListItem
        from .views import uncheck_item
        item = DBSession.query(ListItem).filter_by(title='juice').one()
        request = testing.DummyRequest()
        request.matchdict['id'] = unicode(item.id)
        info = uncheck_item(request)
        self.assertEqual(info['success'], 'unchecked "juice"')
        self.assertEqual(item.checked, False)

    def test_uncheck_item_not_found(self):
        from .views import uncheck_item
        request = testing.DummyRequest()
        request.matchdict['id'] = u'12345xyzzy'
        info = uncheck_item(request)
        self.assertTrue(isinstance(info, HTTPNotFound))

    def test_clear_list(self):
        from .models import ListItem
        from .views import clear_list
        request = testing.DummyRequest()
        info = clear_list(request)
        self.assertEqual(info['success'], 'deleted 2 items')
        self.assertEqual(DBSession.query(ListItem).count(), 0)

