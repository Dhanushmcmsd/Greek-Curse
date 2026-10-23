import copy
import json
import unittest
from pathlib import Path
from tools.anim.pose_validate import validate, check

class PoseTests(unittest.TestCase):
 def test_actual_data(self): self.assertEqual(check(), [])
 def test_bad_bone_angle_and_reference_rejected(self):
  data=json.loads(Path('data/animation/poses.json').read_text())
  bad=copy.deepcopy(data);bad['poses']['idle']['bones']['unknown']=[0,0,0]
  self.assertTrue(validate(bad,[]))
  bad=copy.deepcopy(data);bad['poses']['idle']['bones']['spine']=[float('nan'),0,0]
  self.assertTrue(validate(bad,[]))
  self.assertTrue(validate(data,[{'id':'bad','anim_set':'missing'}]))
