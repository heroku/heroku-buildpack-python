# -*- coding: utf-8 -*-

from datetime import datetime

try:
    import requests
except ImportError:
    from .packages import requests


DEFAULT_LOGPLEX_URL = 'https://east.logplex.io/logs'
DEFAULT_LOGPLEX_TOKEN = None
DETAULT_LOGPLEX_TIMEOUT = 2

class Logplex(object):
    """A Logplex client."""

    def __init__(self, token=None, url=None, timeout=2):
        super(Logplex, self).__init__()

        self.url = url or DEFAULT_LOGPLEX_URL
        self.token = token or DEFAULT_LOGPLEX_TOKEN
        self.timeout = timeout
        self.hostname = 'myhost'
        self.procid = 'python-logplex'
        self.msgid = '-'
        self.structured_data = '-'
        self.timeout = DETAULT_LOGPLEX_TIMEOUT
        self.session = requests.session()

    def format_data(self, data):

        pkt = "<190>1 "
        pkt += datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%S+00:00 ")
        pkt += '{} '.format(self.hostname)
        pkt += '{} '.format(self.token)
        pkt += '{} '.format(self.procid)
        pkt += '{} '.format(self.msgid)
        pkt += '{} '.format(self.structured_data)
        pkt += data
        return '{} {}'.format(len(pkt), pkt)


    def puts(self, s):
        self.send_data(s)

    def send_data(self, s):

        auth = ('token', self.token)
        headers = {'Content-Type': 'application/logplex-1'}
        data = self.format_data(s)

        self.session.post(self.url,
            auth=auth,
            headers=headers,
            data=data,
            timeout=self.timeout
        )
