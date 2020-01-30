# -*- coding: utf-8 -*-
"""Datatrace module implements methods for parsing web pages
and extract valuable data from them.

Todo: leave only 1 option in get_config_filename() function
"""
import os

__version__ = '0.6.13'
__version_info__ = 'Datatrace Crawler, version %s' % __version__

def get_config_filename():
    """Returns config filename"""
    if os.path.exists('/usr/local/etc/datatrace.config'):
        return '/usr/local/etc/datatrace.config'
    elif os.path.exists('/etc/datatrace.config'):
        return '/etc/datatrace.config'

    return os.path.join(os.path.dirname(os.path.realpath(__file__)), 'datatrace.config')
