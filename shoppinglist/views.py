import time

from pyramid.httpexceptions import HTTPFound, HTTPNotFound
from pyramid.response import Response
from pyramid.view import view_config
from sqlalchemy.exc import DBAPIError
from sqlalchemy.orm.exc import NoResultFound

from .models import ListItem


@view_config(route_name="home", renderer="shoppinglist:templates/list.mako")
def main_view(request):
    check = request.POST.get('check')
    if check:
        try:
            item = request.dbsession.query(ListItem).filter_by(id=check).one()
        except NoResultFound:
            pass
        else:
            item.checked = True
    uncheck = request.POST.get('uncheck')
    if uncheck:
        try:
            item = (
                request.dbsession.query(ListItem).filter_by(id=uncheck).one()
            )
        except NoResultFound:
            pass
        else:
            item.checked = False
    remove = request.POST.get('remove')
    if remove:
        try:
            item = request.dbsession.query(ListItem).filter_by(id=remove).one()
        except NoResultFound:
            pass
        else:
            request.dbsession.delete(item)
    add = request.POST.get('add')
    if add:
        item = ListItem(add)
        request.dbsession.add(item)
        request.dbsession.flush()  # force ID allocation
    if request.method == 'POST':
        return HTTPFound(location=f"/?cache_bust={time.time()}")
    try:
        items = request.dbsession.query(ListItem).all()
    except DBAPIError:
        return Response(
            conn_err_msg, content_type="text/plain", status_int=500
        )
    request.response.cache_control = 'no-cache'
    return {"items": items}


conn_err_msg = """\
Pyramid is having a problem using your SQL database.  The problem
might be caused by one of the following things:

1.  You may need to run the "init_ShoppingList_db" script
    to initialize your database tables.  Check your virtual
    environment's "bin" directory for this script and try to run it.

2.  Your database server may not be running.  Check that the
    database server referred to by the "sqlalchemy.url" setting in
    your "development.ini" file is running.

After you fix the problem, please restart the Pyramid application to
try it again.
"""


@view_config(route_name="list_items", renderer="json")
def list_items(request):
    items = request.dbsession.query(ListItem).all()
    return {
        "success": "",
        "items": [
            {"id": item.id, "title": item.title, "checked": item.checked}
            for item in items
        ],
    }


@view_config(route_name="add_item", renderer="json")
def add_item(request):
    title = request.POST.get("title", "").strip()
    if not title:
        return {"error": "'title' parameter blank or missing"}
    item = ListItem(title)
    if request.POST.get("checked", "").lower() == "true":
        item.checked = True
    request.dbsession.add(item)
    request.dbsession.flush()  # force ID allocation
    return {"success": 'added "%s"' % title, "id": item.id}


@view_config(route_name="remove_item", renderer="json")
def remove_item(request):
    item_id = request.matchdict["id"]
    try:
        item = request.dbsession.query(ListItem).filter_by(id=item_id).one()
    except NoResultFound:
        return HTTPNotFound()
    request.dbsession.delete(item)
    return {"success": 'removed "%s"' % item.title}


@view_config(route_name="check_item", renderer="json")
def check_item(request):
    item_id = request.matchdict["id"]
    try:
        item = request.dbsession.query(ListItem).filter_by(id=item_id).one()
    except NoResultFound:
        return HTTPNotFound()
    item.checked = True
    return {"success": 'checked "%s"' % item.title}


@view_config(route_name="uncheck_item", renderer="json")
def uncheck_item(request):
    item_id = request.matchdict["id"]
    try:
        item = request.dbsession.query(ListItem).filter_by(id=item_id).one()
    except NoResultFound:
        return HTTPNotFound()
    item.checked = False
    return {"success": 'unchecked "%s"' % item.title}


@view_config(route_name="clear_list", renderer="json")
def clear_list(request):
    n = request.dbsession.query(ListItem).delete()
    return {"success": "deleted %d items" % n}
