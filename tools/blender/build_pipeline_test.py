"""Tiny orientation/colour/socket fixture."""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import build_early_art as art

art.clear()
root = art.empty("PIPELINE_TEST")
mat = art.material("test_red", (.8, .1, .05))
art.shape("BOX", (0, 0, .25), (.5, .5, .5), mat, root)
art.shape("CAPSULE", (0, 0, .7), (.25, .25, .5), mat, root, "orb")
art.empty("SOCKET_TEST", (0, -.3, .5), root)
art.export("pipeline_test")
