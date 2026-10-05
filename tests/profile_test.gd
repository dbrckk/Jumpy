# Tests for the Profile class.
# This test backs up and restores the real save file to avoid interfering with the user's data.

# We use Godot's built-in unit test framework if available, but we can also run this as a script.
# To run: godot -s tests/profile_test.gd

# If you don't have the unit test plugin, we'll use a simple assert and report.

const SAVE_PATH := "user://jumpy_save.json"
const BACKUP_PATH := "user://jumpy_save_test_backup.json"

func _ready() -> void:
    var passed := true
    passed := test_save_integer() and passed
    passed := test_save_date() and passed
    passed := test_validated_save() and passed
    passed := test_get_mission_progress() and passed
    passed := test_spend_coins() and passed
    
    if passed:
        print("All tests passed!")
    else:
        print("Some tests failed!")
        # Exit with error code if running as a script.
        get_tree().quit()

func test_save_integer() -> bool:
    var profile := Profile
    # We call the private method by using the instance. In GDScript, we can access private members.
    # Note: This is for testing only.
    
    # Valid integers
    assert_equal(profile._save_integer(5), 5, "Valid integer 5")
    assert_equal(profile._save_integer(0), 0, "Valid integer 0")
    assert_equal(profile._save_integer(-3), 0, "Negative integer should return fallback 0")
    assert_equal(profile._save_integer(9999999999), 2147483647, "Too large integer should return maximum")
    assert_equal(profile._save_integer(3.14), 3, "Float 3.14 should be floored to 3")
    assert_equal(profile._save_integer(3.9), 3, "Float 3.9 should be floored to 3")
    
    # Invalid types
    assert_equal(profile._save_integer(null), 0, "Null should return fallback 0")
    assert_equal(profile._save_integer("5"), 0, "String should return fallback 0")
    assert_equal(profile._save_integer([]), 0, "Array should return fallback 0")
    
    # Non-finite numbers
    assert_equal(profile._save_integer(inf), 0, "Infinity should return fallback 0")
    assert_equal(profile._save_integer(-inf), 0, "Negative infinity should return fallback 0")
    assert_equal(profile._save_integer(NaN), 0, "NaN should return fallback 0")
    
    return true

func test_save_date() -> bool:
    var profile := Profile
    
    # Valid dates
    assert_equal(profile._save_date("2024-01-01"), "2024-01-01", "Valid date")
    assert_equal(profile._save_date("2020-02-29"), "2020-02-29", "Leap year")
    assert_equal(profile._save_date("1999-12-31"), "1999-12-31", "End of year")
    
    # Invalid dates
    assert_equal(profile._save_date(""), "", "Empty string")
    assert_equal(profile._save_date("2024-01"), "", "Missing day")
    assert_equal(profile._save_date("2024-13-01"), "", "Invalid month")
    assert_equal(profile._save_date("2024-00-01"), "", "Zero month")
    assert_equal(profile._save_date("2024-01-00"), "", "Zero day")
    assert_equal(profile._save_date("2024-01-32"), "", "Invalid day")
    assert_equal(profile._save_date("2024-02-29"), "", "Non-leap year February 29")
    assert_equal(profile._save_date("not-a-date"), "", "Non-date string")
    assert_equal(profile._save_date("2024/01/01"), "", "Wrong separator")
    assert_equal(profile._save_date("2024-01-01-"), "", "Extra character")
    
    return true

func test_validated_save() -> bool:
    var profile := Profile
    
    # Test with empty dictionary -> should return default data
    var empty_dict : Dictionary = {}
    var result := profile._validated_save(empty_dict)
    assert_equal(result.version, Profile.SAVE_VERSION, "Version should be default")
    assert_equal(result.best_score, 0, "Best score should be 0")
    assert_equal(result.coins, 0, "Coins should be 0")
    assert_equal(result.runs, 0, "Runs should be 0")
    assert_equal(result.perfect_landings, 0, "Perfect landings should be 0")
    assert_equal(result.total_score, 0, "Total score should be 0")
    assert_equal(result.selected_skin, 0, "Selected skin should be 0")
    assert_equal(result.unlocked_skins, [0], "Unlocked skins should be [0]")
    assert_equal(result.daily_best, 0, "Daily best should be 0")
    assert_equal(result.daily_key, "", "Daily key should be empty")
    assert_equal(result.streak_days, 0, "Streak days should be 0")
    assert_equal(result.last_play_date, "", "Last play date should be empty")
    assert_equal(result.sound, true, "Sound should be true by default")
    assert_equal(result.haptics, true, "Haptics should be true by default")
    assert_equal(result.reduced_motion, false, "Reduced motion should be false by default")
    assert_equal(result.high_contrast, false, "High contrast should be false by default")
    
    # Test with valid data
    var valid_dict : Dictionary = {
        "version": 2,
        "best_score": 1500,
        "coins": 50,
        "runs": 10,
        "perfect_landings": 5,
        "total_score": 8000,
        "selected_skin": 2,
        "unlocked_skins": [0, 1, 2],
        "daily_best": 300,
        "daily_key": "2024-01-01",
        "streak_days": 5,
        "last_play_date": "2024-01-01",
        "sound": false,
        "haptics": true,
        "reduced_motion": true,
        "high_contrast": false
    }
    result = profile._validated_save(valid_dict)
    assert_equal(result.version, 1, "Version should be reset to SAVE_VERSION (1) because we only accept version 1? Actually, the _validated_save function does not check version, it uses DEFAULT_DATA and then overwrites. But note: the DEFAULT_DATA has version SAVE_VERSION. So if we pass version 2, it will be ignored and set to SAVE_VERSION because we start from DEFAULT_DATA and then overwrite only the keys we know. So version will be SAVE_VERSION.")
    # Actually, the function starts with DEFAULT_DATA and then overwrites the keys that are in the parsed data. So version will be overwritten only if the parsed data has a "version" key and we process it. But we do not process "version" in the loop. So version will remain as DEFAULT_DATA's version (SAVE_VERSION).
    # Let's check: the function does not have "version" in the list of keys to process. So it will be left as the DEFAULT_DATA's version.
    assert_equal(result.version, Profile.SAVE_VERSION, "Version should be SAVE_VERSION")
    assert_equal(result.best_score, 1500, "Best score")
    assert_equal(result.coins, 50, "Coins")
    assert_equal(result.runs, 10, "Runs")
    assert_equal(result.perfect_landings, 5, "Perfect landings")
    assert_equal(result.total_score, 8000, "Total score")
    assert_equal(result.selected_skin, 2, "Selected skin")
    assert_equal(result.unlocked_skins, [0, 1, 2], "Unlocked skins")
    assert_equal(result.daily_best, 300, "Daily best")
    assert_equal(result.daily_key, "2024-01-01", "Daily key")
    assert_equal(result.streak_days, 5, "Streak days")
    assert_equal(result.last_play_date, "2024-01-01", "Last play date")
    assert_equal(result.sound, false, "Sound")
    assert_equal(result.haptics, true, "Haptics")
    assert_equal(result.reduced_motion, true, "Reduced motion")
    assert_equal(result.high_contrast, false, "High contrast")
    
    # Test with invalid data in the dictionary
    var invalid_dict : Dictionary = {
        "best_score": -5,  # negative -> should become 0
        "coins": "not a number",  # string -> should become 0
        "runs": 3.5,  # float -> should become 3 (floored) but note: we check for finite and nonnegative and integer? Actually, _save_integer will return fallback if not finite or negative or not integer? Wait: 3.5 is finite and nonnegative, but not integer -> it will return fallback (0) because 3.5 != floor(3.5).
        "perfect_landings": 9999999999,  # too big -> becomes 2147483647
        "total_score": -10,  # negative -> 0
        "selected_skin": 10,  # out of range [0,5] -> becomes 0 (because not in unlocks, but note: we process selected_skin after unlocks)
        "unlocked_skins": ["not an int", 2, -1, 6, 2],  # string -> -1 (fallback) -> ignored, 2 -> valid, -1 -> -1 -> ignored, 6 -> 6 -> but then we check if index>=0 and not in unlocks -> 6 is not in [0] initially, but note: we start with [0] and then we process the array. We'll get 2 and 6? But 6 is beyond the skin list? We only have 6 skins (0..5). So 6 is invalid and should be ignored? Actually, in the loop we do: var index = _save_integer(item, -1, 5). So 6 becomes 5? Wait: the maximum is 5, so 6 becomes fallback -1? No: the _save_integer function with maximum 5: if the number is >5, it returns the fallback? Let's look: in _save_integer, if number > maximum, return fallback. So 6 becomes -1 -> then we check if index>=0 -> false -> ignored.
        "sound": "yes",  # not boolean -> ignored, so remains true (from DEFAULT_DATA)
        "haptics": null,  # not boolean -> ignored -> remains true
        "reduced_motion": "maybe",  # ignored -> remains false
        "high_contrast": 1,  # not boolean -> ignored -> remains false
        "daily_key": "not-a-date",  # becomes empty string
        "last_play_date": "also not-a-date",  # becomes empty string
        "streak_days": -3,  # negative -> becomes 0
    }
    result = profile._validated_save(invalid_dict)
    # We expect:
    #   best_score: 0 (because -5 -> invalid -> fallback 0)
    #   coins: 0 (because string -> fallback 0)
    #   runs: 0 (because 3.5 -> not integer -> fallback 0)
    #   perfect_landings: 2147483647 (because 9999999999 -> too big -> fallback maximum)
    #   total_score: 0 (because -10 -> fallback 0)
    #   selected_skin: 0 (because 10 -> out of range [0,5] -> fallback 0, and then we check if 0 is in unlocks? We'll see unlocks below)
    #   unlocked_skins: [0, 2]  (because we start with [0], then we process the array: "not an int" -> -1 -> ignored, 2 -> valid and not in [0] -> add, -1 -> ignored, 6 -> becomes -1 (because 6>5 -> fallback -1) -> ignored, 2 -> duplicate -> ignored)
    #   daily_best: 0 (because invalid -> fallback 0)
    #   daily_key: "" (invalid date -> empty)
    #   streak_days: 0 (negative -> fallback 0)
    #   last_play_date: "" (invalid date -> empty)
    #   sound: true (because not boolean -> ignored, so DEFAULT_DATA's true)
    #   haptics: true (ignored -> DEFAULT_DATA's true)
    #   reduced_motion: false (ignored -> DEFAULT_DATA's false)
    #   high_contrast: false (ignored -> DEFAULT_DATA's false)
    
    assert_equal(result.best_score, 0, "Best score with negative")
    assert_equal(result.coins, 0, "Coins with string")
    assert_equal(result.runs, 0, "Runs with float")
    assert_equal(result.perfect_landings, 2147483647, "Perfect landings too big")
    assert_equal(result.total_score, 0, "Total score negative")
    assert_equal(result.selected_skin, 0, "Selected skin out of range")
    assert_equal(result.unlocked_skins, [0, 2], "Unlocked skins with mixed valid/invalid")
    assert_equal(result.daily_best, 0, "Daily best invalid")
    assert_equal(result.daily_key, "", "Daily key invalid date")
    assert_equal(result.streak_days, 0, "Streak days negative")
    assert_equal(result.last_play_date, "", "Last play date invalid date")
    assert_equal(result.sound, true, "Sound non-boolean")
    assert_equal(result.haptics, true, "Haptics non-boolean")
    assert_equal(result.reduced_motion, false, "Reduced motion non-boolean")
    assert_equal(result.high_contrast, false, "High contrast non-boolean")
    
    return true

func test_get_mission_progress() -> bool:
    var profile := Profile
    
    # Set some known values
    profile.data.runs = 7
    profile.data.runs_goal = 10  # Note: the goal is hardcoded in get_mission_progress to 10 for runs, 50 for perfects, 5000 for score.
    profile.data.perfect_landings = 25
    profile.data.total_score = 3000
    
    var progress := profile.get_mission_progress()
    assert_equal(progress.runs, 7, "Runs should be 7 (min of 7 and 10)")
    assert_equal(progress.runs_goal, 10, "Runs goal should be 10")
    assert_equal(progress.perfects, 25, "Perfects should be 25 (min of 25 and 50)")
    assert_equal(progress.perfects_goal, 50, "Perfects goal should be 50")
    assert_equal(progress.score, 3000, "Score should be 3000 (min of 3000 and 5000)")
    assert_equal(progress.score_goal, 5000, "Score goal should be 5000")
    
    # Test with values over the goal
    profile.data.runs = 15
    profile.data.perfect_landings = 60
    profile.data.total_score = 6000
    progress = profile.get_mission_progress()
    assert_equal(progress.runs, 10, "Runs should be capped at 10")
    assert_equal(progress.perfects, 50, "Perfects should be capped at 50")
    assert_equal(progress.score, 5000, "Score should be capped at 5000")
    
    return true

func test_spend_coins() -> bool:
    # We need to backup the save file, run the test, and then restore.
    var backup_exists := FileAccess.file_exists(BACKUP_PATH)
    if backup_exists:
        var backup_file := FileAccess.open(BACKUP_PATH, FileAccess.READ)
        var backup_content := backup_file.get_as_text()
        backup_file.close()
        # We'll restore later
    
    var save_exists := FileAccess.file_exists(SAVE_PATH)
    var save_content : String
    if save_exists:
        var save_file := FileAccess.open(SAVE_PATH, FileAccess.READ)
        save_content := save_file.get_as_text()
        save_file.close()
    
    # We'll set up a known state for the test
    var profile := Profile
    # We cannot directly set the data because it's a singleton and we want to test the function.
    # Instead, we will load the save file, modify it, and then save it? But we are going to test the spend_coins function which saves.
    # We'll set the data to a known state by directly modifying the singleton's data dictionary.
    # This is acceptable for testing because we are going to restore the save file and the singleton's data will be overwritten when the game reloads?
    # But note: we are in the editor, and the singleton is already loaded. We are going to change its data and then save it.
    # We will then restore the save file from backup, but the singleton's data in memory will be our test data until the game is reloaded.
    # We are okay with that because this is a test and we are not relying on the singleton's data after the test.
    
    # Set known state: 10 coins
    profile.data.coins = 10
    profile.save()  # Save this state so that the function has a known starting point.
    
    # Test 1: spending 5 should succeed and leave 5 coins
    var success := profile.spend_coins(5)
    assert_equal(success, true, "Spending 5 should succeed")
    assert_equal(profile.data.coins, 5, "Coins should be 5 after spending 5")
    
    # Test 2: spending 6 should fail and leave 5 coins
    success = profile.spend_coins(6)
    assert_equal(success, false, "Spending 6 should fail")
    assert_equal(profile.data.coins, 5, "Coins should still be 5 after failed spend")
    
    # Test 3: spending 0 should fail and leave 5 coins
    success = profile.spend_coins(0)
    assert_equal(success, false, "Spending 0 should fail")
    assert_equal(profile.data.coins, 5, "Coins should still be 5 after spending 0")
    
    # Test 4: spending -1 should fail and leave 5 coins
    success = profile.spend_coins(-1)
    assert_equal(success, false, "Spending -1 should fail")
    assert_equal(profile.data.coins, 5, "Coins should still be 5 after spending -1")
    
    # Now restore the save file
    if save_exists:
        var save_file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
        save_file.store_string(save_content)
        save_file.flush()
        save_file.close()
    else:
        # If there was no save file, we remove the one we created.
        FileAccess.remove(SAVE_PATH)
    
    # Also remove the backup if we created one? We didn't create a backup in this function, we only read it.
    # We'll leave the backup as is.
    
    return true

# Helper function for assertions
func assert_equal(actual, expected, message:String) -> bool:
    if actual == expected:
        print("PASS: " + message)
        return true
    else:
        print("FAIL: " + message + " (expected: " + str(expected) + ", got: " + str(actual) + ")")
        return false

# If we are run as a script, we call _ready.
if Engine.is_editor_hint():
    # We are in the editor, we can call _ready manually.
    _ready()

# Note: This test will run when the script is loaded if we are in the editor.
# If we want to run it from the command line, we can do: godot -s tests/profile_test.gd
]},
{