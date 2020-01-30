# -*- coding: utf-8 -*-

import re

from urllib.parse import urlparse, urlunparse, ParseResult
from lxml.html import fromstring

from datatrace.spyder import web

class Job():
    """
    Interface class
    """
    def __init__(self, logger, db):
        self.logger = logger
        self.s = db

    def run(self, task):
        raise NotImplementedError

class JobCheckSQLInjection(Job):

    def get_vulnerable_links(self, domain, buffer):
        html = fromstring(buffer)
        links = list()

        for a in html.xpath('//a'):
            url = a.get('href')
            if url is None or url == '':
                continue

            # Check if the link contains URL arguments
            m = re.search('\?([A-Za-z0-9]+=[A-Za-z0-9\/]+&?)+', url)
            if m is None:
                continue

            # We need to add domain to to the URL if it's a local one
            if not url.startswith('http://') and not ('://') in url:
                if url.startswith('/'):
                    links.append('%s%s' % (domain, url))
                else:
                    links.append('%s/%s' % (domain, url))
            # If it's a local one, it should refer to the domain which is
            # currently analyzed
            elif url.startswith(domain) or \
                 url.startswith(domain.replace('http://', 'http://www.')) or \
                 url.startswith(domain.replace('https://', 'https://www.')) or \
                 url.startswith(domain.replace('http://', 'https://')):
                links.append(url)

        return list(set(links))

    def spoil_query(self, query):
        """
        Puts quote into URL
        """
        params = query.split('&')
        if not params or len(params) == 0:
            raise ValueError('Could not parse url %s' % query)
        params[0] = "%s'" % params[0]
        return '&'.join(params)

    def is_vulnerable(self, buffer):
        expr = 'You have an error in your SQL syntax'
        if re.search(expr, buffer):
            return True
        return False

    def run(self, task, dry_run=False):
        self.site_id = task['site_id']
        self.url = 'http://%s' % task['domain']

        self.logger.info('Getting %s', self.url)

        result = web.get_page(self.url)
        if result['status'] == 'ok':
            links = self.get_vulnerable_links(self.url, result['data'])

            for link in links:
                parsed_link = urlparse(link)
                spoiled_link = ParseResult(scheme=parsed_link.scheme, netloc=parsed_link.netloc,
                                           path=parsed_link.path, params=parsed_link.params,
                                           query=self.spoil_query(parsed_link.query),
                                           fragment=parsed_link.fragment)
                self.logger.info('Spoiled link: %s' % urlunparse(spoiled_link))

                spoiled_data = web.get_page(urlunparse(spoiled_link))

                if spoiled_data['status'] == 'ok':
                    self.logger.info('Spoiled page fetched OK, checking contents...')
                    if self.is_vulnerable(spoiled_data['data']):
                        self.logger.info('VULNERABLE!')
                        if dry_run is False:
                            self.s.execute('insert into log.vulns(site_id, url)' \
                                           'values (%s, %s)',
                                           self.site_id,
                                           urlunparse(spoiled_link))
                    else:
                        self.logger.info('Not vulnerable ;(')
                else:
                    self.logger.info('Could not get page using spoiled URL: %s', spoiled_data['status'])
                # In the current implementation we check only the first URL
                break
        stat = {'sites_processed': 1}
        return {'status': 'done', 'fetch_result': result['status'], 'error': None, 'stat': stat}
