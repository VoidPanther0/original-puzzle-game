extends TestCase
## Shooting stone blocks: 1st hit cracks, 2nd hit destroys. Limited charges per game.

func _session(mode: String = "endless") -> GameSession:
	return GameSession.new(7, mode, {})

func test_only_stone_can_be_shot() -> void:
	var s := _session()
	s.board.set_cell(4, 4, 3)      # a normal (player coloured) block
	check(not s.is_shootable(4, 4), "normal blocks are not shootable")
	var res := s.shoot(4, 4)
	check(not res.get("ok", false), "shooting a normal block does nothing")
	eq(s.board.get_cell(4, 4), 3, "normal block untouched")
	s.board.set_cell(5, 5, GameSession.STONE)
	check(s.is_shootable(5, 5), "stone is shootable")
	check(not s.is_shootable(-1, 0), "out of bounds rejected")

func test_first_hit_cracks_second_hit_destroys() -> void:
	var s := _session()
	s.board.set_cell(5, 5, GameSession.STONE)
	var shots_before := s.shots
	var first := s.shoot(5, 5)
	check(first.get("ok", false), "first shot lands")
	check(first.get("cracked", false), "first shot only cracks")
	check(not first.get("destroyed", false), "first shot does not destroy")
	eq(s.board.get_cell(5, 5), GameSession.STONE, "stone still on the board")
	eq(s.shots, shots_before, "no charge spent on the crack")
	var second := s.shoot(5, 5)
	check(second.get("ok", false), "second shot lands")
	check(second.get("destroyed", false), "second shot destroys")
	eq(s.board.get_cell(5, 5), 0, "stone removed")
	eq(s.shots, shots_before - 1, "one charge spent")
	eq(s.cracked.size(), 0, "crack state cleared")

func test_shots_are_limited() -> void:
	var s := _session("level")
	eq(s.shots, GameSession.SHOTS_PER_GAME, "level games start with the level amount")
	s.shots = 1
	s.board.set_cell(5, 5, GameSession.STONE)
	s.shoot(5, 5)                                   # crack (free)
	var res := s.shoot(5, 5)                        # destroy (costs the last charge)
	check(res.get("ok", false), "last charge used")
	eq(s.shots, 0, "no charges left")
	s.board.set_cell(4, 4, GameSession.STONE)
	var no := s.shoot(4, 4)
	check(not no.get("ok", false), "no shot without charges")
	eq(str(no.get("reason", "")), "no_shots", "reason reported")
	eq(s.board.get_cell(4, 4), GameSession.STONE, "stone still on the board")

func test_gravity_after_destroy() -> void:
	var s := _session()
	s.board.set_cell(7, 2, GameSession.STONE)   # stone resting on the floor
	s.board.set_cell(6, 2, 4)                  # a block resting on the stone
	s.shoot(7, 2)                               # crack
	s.shoot(7, 2)                               # destroy
	eq(s.board.get_cell(7, 2), 0, "stone removed")
	eq(s.board.get_cell(6, 2), 4, "the block above does NOT fall")

func test_hammer_does_not_make_blocks_fall() -> void:
	var s := _session()
	s.board.set_cell(7, 2, GameSession.STONE)
	s.board.set_cell(6, 2, 4)
	check(s.use_hammer(7, 2), "hammer breaks the block")
	eq(s.board.get_cell(7, 2), 0, "cell empty")
	eq(s.board.get_cell(6, 2), 4, "the block above stays where it is")
	eq(s.last_falls.size(), 0, "no fall animation")

func test_shot_state_survives_save_roundtrip() -> void:
	var s := _session("level")
	s.board.set_cell(5, 5, GameSession.STONE)
	s.shoot(5, 5)                    # cracked
	s.shots = 3
	var back := GameSession.from_dict(s.to_dict())
	check(back != null, "session restored")
	eq(back.shots, 3, "charges restored")
	eq(back.cracked.size(), 1, "crack restored")
	check(back.is_shootable(5, 5), "stone still shootable")

func test_every_level_has_stone_to_shoot() -> void:
	for ch in LevelDB.chapters():
		for i in range(1, int(ch.levels) + 1):
			var lv := LevelDB.get_level(int(ch.id), i)
			var s := GameSession.new(int(lv.seed), "level", lv)
			check(s.has_stone(), "level %s starts with stone blocks" % lv.id)
			check(s.shots > 0, "level %s has shots" % lv.id)
