class_name NameFilter
extends RefCounted


static func clean(value: String, blocked: Array) -> Dictionary:
	var normalized := value.strip_edges()
	while normalized.contains("  "):
		normalized = normalized.replace("  ", " ")
	for pair in [["é", "é"], ["á", "á"], ["ö", "ö"], ["ñ", "ñ"]]:
		normalized = normalized.replace(pair[0], pair[1])
	if normalized.length() < 2 or normalized.length() > 24:
		return {"ok": false, "error": "Use 2–24 characters.", "name": normalized}
	for letter in normalized:
		var code := letter.unicode_at(0)
		if not (
			(code >= 65 and code <= 90)
			or (code >= 97 and code <= 122)
			or (code >= 192 and code <= 687)
			or (code >= 880 and code <= 1023)
			or (code >= 48 and code <= 57)
			or letter in [" ", "-", "'"]
		):
			return {
				"ok": false,
				"error": "Use letters, numbers, spaces, apostrophes or hyphens.",
				"name": normalized
			}
	for word in blocked:
		if normalized.to_lower().contains(str(word).to_lower()):
			return {"ok": false, "error": "Choose another name.", "name": normalized}
	return {"ok": true, "error": "", "name": normalized}
