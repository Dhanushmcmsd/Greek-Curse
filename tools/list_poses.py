import json
d = json.load(open("data/animation/poses.json", "r"))
for k in sorted(d["poses"].keys()):
    print(k)
print("---SETS---")
for k in sorted(d.get("sets", {}).keys()):
    print(k, "->", d["sets"][k])
