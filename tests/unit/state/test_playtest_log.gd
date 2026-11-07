extends TestCase
## Etapa 10: the playtest record (mecanicas-e-dificuldade.md §13).


func test_counts_deaths_per_room_and_cause() -> void:
	var log := PlaytestLog.new("2026-11-07 10:00:00")
	log.death(30.0, "t01_guardas", "Guarda de Contrapeso")
	log.death(60.0, "t01_guardas", "Guarda de Contrapeso")
	log.death(90.0, "t07_igris", "onda de Igris")
	assert_eq(log.deaths["t01_guardas"]["Guarda de Contrapeso"], 2, "two deaths to the guard")
	assert_true(log.summary(100.0).contains("MORTES: 3"), "summary counts them")


func test_first_use_keeps_the_first_time_only() -> void:
	var log := PlaytestLog.new()
	log.first(12.5, "espada")
	log.first(40.0, "espada")
	assert_eq(log.firsts["espada"], 12.5, "first hit kept")
	assert_true(log.summary(50.0).contains("Primeira travessia com o gancho: não aconteceu"), "missing skills say so")


func test_igris_attempts_have_result_and_length() -> void:
	var log := PlaytestLog.new()
	log.igris_start(100.0)
	log.igris_end(145.0, "morte")
	log.igris_end(150.0, "morte")  # no attempt running: ignored
	log.igris_start(160.0)
	log.igris_end(260.0, "vitória")
	assert_eq(log.igris_attempts.size(), 2, "two attempts")
	assert_eq(log.igris_attempts[0], {"result": "morte", "seconds": 45.0}, "first lasted 45 s")
	assert_true(log.summary(300.0).contains("2: vitória em 1 min 40 s"), "summary line")


func test_refused_commands_and_rooms_in_order() -> void:
	var log := PlaytestLog.new()
	log.room(0.0, "v00_oficina")
	log.room(5.0, "v01_praca")
	log.room(9.0, "v00_oficina")
	log.refuse(3.0, "espada antes de tê-la")
	log.refuse(4.0, "espada antes de tê-la")
	log.finish(500.0)
	log.finish(600.0)
	assert_eq(log.rooms_seen, ["v00_oficina", "v01_praca"], "each room once, in order")
	assert_eq(log.room_visits.size(), 3, "every entry kept, for time per room")
	assert_true(log.summary(20.0).contains("0 min 05 s Praça") or log.summary(20.0).contains("0 min 05 s v01_praca"), "arrival time per room")
	log.hit(6.0, "Rastejo de Tinta")
	assert_true(log.summary(20.0).contains("Rastejo de Tinta: 1"), "hits that did not kill are listed")
	assert_eq(log.refused["espada antes de tê-la"], 2, "counted")
	assert_eq(log.finished_at, 500.0, "first finish kept")
	assert_eq(PlaytestLog.clock(125.4), "2 min 05 s", "clock format")
