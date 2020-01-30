import configparser
import psycopg2
import psycopg2.extras
import psycopg2.extensions

from flask import Flask
from flask import g

app = Flask(__name__)
#config = configparser.ConfigParser()
#config.read('/usr/local/etc/datatrace_web.config')

from datatrace_web import index

@app.before_request
def get_db():
    if not hasattr(g, 'conn'):
        g.conn = psycopg2.connect('postgresql://migrator:adm290@pg.technozip.ru/datatrace')
        g.conn.set_isolation_level(psycopg2.extensions.ISOLATION_LEVEL_AUTOCOMMIT)
        cursor = g.conn.cursor()
        cursor.execute("SET TIMEZONE TO 'CET'")
        cursor.close()

@app.teardown_appcontext
def teardown(exception):
    if hasattr(g, 'conn'):
        g.conn.close()
