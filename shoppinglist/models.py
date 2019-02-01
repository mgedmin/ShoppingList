from sqlalchemy import Column, Integer, Text, Boolean
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import scoped_session, sessionmaker
from zope.sqlalchemy import ZopeTransactionExtension


DBSession = scoped_session(sessionmaker(extension=ZopeTransactionExtension()))
Base = declarative_base()


class ListItem(Base):
    __tablename__ = "items"
    id = Column(Integer, primary_key=True)
    title = Column(Text)
    checked = Column(Boolean)

    def __init__(self, title, checked=False):
        self.title = title
        self.checked = checked
