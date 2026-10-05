extends Node

const DEFAULT_DATA = {
	"version": 1,
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
	RandomNumberGenerator.new().randomize()
	var failed := false
	failed |= !test_defaults()
	failed |= !test_save_load_valid()
	failed |= !test_save_load_invalid_json()
	failed |= !test_save_load_out_of_range()
	failed |= !test_save_load_negative()
	failed |= !test_save_load_non_integer()
	failed |= !test_save_load_invalid_date()
	failed |= !test_skin_unlock_and_select()
	if failed:
		push_error("Profile tests FAILED")
		get_tree().quit(1)
	else:
		print("All Profile tests PASSED")
		get_tree().quit(0)

func test_defaults() -> bool:
	Profile.load_data()
	for key in DEFAULT_DATA.keys():
		if Profile.data.get(key) != DEFAULT_DATA[key]:
			push_error("Defaults mismatch: %s expected %s, got %s" % [key, DEFAULT_DATA[key], Profile.data.get(key)])
			return false
	return true

func test_save_load_valid() -> bool:
	# Set some custom values
	Profile.data.best_score = 100
	Profile.data.coins = 50
	Profile.data.selected_skin = 2
	Profile.data.unlocked_skins = [0, 1, 2]
	Profile.data.sound = false
	Profile.save()

	# Reload
	Profile.load_data()
	if Profile.data.best_score != 100:
		push_error("Best score not saved correctly")
		return false
	if Profile.data.coins != 50:
		push_error("Coins not saved correctly")
		return false
	if Profile.data.selected_skin != 2:
		push_error("Selected skin not saved correctly")
		return false
	if Profile.data.unlocked_skins != [0, 1, 2]:
		push_error("Unlocked skins not saved correctly")
		return false
	if Profile.data.sound != false:
		push_error("Sound setting not saved correctly")
		return false
	return true

func test_save_load_invalid_json() -> bool:
	# Corrupt the save file
	var save_path = "user://jumpy_save.json"
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	if file == null:
		push_error("Could not open save file for writing")
		return false
	file.store_string("NOT JSON")
	file.close()

	Profile.load_data()
	# Check if defaults were restored
	for key in DEFAULT_DATA.keys():
		if Profile.data.get(key) != DEFAULT_DATA[key]:
			push_error("Invalid JSON did not restore defaults for %s: expected %s, got %s" % [key, DEFAULT_DATA[key], Profile.data.get(key)])
		return false
	return true

func test_save_load_out_of_range() -> bool:
	var save_path = "user://jumpy_save.json"
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	if file == null:
		push_error("Could not open save file for writing")
		return false
	# Store a JSON with an integer too big
	var data = DEFAULT_DATA.duplicate(true)
	data.best_score = 9999999999  # way above max int
	file.store_string(JSON.stringify(data))
	file.close()

	Profile.load_data()
	if Profile.data.best_score != DEFAULT_DATA.best_score:
		push_error("Out of range best_score not clamped to fallback")
		return false
	return true

func test_save_load_negative() -> bool:
	var save_path = "user://jumpy_save.json"
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	if file == null:
		push_error("Could not open save file for writing")
		return false
	var data = DEFAULT_DATA.duplicate(true)
	data.coins = -5
	file.store_string(JSON.stringify(data))
	file.close()

	Profile.load_data()
	if Profile.data.coins != DEFAULT_DATA.coins:
		push_error("Negative coins not clamped to fallback")
		return false
	return true

func test_save_load_non_integer() -> bool:
	var save_path = "user://jumpy_save.json"
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	if file == null:
		push_error("Could not open save file for writing")
		return false
	var data = DEFAULT_DATA.duplicate(true)
	data.runs = 3.14
	file.store_string(JSON.stringify(data))
	file.close()

	Profile.load_data()
	if Profile.data.runs != DEFAULT_DATA.runs:
		push_error("Non-integer runs not clamped to fallback")
		return false
	return true

func test_save_load_invalid_date() -> bool:
	var save_path = "user://jumpy_save.json"
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	if file == null:
		push_error("Could not open save file for writing")
		return false
	var data = DEFAULT_DATA.duplicate(true)
	data.last_play_date = "not-a-date"
	file.store_string(JSON.stringify(data))
	file.close()

	Profile.load_data()
	if Profile.data.last_play_date != "":
		push_error("Invalid date not cleared")
		return false
	return true

func test_skin_unlock_and_select() -> bool:
	# Reset to defaults
	Profile.data = DEFAULT_DATA.duplicate(true)
	Profile.save()

	# Simulate a high total score to unlock skins
	Profile.data.total_score = 6000  # should unlock skins at indices 0,1,2,3,4,5 (milestones: 0,250,900,2200,5000,10000)
	Profile._unlock_earned_skins()
	if Profile.data.unlocked_skins.size() != 6:
		push_error("Expected 6 unlocked skins, got %d" % Profile.data.unlocked_skins.size())
		return false
	var expected = [0, 1, 2, 3, 4, 5]
	for i in expected:
		if i not in Profile.data.unlocked_skins:
			push_error("Missing skin %d in unlocked_skins" % i)
		return false

	# Select skin 4 (should be allowed)
	Profile.select_skin(4)
	if Profile.data.selected_skin != 4:
		push_error("Failed to select skin 4")
		return false

	# Try to select skin 6 (out of range, should not change)
	Profile.select_skin(6)
	if Profile.data.selected_skin != 4:
		push_error("Selecting out-of-range skin changed selection")
		return false

	# Try to select skin 1 (should be allowed because it's unlocked)
	Profile.select_skin(1)
	if Profile.data.selected_skin != 1:
		push_error("Failed to select skin 1")
		return false

	return true
"}]}, {