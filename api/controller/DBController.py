#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
DB sql controller
@author Oslandia, Sylvain Beorchia / http://www.oslandia.com/
"""

import json
import string
import smtplib
import datetime
import unicodedata
from time import gmtime, strftime
from random import choice, randint
from pathlib import Path
from flask import jsonify

import psycopg2

import settings

class DBController:
    def __init__(self):
        self.connectDB()
        self.outputProj = settings.OUTPUT_PROJ
        self.emptyCollection = '{"type":"FeatureCollection","features":[]}'

    def connectDB(self):
        """
        Connect to DB
        """
        self.conn = psycopg2.connect(**settings.DB_INFOS)
        self.conn.set_session(autocommit=True)
        self.cursor = self.conn.cursor()

    def disconnectDB(self):
        """
        Disconnect from DB
        """
        self.cur.close()
        self.conn.close()

    def test(self, start_with):
        """
        :returns: json data
        """

        sql = """
                select nom_com, st_asgeojson(geom) as geom
                from 
                admin.communes
                where nom_com ilike '%%s'
                limit 2
                """

        sql_params = [start_with]
        self.cursor.execute(sql, sql_params)
        self.traceSql("test", self.cursor)

        data = self.processData()

        return data


    def test_json(self):
        """
        :returns: json data
        """

        sql = """
                select nom_com
                from 
                admin.communes
                limit 2
                """

        sql_params = []
        self.cursor.execute(sql)
        self.traceSql("test", self.cursor)

        data = jsonify(self.cursor.fetchall())

        return data

    def run_query(self, sql, params):
        """
        :returns: cursor
        """

        self.cursor.execute(sql, params)

        return self.cursor


    def processData(self, header=True):
        """
        Generate a GEOJSON or CSV
        """
        output = self.process_data_geojson(self.cursor)
        if header:
            totalOutput = '{"type":"FeatureCollection","features":[' + output + ']}'
            return totalOutput
        else:
            return output

    def process_data_geojson(self, cursor):
        """
        Get data from DB (cursor has already been initiated)
        Process Geom data

        :params cursor cursor: cursor on the DB
        :returns: json data
        """

        # retrieve the records from the database
        records = cursor.fetchall()

        # Get the column names returned
        colnames = [desc[0] for desc in cursor.description]

        # Find the index of the column that holds the geometry
        geomIndex = colnames.index("geom")

        output = ""
        rowOutput = ""
        i = 0
        feature_added = False
        # For each row returned
        while i < len(records):
            # Make sure the geometry exists
            if records[i][geomIndex] is not None:
                # If it's the first record, don't add a comma
                comma = "," if feature_added else ""
                rowOutput = comma + '{"type":"Feature","geometry":' + records[i][geomIndex] + ',"properties":{'
                properties = ""

                j = 0
                # For each field returned, assemble the properties object
                while j < len(colnames):
                    if colnames[j] != 'geom':
                        comma = "," if j > 0 else ""
                        value = records[i][j] if records[i][j] is not None else ''
                        if isinstance(value, dict):
                            value = json.dumps(value)
                        else:
                            value = '"' + str(value).replace("\"", "'") + '"'
                        properties += comma + '"' + colnames[j] + '":' + value
                    j += 1

                rowOutput += properties
                rowOutput += '}}\n'

                output += rowOutput
                
                feature_added = True

            # start over
            rowOutput = ""
            i += 1

        return output


    def traceSql(self, url, cursor):
        if hasattr(settings, 'TRACE_SQL'):
            if settings.TRACE_SQL:
                print('-----------------------')
                print('## {}'.format(url))
                query_string = cursor.query.decode()
                query_string = "\n".join(line.strip() for line in query_string.split("\n"))
                print(query_string)

