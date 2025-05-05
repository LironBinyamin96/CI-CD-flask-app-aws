from flask import Flask, request, jsonify, send_from_directory
from flask_cors import CORS 
import pymysql
import boto3
import json
import get_parameters
import os

app = Flask(__name__, static_folder='../frontend')

def get_parameter(name):
    ssm = boto3.client("ssm", region_name="il-central-1")
    param = ssm.get_parameter(Name=name, WithDecryption=True)
    return param['Parameter']['Value']

db_host = get_parameter("/liron/database/endpoint")
db_user = get_parameters.get_secret()["username"]
db_pass = get_parameters.get_secret()["password"]
db_name = "liron_db"

def get_db_connection():
    return pymysql.connect(
        host=db_host,
        user=db_user,
        password=db_pass,
        database=db_name,
        cursorclass=pymysql.cursors.DictCursor
    )

app = Flask(__name__, static_folder='../frontend')
CORS(app) 

@app.route("/add-name", methods=["POST"])
def add_name():
    data = request.get_json()
    name = data.get("name")
    if not name:
        return jsonify({"error": "Name is required"}), 400

    try:
        conn = get_db_connection()
        with conn:
            with conn.cursor() as cursor:
                cursor.execute("INSERT INTO users (name) VALUES (%s)", (name,))
                conn.commit()
        return jsonify({"message": f"Added '{name}' to the database!"})
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/')
def serve_index():
    return send_from_directory('../frontend', 'index.html')

@app.route('/<path:path>')
def serve_static(path):
    return send_from_directory('../frontend', path)

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=3000)