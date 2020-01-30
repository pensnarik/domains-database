import psycopg2.extras

from flask import g

def get_rows(query, args=None):
    cursor = g.conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)
    cursor.execute(query, args)
    res = [r for r in cursor.fetchall()]
    cursor.close()
    return res

def get_row(query):
    cursor = g.conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)
    cursor.execute(query)
    res = cursor.fetchone()
    cursor.close()
    return res

def get_value(query):
    cursor = g.conn.cursor()
    cursor.execute(query)
    res = cursor.fetchone()
    cursor.close()
    return res[0]

def execute(query, *args):
    cursor = g.conn.cursor()
    cursor.execute(query, args)
    cursor.close()
    g.conn.commit()
    return
