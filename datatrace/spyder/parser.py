# -*- coding: utf-8 -*-

"""
Module contains procedures for sites content processing
"""

import re
import logging
from html import unescape as unhtml

from lxml.html import fromstring

from datatrace.spyder import popular_domains, domain_expr, expr_phones

logger = logging.getLogger('datatrace')


def quote_regexp(expression):
    return expression.replace('.', r'\.')


def normalize_phone(phone):
    return re.sub('^8', '7', ''.join(i if i in '0123456789' else '' for i in phone))


def is_valid_domain(url):
    # We need to refer the list of pupular 1-2 level domains in order to minimize
    # the possibility of spending too much time for analyzing non existing domains
    try:
        return any(url.endswith('.%s' % i) for i in popular_domains[len(url.split('.')) - 1]) and \
               '--' not in url
    except KeyError:
        return False


def get_title(buffer, charset):
    """
    Returns page title from <title> tag, we should consider that
    <title> might have attributes, for example: <title itemprop="name">
    """
    expr = r'''<title[^>]{0,100}>\s{0,100}(.{1,500}?)\s{0,100}</title>'''
    m = re.search(expr, buffer, re.MULTILINE | re.DOTALL | re.IGNORECASE)
    title = u''
    if m:
        if 'utf' in charset:
            title = m.group(1)
        else:
            # FIXME: Why not convert in a simple way?
            try:
                title = m.group(1).decode('cp1251').encode('utf8')
            except:
                title = m.group(1)
        return unhtml(title).strip()
    else:
        return None


def get_phones(buffer, max_phones=10):
    """
    Extracts all phone numbers found on the page, returns only first max_phones entries
    """
    phones = list(); i = 0
    for m in re.finditer(expr_phones, buffer):
        phones.append(normalize_phone(m.group(0)))
        i = i + 1
        if i == max_phones: break
    return list(set(phones))


def get_emails(buffer, max_emails=10):
    """
    Extract e-mails from the site
    """
    expr_emails = r'[a-z0-9]([a-z0-9.-]){1,40}@([a-z0-9-]+){1,3}\.[a-z]{2,30}'
    emails = list()
    i = 0
    for m in re.finditer(expr_emails, buffer):
        if is_valid_domain(m.group(0)):
            emails.append(m.group(0))
        i = i + 1
        if i == max_emails: break
    return list(set(emails))


def get_domains(buffer, parent_domain, max_domains=1000):
    """
    Extracts domains from the site contents
    """
    expr_domains = 'https?://%s' % domain_expr
    domains = list()
    i = 0
    for m in re.finditer(expr_domains, buffer):
        if is_valid_domain(m.group(1)) and \
           m.group(1) not in domains and \
           m.group(1) != parent_domain:

            domains.append(m.group(1))
            i += 1
        if i == max_domains: break
    return domains


def get_charset(buffer):
    """
    Determines website encoding based on what can be found in <meta charset>
    tag. It treats buffer as bytes array because we don't know the encoding
    yet ant cannot convert it to string therefore
    """
    def try_charset_from_meta(meta):
        expr = r'''<meta.{1,1000}?charset\s*=\s*['\"]?([0-9a-z\\-]{1,20})['\"]?'''
        m = re.search(expr, meta, re.IGNORECASE)
        if m:
            return m.group(1).lower()
        else:
            return None

    buffer_len = buffer.tell()

    for i in range(buffer_len):
        buffer.seek(i)
        five_bytes = buffer.read(5)
        if five_bytes == b'<meta':
            for j in range(1, 100):
                bracket = buffer.read(1)
                if bracket == b'>':
                    buffer.seek(i)
                    line = buffer.read(j + len('<meta'))
                    try:
                        encoded_line = line.decode('utf-8')
                    except UnicodeDecodeError:
                        i += (j + len('<meta'))
                        continue
                    encoding = try_charset_from_meta(encoded_line)
                    logger.debug(encoded_line)
                    if encoding is not None:
                        logger.info('Charset detected from buffer using <meta> tag')
                        return encoding
                    i += (j + len('<meta'))
                    continue
    return None

def get_charset_from_headers(headers):
    """
    Extracts site encoding from HTTP headers
    """
    if 'content-type' in headers:
        m = re.search(r'charset\s?=\s?([a-z0-9\-]+)', headers['content-type'], re.IGNORECASE)
        if m:
            charset = m.group(1).lower()
            logger.info('Charset detected from headres as %s', charset)
            return charset
    return None


def get_links_from_page(buffer):
    """
    Extracts all unique links from the site content
    """
    expr = r'http[s]?://%s(/([a-zA-Z0-9.-]{1,}))+(\.html|\.php|\.asp|\.php3|\/)' % domain_expr
    links = list()
    domains = list()
    for m in re.finditer(expr, buffer, re.MULTILINE):
        if m.group(2):
            # FIXME: Add more comments here
            # Add a new link only in case when expression doesn't match domain
            links.append(m.group(0))
        domains.append(m.group(1))
    return (list(set(links)), list(set(domains)),)


def normalize_url(url, domain):
    """
    Adds protocol specification to the beginning of the given
    URL if necessary
    """
    if url.startswith('http://') or url.startswith('https://'):
        return url
    if url.startswith('/'):
        return 'http://%s%s' % (domain, url)
    return 'http://%s/%s' % (domain, url)


def get_contact_pages(buffer, domain):
    """
    Returns links to all possible contact pages found on the site index page
    """
    usual_contact_titles = [u'Contact', u'Contacts', u'About', u'Контакты', u'Связаться с нами']
    usual_contact_urls = ['/contact', '/contacts', '/info']
    result = list()

    html = fromstring(buffer)

    for a in html.xpath('//a'):
        title = a.text_content().strip()
        url = a.get('href')
        if url is None:
            continue
        if title in usual_contact_titles or url in usual_contact_urls:
            result.append(normalize_url(url, domain))

    del html

    return list(set(result))
