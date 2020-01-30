import json
import datetime as dt

from flask import render_template, g, request

from datatrace_web import app, sql

import calendar, json, pytz

def get_hosts():
    query = '''
    select distinct hostname
      from session
     where end_time is null
       and instance is not null
     order by 1
    '''
    return [i['hostname'] for i in sql.get_rows(query)]

@app.route('/', methods=['GET'])
def index():
    tz = pytz.timezone('CET')
    default_intervals = {
        'h': [dt.date.today().strftime('%Y-%m-%d 00:00'),
              (dt.date.today() + dt.timedelta(days=1)).strftime('%Y-%m-%d 00:00')],
        'm': [(dt.datetime.now().astimezone(tz) - dt.timedelta(hours=1)).strftime('%Y-%m-%d %H:%M'),
               dt.datetime.now().astimezone(tz).strftime('%Y-%m-%d %H:%M')]
    }
    host = request.args.get('host')
    interval = request.args.get('interval', 'm')

    date_from = request.args.get('date_from')
    date_till = request.args.get('date_till')

    if date_from is None or date_till is None:
        date_from, date_till = default_intervals[interval]

    if host == '':
        host = None

    stat = sql.get_rows("select * from report.stat(%s, %s, %s, %s)", (date_from, date_till, host, interval,))
    hosts_stat = sql.get_rows("select * from report.hosts_stat(%s, %s, %s)", (date_from, date_till, interval, ))
    status_stat = sql.get_rows("select * from report.status_log(%s, %s, %s, %s)", (date_from, date_till, host, interval, ))

    hosts_data = dict()
    hosts_data_avg = dict()
    status_data = {'ok': list(), 'timeout': list(), 'connection_error': list(),
                   'too_many_redirects': list(), 'unknown_error': list(),
                   'too_large': list(), 'resolve_error': list()}

    for row in hosts_stat:
        if row['host'] in hosts_data.keys():
            hosts_data[row['host']].append({'Timestamp': row['date_time'].strftime('%Y-%m-%dT%H:%M%Z'), 'Value': row['parsed_sites']})
            hosts_data_avg[row['host']].append({'Timestamp': row['date_time'].strftime('%Y-%m-%d %H:%M%Z'), 'Value': str(row['avg_total'])})
        else:
            hosts_data[row['host']] = [{'Timestamp': row['date_time'].strftime('%Y-%m-%d %H:%M%Z'), 'Value': row['parsed_sites']}]
            hosts_data_avg[row['host']] = [{'Timestamp': row['date_time'].strftime('%Y-%m-%d %H:%M%Z'), 'Value': str(row['avg_total'])}]

    for row in status_stat:
        for status in status_data.keys():
            status_data[status].append({'Timestamp': row['date_time'].strftime('%Y-%m-%d %H:%M%Z'), 'Value': row['num_%s' % status]})

    return render_template('index.html', stat=stat, host=host, interval=interval, hosts=get_hosts(),
                           date_from=date_from, date_till=date_till, hosts_data=json.dumps(hosts_data),
                           hosts_data_avg=hosts_data_avg, status_data=json.dumps(status_data))

@app.route('/search', methods=['GET'])
def search():
    domain = request.args.get('domain')
    ip = request.args.get('ip')
    phone = request.args.get('phone')
    last_domain = request.args.get('last_domain')

    if domain == '':
        domain = None
    if ip == '':
        ip = None
    if last_domain == '':
        last_domain = None
    if phone == '':
        phone = None

    query = '''
    select * from public.search(%s, %s, %s, %s)
    '''

    result = sql.get_rows(query, (domain, ip, phone, last_domain,))
    last_domain = result[-1]['domain'] if len(result) > 0 else None

    return render_template('search.html', result=result, domain=domain, ip=ip, phone=phone,
                           last_domain=last_domain)
