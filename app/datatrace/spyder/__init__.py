# -*- coding: utf-8 -*-
"""Contstants and definitions"""

popular_domains = {1: ['ru', 'com', 'net', 'org', 'su', 'eu', 'de', 'ua', 'info', 'by',
                       'pro', 'co', 'cz', 'biz', 'it', 'pl', 'lv', 'kz', 'nl', 'me', 'ch',
                       'fi', 'gov', 'lt', 'fr', 'se', 'edu', 'es', 'in', 'no', 'at',
                       'ee', 'tv', 'hu', 'here', 'sk', 'cc', 'bg', 'be', 'dk', 'au', 'nz',
                       'yandex', 'chat'],
                   2: [# Australia
                       'asn.au', 'com.au', 'net.au', 'id.au', 'org.au', 'edu.au', 'gov.au',
                       'csiro.au', 'act.au', 'nsw.au', 'nt.au', 'qld.au', 'sa.au', 'tas.au',
                       'vic.au', 'wa.au',
                       # Austria
                       'co.at', 'or.at',
                       # France
                       'avocat.fr', 'aeroport.fr', 'veterinaire.fr',
                       # Hungary
                       'co.hu', 'film.hu', 'lakas.hu', 'ingatlan.hu', 'sport.hu', 'hotel.hu',
                       # New Zealand
                       'ac.nz', 'co.nz', 'geek.nz', 'gen.nz', 'kiwi.nz', 'maori.nz', 'net.nz',
                       'org.nz', 'school.nz', 'cri.nz', 'govt.nz', 'health.nz', 'iwi.nz', 'mil.nz',
                       'parliament.nz',
                       # Israel
                       'ac.il', 'co.il', 'org.il', 'net.il', 'k12.il', 'gov.il', 'muni.il',
                       'idf.il',
                       # Russia
                       'spb.ru', 'msk.ru', 'org.ru',
                       # South Africa
                       'ac.za', 'gov.za', 'law.za', 'mil.za', 'nom.za', 'school.za', 'net.za',
                       # United Kingdom
                       'co.uk', 'org.uk', 'me.uk', 'ltd.uk', 'plc.uk', 'net.uk', 'sch.uk', 'ac.uk',
                       'gov.uk', 'mod.uk', 'nhs.uk', 'police.uk']}

popular_hosts = ['w3.org', 'liveinternet.ru', 'gmpg.org', 'vk.com', 'facebook.com', 'google.com',
                 'youtube.com', 'twitter.com', 'ogp.me', 'schema.org', 'macromedia.com',
                 'joomla.org', 'yandex.ru', '1c-bitrix.ru', 'vkontakte.ru', 'wordpress.org',
                 'marketgid.com', 'wildberries.ru', 'fotostrana.ru', 'jelastic.com',
                 'gomobi.info', 'yourmine.ru', 'watchesforyou.ru', 'userapi.com',
                 'odnoklassniki.ru', 'instagram.com', 'sedo.com', 'opera.com', 'mozilla.com',
                 'microsoft.com', 'mozilla.org']

headers = {'User-agent': 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) ' \
           'Chrome/34.0.1847.132 Safari/537.36', 'Connection': 'close'}

domain_expr = r'(?:www\.)?([a-z0-9-]{2,65}(?:\.[a-z]{2,10})?\.[a-z]{2,})'

__all__ = ['popular_domains', 'headers']

# Moscow region cell operator codes
# http://www.mobile-networks.ru/articles/kody_sotovyh_operatorov_rossii/moskva.html#sel=

phone_prefixes = ['495', '499', '800', '812',
                  '901', '903', '905', '906', '909', '910', '915', '916', '917', '919', '925',
                  '926', '929', '936', '958', '962', '963', '964', '965', '967', '977', '985',
                  '999']

expr_phones = r'(7|8)[\s\-]?((%s)|%s)[\s\-]?(' \
              r'[0-9]{3}[\s\-]?[0-9]{2}[\s\-]?[0-9]{2}|' \
              r'[0-9]{3}[\s\-]?[0-9]{1}[\s\-]?[0-9]{3}|' \
              r'[0-9]{2}[\s\-]?[0-9]{3}[\s\-]?[0-9]{2})' % \
              ('|'.join(phone_prefixes), '|'.join([r'\(%s\)' % i for i in phone_prefixes]))
