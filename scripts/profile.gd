extends Node

const SAVE_PATH: String = "user://jumpy_save.json"
const SAVE_VERSION: int = 1

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
	"haptics": true,
	"reduced_motion": false,
	"high_contrast": false
}

func _ready() -> void:
	load_data()
	_refresh_daily()

func load_data() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_warning("Jumpy: unable to open save file for reading. Error %s" % FileAccess.get_open_error())
		return
	var raw: String = file.get_as_text()
	var parsed: Variant = JSON.parse_string(raw)
	if parsed is Dictionary:
		for key: Variant in parsed.keys():
			if data.has(key):
				data[key] = parsed[key]
	else:
		push_warning("Jumpy: save file is invalid; defaults preserved.")

func save() -> void:
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("Jumpy: unable to open save file for writing. Error %s" % FileAccess.get_open_error())
		return
	file.store_string(JSON.stringify(data))
	file.flush()
	var error: Error = file.get_error()
	if error != OK:
		push_warning("Jumpy: save write failed with error %s" % error)

func set_preference(key: String, value: bool) -> void:
	if key not in ["sound", "haptics", "reduced_motion", "high_contrast"]:
		push_warning("Jumpy: unknown preference %s" % key)
		return
	data[key] = value
	save()

func record_run(score: int, run_coins: int, perfects: int, daily: bool) -> Dictionary:
	data.runs = int(data.runs) + 1
	data.coins = int(data.coins) + run_coins
	data.total_score = int(data.total_score) + score
	data.perfect_landings = int(data.perfect_landings) + perfects
	data.best_score = maxi(int(data.best_score), score)
	if daily:
		data.daily_best = maxi(int(data.daily_best), score)
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
		"runs": mini(int(data.runs), 10),
		"runs_goal": 10,
		"perfects": mini(int(data.perfect_landings), 50),
		"perfects_goal": 50,
		"score": mini(int(data.total_score), 5000),
		"score_goal": 5000
	}

func daily_seed() -> int:
	_refresh_daily()
	return absi(hash(str(data.daily_key)))

func _refresh_daily() -> void:
	var date: Dictionary = Time.get_date_dict_from_system()
	var key: String = "%04d-%02d-%02d" % [date.year, date.month, date.day]
	if str(data.daily_key) != key:
		data.daily_key = key
		data.daily_best = 0
		save()

func _update_streak() -> void:
	var date: Dictionary = Time.get_date_dict_from_system()
	var today: String = "%04d-%02d-%02d" % [date.year, date.month, date.day]
	if str(data.last_play_date) == today:
		return
	if str(data.last_play_date).is_empty():
		data.streak_days = 1
	else:
		var now_unix: int = int(Time.get_unix_time_from_system())
		var last_unix: int = int(Time.get_unix_time_from_datetime_string(str(data.last_play_date) + "T00:00:00"))
		var days: int = int((now_unix - last_unix) / 86400.0)
		data.streak_days = int(data.streak_days) + 1 if days <= 1 else 1
	data.last_play_date = today

func _unlock_earned_skins() -> void:
	var unlocks: Array = data.unlocked_skins
	var milestones: Array[int] = [0, 250, 900, 2200, 5000, 10000]
	for i: int in range(milestones.size()):
		if int(data.total_score) >= milestones[i] and not i in unlocks:
			unlocks.append(i)
	data.unlocked_skins = unlocks
