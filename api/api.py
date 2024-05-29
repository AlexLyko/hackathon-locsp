"""
Main server processes for retreiving data from DB
@author Oslandia, Sylvain Beorchia / http://www.oslandia.com/
"""

import os
from datetime import date, time, datetime

from flask import Flask, Response, jsonify, request, render_template
from flask.json import JSONEncoder
from werkzeug.utils import secure_filename
from werkzeug.security import safe_str_cmp
#from flask_jwt_extended import (JWTManager, jwt_required, get_jwt_identity, create_access_token, create_refresh_token,
#                                jwt_refresh_token_required)

from controller.DBController import DBController

from controller.repository_oso import RepoOso

app = Flask(__name__)
app.debug = True

#app.config['SECRET_KEY'] = settings.secret_key
#app.json_encoder = CustomJSONEncoder

def initDBC():
    """
    Initialize DBC + fill params
    """
    dbc = DBController()
    return dbc


@app.route('/test', methods=['GET', 'POST'])
def test():
    
    if request.method == 'POST':
        d = request.form
    if request.method == 'GET':
        d = request.args

    start_with = d['start_with']
    dbc = initDBC()
    output = dbc.test(start_with)
    return Response(response=output, status=200, mimetype='application/json')


@app.route('/test2', methods=['GET', 'POST'])
def test2():
    
    if request.method == 'POST':
        d = request.form
    if request.method == 'GET':
        d = request.args

    dbc = initDBC()
    
    name = d['nom']
    return render_template('test2.html', name=name)


@app.route('/test3', methods=['GET', 'POST'])
def test3():
    
    if request.method == 'POST':
        d = request.form
    if request.method == 'GET':
        d = request.args

    dbc = initDBC()
    
    return dbc.test_json()


@app.route('/testoso', methods=['GET', 'POST'])
def testoso():
    
    if request.method == 'POST':
        d = request.form
    if request.method == 'GET':
        d = request.args
    if not 'x' in d:
        return jsonify({"error": "x is mandatory"})
    if not 'y' in d:
        return jsonify({"error": "y is mandatory"})

    data = RepoOso().get_oso_intersects(d['x'], d['y'], d.get('distance', 10))
    
    return app.response_class(
        response=data,
        status=200,
        mimetype='application/json'
    )


@app.route('/test4/<x>/<y>')
def test4(x, y):
    res = {}
    res['x'] = x
    res['y'] = y
    
    data = jsonify(res)
    return data


if __name__ == '__main__':
    app.debug = True
    app.run()
