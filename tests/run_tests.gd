extends SceneTree
## Headless runner:  godot --headless --path godot -s res://tests/run_tests.gd

func _initialize() -> void:
	var files: Array = []
	var dir := DirAccess.open("res://tests")
	for f in dir.get_files():
		if f.begins_with("test_") and f.ends_with(".gd") and f != "test_case.gd":
			files.append(f)
	files.sort()
	var total_checks := 0
	var total_tests := 0
	var failed := 0
	for f in files:
		var script: GDScript = load("res://tests/" + f)
		var t = script.new()
		t.tree = self
		for m in t.get_method_list():
			if not str(m.name).begins_with("test_"): continue
			total_tests += 1
			var before: int = t.failures.size()
			await t.call(m.name)
			if t.failures.size() > before:
				failed += 1
				for i in range(before, t.failures.size()):
					print("  FAIL %s::%s  %s" % [f, m.name, t.failures[i]])
			else:
				print("  ok   %s::%s" % [f, m.name])
		total_checks += t.checks
	print("")
	print("TESTS: %d run, %d failed, %d assertions" % [total_tests, failed, total_checks])
	quit(1 if failed > 0 else 0)
