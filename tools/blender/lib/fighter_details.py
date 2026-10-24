"""Original sculpted anatomy and armour details; no third-party model assets."""
import math
import bpy
from .primitives import shape
from .materials import material


def decorate(root, h, w, style, skin, cloth, gold, dark):
 ivory=material('ivory',(.84,.83,.72)); steel=material('steel',(.27,.34,.39)); jade=material('gem',(.08,.65,.55))
 # Layered chest, rib cage, abdomen and anatomically distinct face.
 for side in [-1,1]:
  shape('PECTORAL', (side*w*.23,-.11,h*.735),(w*.44,.10,h*.10), skin,root,'body')
  shape('DELTOID',(side*w*.49,0,h*.785),(w*.33,.24,h*.13),skin,root,'body')
  shape('HEAD_CHEEK',(side*.075,-.07,h*.915),(.085,.07,h*.055),skin,root,'body')
  shape('HEAD_BROW',(side*.055,-.12,h*.94),(.09,.045,.025),dark,root,'body')
  shape('HEAD_EAR',(side*.126,0,h*.925),(.035,.07,.08),skin,root,'body')
 for row in range(3):
  for side in [-1,1]:
   shape('ABDOMEN',(side*w*.105,-.13,h*(.68-row*.045)),(w*.20,.09,h*.04),skin,root,'body')
 shape('HEAD_JAW',(0,-.035,h*.885),(.18,.17,h*.07),skin,root,'body')
 shape('HEAD_MOUTH',(0,-.135,h*.895),(.075,.016,.014),dark,root)
 for i in range(9):
  a=(i/8-.5)*math.pi
  panel=shape('SKIRT_PANEL',(math.sin(a)*w*.37,-math.cos(a)*.16,h*.46),(.065,.035,h*.14),cloth if i%2 else dark,root)
  panel.rotation_euler.y=math.sin(a)*.15
  shape('SKIRT_RIVET',(math.sin(a)*w*.37,-math.cos(a)*.18,h*.515),(.022,.022,.022),gold,root,'orb')
 # Details are merged into the rigid limb segment so they move and sever with it.
 for side,sign in [('L',-1),('R',1)]:
  for limb in ['ARM','LEG']:
   arm=limb=='ARM'; x=sign*w*(.53 if arm else .23); z=h*(.79 if arm else .45); length=h*(.31 if arm else .43)
   target=bpy.data.objects.get(limb+'_LOWER_'+side)
   parent=target.parent
   additions=[shape("DETAIL",(0,0,-length*.50),(w*.22,w*.22,w*.22),skin,parent,"body")]
   for band in [.54,.80]:
    additions.append(shape('DETAIL',(0,-.015,-length*band),(w*(.27 if arm else .30),w*.27,.035),gold,parent,'cylinder'))
   additions.append(shape('DETAIL',(0,-w*.11,-length*.68),(w*.22,.045,length*.28),steel if style=='helm' else cloth,parent,'body'))
   bpy.ops.object.select_all(action='DESELECT')
   target.select_set(True)
   for obj in additions: obj.select_set(True)
   bpy.context.view_layer.objects.active=target
   bpy.ops.object.join()
 if style=='helm':
  shape('HELM_FACE',(0,-.12,h*.94),(.25,.07,h*.075),steel,root,'body')
  for side in [-1,1]:
   shape('HELM_CHEEK',(side*.10,-.10,h*.90),(.05,.09,h*.09),gold,root)
  for i in range(10):
   shape('CREST_FEATHER',(0,.13-i*.027,h*.975),(.045,.035,h*.045),dark if i%2 else cloth,root)
 elif style=='hunter':
  shape('HEAD_HAIR',(0,.045,h*.965),(.24,.22,h*.065),dark,root,'body')
  for side in [-1,1]:
   pauldron=shape('PAULDRON',(side*w*.49,0,h*.80),(w*.30,.29,.12),cloth,root,'body')
  shape('CHEST_PLATE',(0,-.16,h*.71),(w*.62,.045,h*.18),dark,root,'body')
  shape('CHEST_GEM',(0,-.20,h*.76),(.055,.04,.075),jade,root,'body')
 elif style=='wrestler':
  shape('BEARD',(0,-.09,h*.885),(.15,.12,.09),dark,root,'body')
  for side in [-1,1]:
   shape('WAR_PAINT',(side*w*.21,-.19,h*.73),(.035,.018,h*.08),cloth,root)
 else:
  shape('HEAD_HOOD',(0,.085,h*.91),(.30,.25,h*.17),cloth,root,'body')
  shape('HEAD_MASK',(0,-.125,h*.925),(.20,.055,h*.12),steel,root,'body')
  for side in [-1,1]:
   shape('HEAD_LENS',(side*.05,-.16,h*.94),(.045,.025,.028),jade,root,'body')
   shape('PAULDRON',(side*w*.48,0,h*.81),(.21,.30,.18),cloth,root,'body')
  shape('CHEST_PLATE',(0,-.15,h*.69),(w*.68,.07,h*.25),steel,root,'body')
  for row in range(4):
   for side in [-1,1]:
    obj=shape('RIB_ARMOUR',(side*.07,-.20,h*(.77-row*.045)),(.14,.035,.025),ivory,root)
    obj.rotation_euler.y=side*.25
