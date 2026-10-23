import sys
import argparse


def parse():
    parser = argparse.ArgumentParser()
    parser.add_argument("--id", default="theron")
    return parser.parse_args(sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else [])
