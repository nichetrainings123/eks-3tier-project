import os
from contextlib import contextmanager

import psycopg2
from flask import Flask, redirect, render_template, request, session

app = Flask(__name__)
app.config["SECRET_KEY"] = os.getenv("FLASK_SECRET_KEY")


def get_connection():
    return psycopg2.connect(
        host=os.getenv("DB_HOST", "postgres"),
        database=os.getenv("DB_NAME", "trainingdb"),
        user=os.getenv("DB_USER", "admin"),
        password=os.getenv("DB_PASSWORD", "Password@123")
    )

@contextmanager
def database_connection():
    connection = get_connection()
    try:
        with connection:
            yield connection
    finally:
        connection.close()


with database_connection() as connection:
    with connection.cursor() as cursor:
        cursor.execute("""
        CREATE TABLE IF NOT EXISTS users (
            id SERIAL PRIMARY KEY,
            username VARCHAR(100) UNIQUE,
            password VARCHAR(100)
        );
        """)


@app.route("/")
def home():
    return render_template("index.html")


@app.route("/register", methods=["POST"])
def register():
    username = request.form.get("username", "").strip()
    password = request.form.get("password", "")
    if not username or not password:
        return "Username and password are required.", 400

    try:
        with database_connection() as connection:
            with connection.cursor() as cursor:
                cursor.execute(
                    "INSERT INTO users(username,password) VALUES(%s,%s)",
                    (username, password)
                )
        return "Registration Successful!"
    except psycopg2.errors.UniqueViolation:
        return "User already exists.", 409
    except psycopg2.Error:
        app.logger.exception("Database error while registering user")
        return "Registration failed due to a database error. Please try again.", 500


@app.route("/login", methods=["POST"])
def login():
    username = request.form.get("username", "").strip()
    password = request.form.get("password", "")

    try:
        with database_connection() as connection:
            with connection.cursor() as cursor:
                cursor.execute(
                    "SELECT * FROM users WHERE username=%s AND password=%s",
                    (username, password)
                )
                user = cursor.fetchone()
    except psycopg2.Error:
        app.logger.exception("Database error while logging in")
        return "Login failed due to a database error. Please try again.", 500

    if user:
        session["username"] = username
        return redirect("/bmi")

    return "Invalid Username or Password."


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
