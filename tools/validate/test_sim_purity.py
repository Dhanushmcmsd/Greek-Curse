"""Sample files for the sim purity checker. They are not Godot project scripts."""

import unittest

from tools.validate.check_sim_purity import check_sim, scan_text


CLEAN = """extends RefCounted
class_name Example
const N: int = 1
var point: Vector2i = Vector2i(1, 2)
"""

FORBIDDEN_SAMPLES = {
    "randf": "var n = randf()\n",
    "randi": "var n = randi()\n",
    "randomize": "randomize()\n",
    "Time.": "var t = Time.get_ticks_msec()\n",
    "OS.": "var n = OS.get_processor_count()\n",
    "Engine.": "var f = Engine.get_frames_per_second()\n",
    "get_node": "get_node(\"A\")\n",
    "get_tree": "get_tree()\n",
    "PhysicsServer": "PhysicsServer.body_get_direct_state()\n",
    "RigidBody": "extends RigidBody3D\n",
    "CharacterBody": "extends CharacterBody2D\n",
    "Area3D": "extends Area3D\n",
    "HTTPRequest": "var h = HTTPRequest.new()\n",
    "ENet": "ENetMultiplayerPeer.new()\n",
    "WebSocket": "WebSocketPeer.new()\n",
    "float literal": "const X = 1.5\n",
    "float type": "var speed: float = 1\n",
    "Vector2(": "var v = Vector2(1, 2)\n",
    "Vector3(": "var v = Vector3(0, 1, 0)\n",
    "Node inheritance": "extends Node\n",
}


class SimPurityTests(unittest.TestCase):
    def test_clean_sample_passes(self) -> None:
        self.assertEqual(scan_text("clean.gd", CLEAN), [])

    def test_each_forbidden_token_fails(self) -> None:
        for label, text in FORBIDDEN_SAMPLES.items():
            errors = scan_text("bad.gd", text)
            self.assertTrue(errors, label)
            self.assertTrue(any(label in error or "forbidden" in error for error in errors), errors)

    def test_allow_comment_skips_the_line(self) -> None:
        text = "var n = randf() # sim-purity-ok: presentation preview only\n"
        self.assertEqual(scan_text("allowed.gd", text), [])

    def test_project_sim_passes(self) -> None:
        self.assertEqual(check_sim(), [])


if __name__ == "__main__":
    unittest.main()
