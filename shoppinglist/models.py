from sqlalchemy import Column, Integer, Text, Boolean, engine_from_config
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
import zope.sqlalchemy


Base = declarative_base()


def includeme(config):
    settings = config.get_settings()
    settings['tm.manager_hook'] = 'pyramid_tm.explicit_manager'
    config.include("pyramid_tm")
    config.include("pyramid_retry")
    session_factory = get_session_factory(get_engine(settings))
    config.registry['dbsession_factory'] = session_factory
    config.add_request_method(
        lambda r: get_dbsession(r.tm, session_factory),
        'dbsession',
        reify=True
    )


def get_dbsession(transaction_manager, session_factory):
    dbsession = session_factory()
    zope.sqlalchemy.register(
        dbsession, transaction_manager=transaction_manager)
    return dbsession


def get_engine(settings, prefix='sqlalchemy.'):
    return engine_from_config(settings, prefix)


def get_session_factory(engine):
    factory = sessionmaker()
    factory.configure(bind=engine)
    return factory


class ListItem(Base):
    __tablename__ = "items"
    id = Column(Integer, primary_key=True)
    title = Column(Text)
    checked = Column(Boolean)

    def __init__(self, title, checked=False):
        self.title = title
        self.checked = checked
