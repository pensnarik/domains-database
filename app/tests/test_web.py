#!/usr/bin/env python3

import pytest

from datatrace.spyder import web, parser
from datatrace.spyder.parser import is_valid_domain, normalize_phone, normalize_url

class TestWebMethods:

    def test_get_page(self):
        page = web.get_page('http://kernel.org')
        assert page['charset'] == 'utf-8'
        assert parser.get_title(page['data'], 'utf-8') == 'The Linux Kernel Archives'

    def test_non_existent_page(self):
        page = web.get_page('http://example.com2')
        assert page['status'] == 'connection_error'

    def test_is_valid_domain(self):
        assert is_valid_domain('google.com') == True
        assert is_valid_domain('xn--sauzatimmobilier-eqb.com') == False
        assert is_valid_domain('google.test') == False

    def test_normalize_phone(self):
        assert normalize_phone('84957771122') == '74957771122'
        assert normalize_phone('8 (495) 777-11-22') == '74957771122'

    def test_normalize_url(self):
        assert normalize_url('/test', 'domain.com') == 'http://domain.com/test'
        assert normalize_url('http://domain.com/test', 'domain.com') == 'http://domain.com/test'
