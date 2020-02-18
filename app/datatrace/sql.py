"""Implemets functions to access PostgreSQL database"""

import psycopg2.extras

class Sql():
    """Implements functions to access the database"""
    def __init__(self, conn):
        self.conn = conn

    def get_rows(self, query):
        """Returns multiple rows"""
        cursor = self.conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)
        cursor.execute(query)
        res = [r for r in cursor.fetchall()]
        cursor.close()
        return res

    def get_row(self, query, args):
        """Returns one row"""
        cursor = self.conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)
        cursor.execute(query, args)
        res = cursor.fetchone()
        cursor.close()
        return res

    def get_value(self, query, args):
        """Returns a singe value"""
        cursor = self.conn.cursor()
        cursor.execute(query, args)
        res = cursor.fetchone()
        cursor.close()
        return res[0]

    def execute(self, query, *args):
        """Executes a statement and returns no result"""
        cursor = self.conn.cursor()
        cursor.execute(query, args)
        cursor.close()
        return
