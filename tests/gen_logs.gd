extends SceneTree
## Dev tool: plays seeded games and dumps {score, log} so the server-side TS replay can be cross-checked.
func _initialize() -> void:
	var out := FileAccess.open(OS.get_environment("LOGS_OUT"), FileAccess.WRITE)
	var rng := RandomNumberGenerator.new()
	rng.seed = 99
	for seed_v in range(1, 31):
		var s := GameSession.new(seed_v)
		for _i in 350:
			if s.game_over:
				if s.continues_used < 2 and rng.randf() < 0.8: s.continue_game()
				else: break
			var r := rng.randf()
			if r < 0.03 and s.board.occupied_count() > 0:
				var cells: Array = []
				for i in 64:
					if s.board.cells[i] != 0: cells.append(i)
				var pick: int = cells[rng.randi_range(0, cells.size() - 1)]
				s.use_hammer(pick / 8, pick % 8)
			elif r < 0.05: s.use_refresh()
			elif r < 0.07: s.use_shuffle()
			var mv := MoveSolver.best_move(s.board, s.tray)
			if mv.is_empty():
				if s.game_over: continue
				break
			if rng.randf() < 0.3:
				var all := MoveSolver.all_moves(s.board, s.tray)
				mv = all[rng.randi_range(0, all.size() - 1)]
			s.place(mv.index, mv.anchor.y, mv.anchor.x)
		out.store_line(JSON.stringify({"seed": seed_v, "score": s.scoring.score, "moves": s.moves, "log": s.event_log}))
	out.close()
	quit()
