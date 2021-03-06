import os
import sys
import transaction

from pyramid.paster import get_appsettings, setup_logging

from ..models import Base, get_dbsession, get_engine, get_session_factory


def usage(argv):
    cmd = os.path.basename(argv[0])
    print(
        "usage: %s <config_uri>\n"
        '(example: "%s development.ini")' % (cmd, cmd)
    )
    sys.exit(1)


def main(argv=sys.argv):
    if len(argv) != 2:
        usage(argv)
    config_uri = argv[1]
    setup_logging(config_uri)
    settings = get_appsettings(config_uri)
    engine = get_engine(settings)
    session_factory = get_session_factory(engine)
    dbsession = get_dbsession(transaction.manager, session_factory)
    Base.metadata.create_all(engine)
    with transaction.manager:
        # create any database rows that must exist in the DB
        # dbsession.add(MyModel(...))
        pass
