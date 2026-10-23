import re


def validate(name):
    if not re.fullmatch(r"[A-Za-z][A-Za-z0-9_.]*", name):
        raise ValueError("Invalid generated node name: " + name)
    return name
