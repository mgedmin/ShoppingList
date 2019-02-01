import unittest
import transaction

from pyramid import testing
from pyramid.httpexceptions import HTTPNotFound

from .models import DBSession, Base, ListItem


class TestViews(unittest.TestCase):
    def setUp(self):
        self.config = testing.setUp()
        from sqlalchemy import create_engine

        engine = create_engine("sqlite://")
        DBSession.configure(bind=engine)
        Base.metadata.create_all(engine)
        with transaction.manager:
            DBSession.add(ListItem("bread"))
            DBSession.add(ListItem("juice", checked=True))

    def tearDown(self):
        DBSession.remove()
        testing.tearDown()

    def test_main_view(self):
        from .views import main_view

        request = testing.DummyRequest()
        info = main_view(request)
        self.assertEqual(len(info["items"]), 2)

    def test_list_items(self):
        from .views import list_items

        request = testing.DummyRequest()
        info = list_items(request)
        self.assertEqual(len(info["items"]), 2)

    def test_add_item(self):
        from .models import ListItem
        from .views import add_item

        request = testing.DummyRequest(post=dict(title="apples "))
        info = add_item(request)
        self.assertEqual(info["success"], 'added "apples"')
        item = DBSession.query(ListItem).filter_by(id=info["id"]).one()
        self.assertEqual(item.title, "apples")
        self.assertEqual(item.checked, False)

    def test_add_item_checked(self):
        from .models import ListItem
        from .views import add_item

        request = testing.DummyRequest(
            post=dict(title="apples ", checked="true")
        )
        info = add_item(request)
        self.assertEqual(info["success"], 'added "apples"')
        item = DBSession.query(ListItem).filter_by(id=info["id"]).one()
        self.assertEqual(item.title, "apples")
        self.assertEqual(item.checked, True)

    def test_add_item_unchecked(self):
        from .models import ListItem
        from .views import add_item

        request = testing.DummyRequest(
            post=dict(title="apples ", checked="false")
        )
        info = add_item(request)
        self.assertEqual(info["success"], 'added "apples"')
        item = DBSession.query(ListItem).filter_by(id=info["id"]).one()
        self.assertEqual(item.title, "apples")
        self.assertEqual(item.checked, False)

    def test_add_item_no_title(self):
        from .views import add_item

        request = testing.DummyRequest()
        info = add_item(request)
        self.assertEqual(info["error"], "'title' parameter blank or missing")

    def test_add_item_blank_title(self):
        from .views import add_item

        request = testing.DummyRequest(post=dict(title=" "))
        info = add_item(request)
        self.assertEqual(info["error"], "'title' parameter blank or missing")

    def test_remove_item(self):
        from .models import ListItem
        from .views import remove_item

        item = DBSession.query(ListItem).filter_by(title="juice").one()
        request = testing.DummyRequest()
        request.matchdict["id"] = str(item.id)
        info = remove_item(request)
        self.assertEqual(info["success"], 'removed "juice"')
        self.assertEqual(DBSession.query(ListItem).count(), 1)

    def test_remove_item_not_found(self):
        from .views import remove_item

        request = testing.DummyRequest()
        request.matchdict["id"] = u"12345xyzzy"
        info = remove_item(request)
        self.assertTrue(isinstance(info, HTTPNotFound))

    def test_check_item(self):
        from .models import ListItem
        from .views import check_item

        item = DBSession.query(ListItem).filter_by(title="bread").one()
        request = testing.DummyRequest()
        request.matchdict["id"] = str(item.id)
        info = check_item(request)
        self.assertEqual(info["success"], 'checked "bread"')
        self.assertEqual(item.checked, True)

    def test_check_item_not_found(self):
        from .views import check_item

        request = testing.DummyRequest()
        request.matchdict["id"] = u"12345xyzzy"
        info = check_item(request)
        self.assertTrue(isinstance(info, HTTPNotFound))

    def test_uncheck_item(self):
        from .models import ListItem
        from .views import uncheck_item

        item = DBSession.query(ListItem).filter_by(title="juice").one()
        request = testing.DummyRequest()
        request.matchdict["id"] = str(item.id)
        info = uncheck_item(request)
        self.assertEqual(info["success"], 'unchecked "juice"')
        self.assertEqual(item.checked, False)

    def test_uncheck_item_not_found(self):
        from .views import uncheck_item

        request = testing.DummyRequest()
        request.matchdict["id"] = u"12345xyzzy"
        info = uncheck_item(request)
        self.assertTrue(isinstance(info, HTTPNotFound))

    def test_clear_list(self):
        from .models import ListItem
        from .views import clear_list

        request = testing.DummyRequest()
        info = clear_list(request)
        self.assertEqual(info["success"], "deleted 2 items")
        self.assertEqual(DBSession.query(ListItem).count(), 0)


class TestUninitializedDB(unittest.TestCase):

    def setUp(self):
        self.config = testing.setUp()
        from sqlalchemy import create_engine

        engine = create_engine("sqlite://")
        DBSession.configure(bind=engine)

    def tearDown(self):
        DBSession.remove()
        testing.tearDown()

    def test_main_view(self):
        from .views import main_view

        request = testing.DummyRequest()
        res = main_view(request)
        self.assertEqual(res.status_int, 500)


class FunctionalTests(unittest.TestCase):

    def setUp(self):
        from webtest import TestApp
        from . import main

        app = main({}, **{
            'sqlalchemy.url': 'sqlite:///:memory:'
        })
        Base.metadata.create_all(DBSession.bind)
        self.testapp = TestApp(app)

    def tearDown(self):
        DBSession.remove()

    def test_root(self):
        res = self.testapp.get('/', status=200)
        self.assertIn('<h1>Shopping List</h1>', res.text)

    def test_html_injection(self):
        with transaction.manager:
            DBSession.add(ListItem("<script>alert(1)</script>"))
        res = self.testapp.get('/', status=200)
        self.assertEqual(res.text.count('</script>'), 3)
        self.assertIn(r'"<script>alert(1)<\/script>"', res.text)
