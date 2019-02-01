from json import dumps

from markupsafe import Markup


def json(s):
    # XXX: the idea is that if I return Markup and do ${'<>'|json} in a mako
    # template, I'll get '<>', not '&lt;&gt;'.  This doesn't work and I have
    # to do ${...|json,n} anyway.  Why?
    return Markup(dumps(s).replace('</script', r'<\/script'))
