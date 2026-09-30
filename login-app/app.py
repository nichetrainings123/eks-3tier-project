from flask import Flask, render_template, request
import psycopg2
import os

app = Flask(__name__)

def get_connection():
    return psycopg2.connect(
        host=os.getenv("DB_HOST", "postgres"),
        database=os.getenv("DB_NAME", "trainingdb"),
        user=os.getenv("DB_USER", "admin"),
        password=os.getenv("DB_PASSWORD", "Password@123")
    )

conn = get_connection()
cur = conn.cursor()

cur.execute("""
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(100) UNIQUE,
    password VARCHAR(100)
);
""")
conn.commit()


@app.route("/")
def home():
    return render_template("index.html")


@app.route("/register", methods=["POST"])
def register():
    username1 = request.form["username"]
    password = request.form["password"]

    try:
        cur.execute(
            "INSERT INTO users(username,password) VALUES(%s,%s)",
            (username, password)
        )
        conn.commit()
        return "Registration Successful!"
    except Exception:
        conn.rollback()
        return "User already exists."


@app.route("/login", methods=["POST"])
def login():
    username = request.form["username"]
    password = request.form["password"]

    cur.execute(
        "SELECT * FROM users WHERE username=%s AND password=%s",
        (username, password)
    )

    user = cur.fetchone()

    if user:
        return f"Welcome {username}"

    return "Invalid Username or Password."


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
