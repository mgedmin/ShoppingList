import unittest

import transaction
from pyramid import testing
from pyramid.httpexceptions import HTTPFound, HTTPNotFound

from .models import (
    Base,
    ListItem,
    get_dbsession,
    get_engine,
    get_session_factory,
)


class BaseTest(unittest.TestCase):

    def setUp(self):
        self.config = testing.setUp(settings={
            'sqlalchemy.url': 'sqlite:///:memory:',
        })
        self.config.include('.models')

        settings = self.config.get_settings()
        self.engine = get_engine(settings)
        session_factory = get_session_factory(self.engine)
        self.session = get_dbsession(transaction.manager, session_factory)

        self.init_db()

    def init_db(self):
        Base.metadata.create_all(self.engine)
        with transaction.manager:
            self.session.add(ListItem("bread"))
            self.session.add(ListItem("juice", checked=True))

    def tearDown(self):
        transaction.abort()
        self.engine.dispose()
        testing.tearDown()

    def dummy_request(self, **kwargs):
        return testing.DummyRequest(dbsession=self.session, **kwargs)


class TestViews(BaseTest):

    def test_main_view(self):
        from .views import main_view

        request = self.dummy_request()
        info = main_view(request)
        self.assertEqual(len(info["items"]), 2)

    def test_main_view_add_item(self):
        from .views import main_view

        request = self.dummy_request(post=dict(add="aitemu"))
        response = main_view(request)
        self.assertIsInstance(response, HTTPFound)
        item = self.session.query(ListItem).filter_by(title="aitemu").one()
        self.assertEqual(item.title, "aitemu")
        self.assertEqual(item.checked, False)

    def test_main_view_remove_item(self):
        from .views import main_view

        item = self.session.query(ListItem).filter_by(title="bread").one()
        request = self.dummy_request(post=dict(remove=item.id))
        response = main_view(request)
        self.assertIsInstance(response, HTTPFound)
        self.assertEqual(self.session.query(ListItem).count(), 1)

    def test_main_view_remove_item_not_found(self):
        from .views import main_view

        request = self.dummy_request(post=dict(remove="no such id"))
        response = main_view(request)
        self.assertIsInstance(response, HTTPFound)
        self.assertEqual(self.session.query(ListItem).count(), 2)

    def test_main_view_check_item(self):
        from .views import main_view

        item = self.session.query(ListItem).filter_by(title="bread").one()
        request = self.dummy_request(post=dict(check=item.id))
        response = main_view(request)
        self.assertIsInstance(response, HTTPFound)
        self.assertEqual(item.checked, True)

    def test_main_view_check_item_not_found(self):
        from .views import main_view

        request = self.dummy_request(post=dict(check="no such id"))
        response = main_view(request)
        self.assertIsInstance(response, HTTPFound)

    def test_main_view_uncheck_item(self):
        from .views import main_view

        item = self.session.query(ListItem).filter_by(title="juice").one()
        request = self.dummy_request(post=dict(uncheck=item.id))
        response = main_view(request)
        self.assertIsInstance(response, HTTPFound)
        self.assertEqual(item.checked, False)

    def test_main_view_uncheck_item_not_found(self):
        from .views import main_view

        request = self.dummy_request(post=dict(uncheck="no such id"))
        response = main_view(request)
        self.assertIsInstance(response, HTTPFound)

    def test_list_items(self):
        from .views import list_items

        request = self.dummy_request()
        info = list_items(request)
        self.assertEqual(len(info["items"]), 2)

    def test_add_item(self):
        from .models import ListItem
        from .views import add_item

        request = self.dummy_request(post=dict(title="apples "))
        info = add_item(request)
        self.assertEqual(info["success"], 'added "apples"')
        item = self.session.query(ListItem).filter_by(id=info["id"]).one()
        self.assertEqual(item.title, "apples")
        self.assertEqual(item.checked, False)

    def test_add_item_checked(self):
        from .models import ListItem
        from .views import add_item

        request = self.dummy_request(
            post=dict(title="apples ", checked="true")
        )
        info = add_item(request)
        self.assertEqual(info["success"], 'added "apples"')
        item = self.session.query(ListItem).filter_by(id=info["id"]).one()
        self.assertEqual(item.title, "apples")
        self.assertEqual(item.checked, True)

    def test_add_item_unchecked(self):
        from .models import ListItem
        from .views import add_item

        request = self.dummy_request(
            post=dict(title="apples ", checked="false")
        )
        info = add_item(request)
        self.assertEqual(info["success"], 'added "apples"')
        item = self.session.query(ListItem).filter_by(id=info["id"]).one()
        self.assertEqual(item.title, "apples")
        self.assertEqual(item.checked, False)

    def test_add_item_no_title(self):
        from .views import add_item

        request = self.dummy_request()
        info = add_item(request)
        self.assertEqual(info["error"], "'title' parameter blank or missing")

    def test_add_item_blank_title(self):
        from .views import add_item

        request = self.dummy_request(post=dict(title=" "))
        info = add_item(request)
        self.assertEqual(info["error"], "'title' parameter blank or missing")

    def test_remove_item(self):
        from .models import ListItem
        from .views import remove_item

        item = self.session.query(ListItem).filter_by(title="juice").one()
        request = self.dummy_request()
        request.matchdict["id"] = str(item.id)
        info = remove_item(request)
        self.assertEqual(info["success"], 'removed "juice"')
        self.assertEqual(self.session.query(ListItem).count(), 1)

    def test_remove_item_not_found(self):
        from .views import remove_item

        request = self.dummy_request()
        request.matchdict["id"] = u"12345xyzzy"
        info = remove_item(request)
        self.assertIsInstance(info, HTTPNotFound)

    def test_check_item(self):
        from .models import ListItem
        from .views import check_item

        item = self.session.query(ListItem).filter_by(title="bread").one()
        request = self.dummy_request()
        request.matchdict["id"] = str(item.id)
        info = check_item(request)
        self.assertEqual(info["success"], 'checked "bread"')
        self.assertEqual(item.checked, True)

    def test_check_item_not_found(self):
        from .views import check_item

        request = self.dummy_request()
        request.matchdict["id"] = u"12345xyzzy"
        info = check_item(request)
        self.assertIsInstance(info, HTTPNotFound)

    def test_uncheck_item(self):
        from .models import ListItem
        from .views import uncheck_item

        item = self.session.query(ListItem).filter_by(title="juice").one()
        request = self.dummy_request()
        request.matchdict["id"] = str(item.id)
        info = uncheck_item(request)
        self.assertEqual(info["success"], 'unchecked "juice"')
        self.assertEqual(item.checked, False)

    def test_uncheck_item_not_found(self):
        from .views import uncheck_item

        request = self.dummy_request()
        request.matchdict["id"] = u"12345xyzzy"
        info = uncheck_item(request)
        self.assertIsInstance(info, HTTPNotFound)

    def test_clear_list(self):
        from .models import ListItem
        from .views import clear_list

        request = self.dummy_request()
        info = clear_list(request)
        self.assertEqual(info["success"], "deleted 2 items")
        self.assertEqual(self.session.query(ListItem).count(), 0)


class TestUninitializedDB(BaseTest):

    def init_db(self):
        pass

    def test_main_view(self):
        from .views import main_view

        request = self.dummy_request()
        res = main_view(request)
        self.assertEqual(res.status_int, 500)


class FunctionalTests(unittest.TestCase):

    @classmethod
    def setUpClass(cls):
        from webtest import TestApp

        from . import main

        settings = {
            'sqlalchemy.url': 'sqlite:///:memory:'
        }
        app = main({}, **settings)
        cls.testapp = TestApp(app)

        session_factory = app.registry['dbsession_factory']
        cls.engine = session_factory.kw['bind']
        Base.metadata.create_all(bind=cls.engine)

        session_factory = get_session_factory(cls.engine)
        cls.session = get_dbsession(transaction.manager, session_factory)

    @classmethod
    def tearDownClass(cls):
        Base.metadata.drop_all(bind=cls.engine)

    def test_root(self):
        res = self.testapp.get('/', status=200)
        self.assertIn('<h1>Shopping List</h1>', res.text)

    def test_html_injection(self):
        res = self.testapp.get('/', status=200)
        baseline = res.text.count('</script>')
        with transaction.manager:
            self.session.add(ListItem("<script>alert(1)</script>"))
        res = self.testapp.get('/', status=200)
        self.assertEqual(res.text.count('</script>'), baseline)
        self.assertIn(r'"<script>alert(1)<\/script>"', res.text)
