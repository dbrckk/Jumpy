extends Node

const SAVE_PATH := "user://jumpy_save.json"
const SAVE_VERSION := 1

var data: Dictionary = {
	"version": SAVE_VERSION,
	"best_score": 0,
	"coins": 0,
	"runs": 0,
	"perfect_landings": 0,
	"total_score": 0,
	"selected_skin": 0,
	"unlocked_skins": [0],
	"daily_best": 0,
	"daily_key": "",
	"streak_days": 0,
	"last_play_date": "",
	"sound": true,
	"haptics": true
}

func _ready() -> void:
	load_data()
	_refresh_daily()

func load_data() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		for key in parsed.keys():
			data[key] = parsed[key]

func save() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))

func record_run(score: int, run_coins: int, perfects: int, daily: bool) -> Dictionary:
	data.runs = int(data.runs) + 1
	data.coins = int(data.coins) + run_coins
	data.total_score = int(data.total_score) + score
	data.perfect_landings = int(data.perfect_landings) + perfects
	data.best_score = max(int(data.best_score), score)
	if daily:
		data.daily_best = max(int(data.daily_best), score)
	_update_streak()
	_unlock_earned_skins()
	save()
	return get_mission_progress()

func spend_coins(amount: int) -> bool:
	if int(data.coins) < amount:
		return false
	data.coins = int(data.coins) - amount
	save()
	return true

func select_skin(index: int) -> void:
	if index in data.unlocked_skins:
		data.selected_skin = index
		save()

func get_mission_progress() -> Dictionary:
	return {
		"runs": min(int(data.runs), 10),
		"runs_goal": 10,
		"perfects": min(int(data.perfect_landings), 50),
		"perfects_goal": 50,
		"score": min(int(data.total_score), 5000),
		"score_goal": 5000
	}

func daily_seed() -> int:
	_refresh_daily()
	return abs(hash(str(data.daily_key)))

func _refresh_daily() -> void:
	var d := Time.get_date_dict_from_system()
	var key := "%04d-%02d-%02d" % [d.year, d.month, d.day]
	if str(data.daily_key) != key:
		data.daily_key = key
		data.daily_best = 0
		save()

func _update_streak() -> void:
	var d := Time.get_date_dict_from_system()
	var today := "%04d-%02d-%02d" % [d.year, d.month, d.day]
	if str(data.last_play_date) == today:
		return
	if str(data.last_play_date).is_empty():
		data.streak_days = 1
	else:
		var now_unix := Time.get_unix_time_from_system()
		var last_unix := Time.get_unix_time_from_datetime_string(str(data.last_play_date) + "T00:00:00")
		var days := int((now_unix - last_unix) / 86400.0)
		data.streak_days = int(data.streak_days) + 1 if days <= 1 else 1
	data.last_play_date = today

func _unlock_earned_skins() -> void:
	var unlocks: Array = data.unlocked_skins
	var milestones := [0, 250, 900, 2200, 5000, 10000]
	for i in range(milestones.size()):
		if int(data.total_score) >= milestones[i] and not i in unlocks:
			unlocks.append(i)
	data.unlocked_skins = unlocks
