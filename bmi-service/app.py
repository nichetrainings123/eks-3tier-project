import math
import os

from flask import Flask, redirect, render_template, request, session

app = Flask(__name__)
app.config["SECRET_KEY"] = os.getenv("FLASK_SECRET_KEY")


@app.get("/healthz")
def health():
    return "ok"


@app.route("/bmi", methods=["GET", "POST"])
def calculate_bmi():
    username = session.get("username")
    if not username:
        return redirect("/")

    bmi = None
    category = None
    error = None
    if request.method == "POST":
        try:
            weight_kg = float(request.form["weight_kg"])
            height_cm = float(request.form["height_cm"])
            if not math.isfinite(weight_kg) or not math.isfinite(height_cm):
                raise ValueError
            if weight_kg <= 0 or height_cm <= 0:
                raise ValueError

            height_m = height_cm / 100
            if height_m <= 0:
                raise ValueError
            bmi = weight_kg / (height_m ** 2)
            if not math.isfinite(bmi):
                raise ValueError
            if bmi < 18.5:
                category = "Underweight"
            elif bmi < 25:
                category = "Normal weight"
            elif bmi < 30:
                category = "Overweight"
            else:
                category = "Obesity"
        except (KeyError, ValueError, OverflowError, ZeroDivisionError):
            error = "Enter a valid positive weight in kilograms and height in centimeters."

    return render_template(
        "bmi.html",
        username=username,
        bmi=bmi,
        category=category,
        error=error,
    )


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5001)
