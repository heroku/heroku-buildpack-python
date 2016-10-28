from flask import Flask, request
import subprocess

app = Flask(__name__)

@app.route("/")
def hello():
    return "I was started without a Procfile"

@app.route('/execute', methods=['POST'])
def execute():
    with open('runtime.py', 'w') as f:
        f.write(request.values.get('code'))
    return subprocess.check_output(["python", "runtime.py"])

app.debug=True
