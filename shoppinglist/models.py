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
    dbmaker = get_dbmaker(get_engine(settings))
    config.registry['dbsession_factory'] = dbmaker
    config.add_request_method(
        lambda r: get_session(r.tm, dbmaker),
        'dbsession',
        reify=True
    )


def get_session(transaction_manager, dbmaker):
    dbsession = dbmaker()
    zope.sqlalchemy.register(
        dbsession, transaction_manager=transaction_manager)
    return dbsession


def get_engine(settings, prefix='sqlalchemy.'):
    return engine_from_config(settings, prefix)


def get_dbmaker(engine):
    dbmaker = sessionmaker()
    dbmaker.configure(bind=engine)
    return dbmaker


class ListItem(Base):
    __tablename__ = "items"
    id = Column(Integer, primary_key=True)
    title = Column(Text)
    checked = Column(Boolean)

    def __init__(self, title, checked=False):
        self.title = title
        self.checked = checked
