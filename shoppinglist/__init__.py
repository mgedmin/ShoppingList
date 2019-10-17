from pyramid.config import Configurator

from .cache import ChecksumCacheBuster


def main(global_config, **settings):
    """This function returns a Pyramid WSGI application."""
    config = Configurator(settings=settings)
    config.add_settings(
        {"mako.imports": "from shoppinglist.filters import json"}
    )
    config.include("pyramid_mako")
    config.include("pyramid_tm")
    config.include(".models")
    config.add_static_view("static", "static", cache_max_age=365*24*3600)
    config.add_cache_buster("static", ChecksumCacheBuster("static/SHA256SUMS"))
    config.add_route("home", "/")
    # Let's go nuts with REST, why don't we?
    config.add_route("list_items", "/api/items", request_method="GET")
    config.add_route("add_item", "/api/items", request_method="POST")
    config.add_route("remove_item", "/api/items/{id}", request_method="DELETE")
    config.add_route(
        "check_item", "/api/items/{id}/checked", request_method="POST"
    )
    config.add_route(
        "uncheck_item", "/api/items/{id}/checked", request_method="DELETE"
    )
    config.add_route("clear_list", "/api/items", request_method="DELETE")
    config.scan()
    return config.make_wsgi_app()
