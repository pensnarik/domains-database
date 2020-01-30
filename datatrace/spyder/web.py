# -*- coding: utf-8 -*-

import logging
import requests
import socket
import io

import timeout_decorator

from datatrace.spyder.exceptions import SpyderError
from datatrace.spyder import headers, parser

logger = logging.getLogger('datatrace')

@timeout_decorator.timeout(60, use_signals=True)
def get_page(url):
    """
    Downloads the websites root page using requests library, returns dict():
    {'status': <operation result>, 'data': <data>}
    In case of failure status is one of the follows:

    timeout, connection_error, too_many_redirects, too_large, unknown_error

    These values map to site_fetch_result enum type in the database
    """
    error = None
    data = None
    charset = None
    max_page_size = 10 * 1024 * 1024

    try:
        s = requests.Session()

        # max_redirects = 10 the only way I know to avoid infinite redirects
        # except manual handling (Session.resolve_redirects()),

        s.max_redirects = 10
        s.keep_alive = False

        r = s.get('http://%s' % url if not url.startswith('http://') else url,
                  headers=headers, timeout=10.0, stream=True)
        # Download data by 4kb chunks
        raw_data = io.BytesIO()
        size = 0
        for chunk in r.iter_content(4096):
            size += len(chunk)
            raw_data.write(chunk)
            if size > max_page_size:
                r.close()
                raise SpyderError('too_large')

        # r.encoding often wrong so we try to determine encoding as follows:
        #
        # 1) Analyze HTTP headers
        # 2) Analyze <meta charset> HTML tag
        # 3) Ask requests

        charset = parser.get_charset_from_headers(r.headers) or \
                  parser.get_charset(raw_data) or \
                  r.encoding

        logger.info('Detected charset as %s' % charset)
        # parser.get_charset can move the file pointer
        raw_data.seek(0)
        try:
            data = raw_data.getvalue().decode(charset or 'utf-8')
        except UnicodeDecodeError as e:
            try:
                data = raw_data.getvalue().decode('cp1251')
            except UnicodeDecodeError as e:
                data = raw_data.getvalue().decode('utf-8', 'replace')
        fetch_result = 'ok'
    except SpyderError as err:
        fetch_result = err.value
    except (requests.Timeout, socket.timeout):
        fetch_result = 'timeout'
    except requests.exceptions.ConnectionError:
        fetch_result = 'connection_error'
    except requests.exceptions.TooManyRedirects:
        fetch_result = 'too_many_redirects'
    except Exception as e:
        fetch_result = 'unknown_error'
        error = str(e)
        raise
    finally:
        del s

    return {'status': fetch_result,
            'data': data if fetch_result == 'ok' else None,
            'status_code': r.status_code if fetch_result == 'ok' else None,
            'headers': r.headers if fetch_result == 'ok' else None,
            'size': size if fetch_result == 'ok' else None,
            'error': error, 'charset': charset}
