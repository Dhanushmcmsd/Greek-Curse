import json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
graph=json.loads((ROOT/'data/ui/navigation.json').read_text())
def visit(start):
 seen=set();todo=[start]
 while todo:
  node=todo.pop()
  if node in seen:continue
  seen.add(node);todo.extend(graph[node])
 return seen
assert set(graph)-{'error'} <= visit('boot')
for node in graph:
 assert node=='boot' or 'main_menu' in visit(node),node
print('UI_GRAPH_OK',len(graph),'screens')
