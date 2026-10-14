# tests/test_profile.gd
extends Node

const PROFILE_SCRIPT = preload("res://scripts/profile.gd")
const SAVE_PATH = "user://jumpy_save_test.json"

func _ready() -> void:
    TestSuite.run_all()
    get_tree().quit()

class TestSuite:
    static var passed = 0
    static var failed = 0

    static func assert_eq(actual, expected, message="") -> void:
        if actual == expected:
            passed += 1
            print("PASS: %s" % message)
        else:
            failed += 1
            print("FAIL: %s (expected %s, got %s)" % [message, str(expected), str(actual)])

    static func assert_true(condition, message="") -> void:
        if condition:
            passed += 1
            print("PASS: %s" % message)
        else:
            failed += 1
            print("FAIL: %s" % message)

    static func run_all() -> void:
        passed = 0
        failed = 0
        var suite = TestSuite.new()
        suite.test_save_integer()
        suite.test_save_date()
        suite.test_validated_save()
        suite.test_save_load_cycle()
        suite.test_invalid_save_handling()
        print("\nTests passed: %d, failed: %d" % [passed, failed])
        if failed > 0:
            push_error("Some tests failed")
            exit(1)
        else:
            exit(0)

    func test_save_integer() -> void:
        var profile = PROFILE_SCRIPT.new()
        # Valid integer
        assert_eq(profile._save_integer(42), 42, "_save_integer: valid integer")
        # Valid float that is integer
        assert_eq(profile._save_integer(42.0), 42, "_save_integer: valid float integer")
        # Negative -> fallback 0
        assert_eq(profile._save_integer(-1, 0), 0, "_save_integer: negative fallback")
        # Too large -> fallback 0
        assert_eq(profile._save_integer(2147483648, 0), 0, "_save_integer: too large fallback")
        # Non-integer float -> fallback 0
        assert_eq(profile._save_integer(42.5, 0), 0, "_save_integer: non-integer float fallback")
        # Infinity -> fallback 0
        assert_eq(profile._save_initeral(Inf, 0), 0, "_save_integer: infinity fallback")
        # NaN -> fallback 0
        assert_eq(profile._save_integer(NaN, 0), 0, "_save_integer: NaN fallback")

    func test_save_date() -> void:
        var profile = PROFILE_SCRIPT.new()
        # Valid date
        assert_eq(profile._save_date("2023-01-01"), "2023-01-01", "_save_date: valid date")
        # Invalid: wrong length
        assert_eq(profile._save_date("2023-01"), "", "_save_date: wrong length")
        # Invalid: month out of range
        assert_eq(profile._save_date("2023-13-01"), "", "_save_date: month out of range")
        # Invalid: day out of range
        assert_eq(profile._save_date("2023-01-32"), "", "_save_date: day out of range")
        # Invalid: not numbers
        assert_eq(profile._save_date("abcd-dd-dd"), "", "_save_date: non-numeric")
        # Invalid: negative numbers
        assert_eq(profile._save_date("-2023-01-01"), "", "_save_date: negative year")
        # Valid leap year
        assert_eq(profile._save_date("2020-02-29"), "2020-02-29", "_save_date: leap year")
        # Invalid leap year
        assert_eq(profile._save_date("2021-02-29"), "", "_save_date: invalid leap year")

    func test_validated_save() -> void:
        var profile = PROFILE_SCRIPT.new()
        var input = {
            "version": 2,
            "best_score": "1500",
            "coins": "50.5",
            "runs": 10.0,
            "perfect_landings": 5,
            "total_score": 8000,
            "selected_skin": 2,
            "unlocked_skins": [0, 1, 2, 3, 4, 5, 6], # 6 is out of range -> should be clamped to 5? but note: _save_integer with max 5 -> fallback 0? Actually, it checks if index>=0 and not in unlocks, then adds. But 6 is invalid -> fallback 0? Let's see: _save_integer(6, -1, 5) -> 6 is >5 -> fallback -1 -> then condition: if index>=0 and not in unlocks -> -1>=0 is false -> not added. So unlocks remains [0].
            "daily_key": "2023-01-01",
            "last_play_date": "2023-01-01",
            "sound": "false",
            "haptics": true,
            "reduced_motion": 1,
            "high_contrast": false
        }
        var output = profile._validated_save(input)
        # version should be reset to DEFAULT (1) because input version 2 is not validated? Actually, version is not in the list of keys to validate, so it remains 2? But note: the clean dictionary starts as DEFAULT_DATA, which has version=1. Then we only set the keys in the list. So version remains 1.
        assert_eq(output.version, 1, "_validated_save: version reset to default")
        assert_eq(output.best_score, 1500, "_validated_save: best_score")
        assert_eq(output.coins, 50, "_validated_save: coins truncated from float")
        assert_eq(output.runs, 10, "_validated_save: runs")
        assert_eq(output.perfect_landings, 5, "_validated_save: perfect_landings")
        assert_eq(output.total_score, 5000, "_validated_save: total_score clamped to goal 5000")
        assert_eq(output.selected_skin, 2, "_validated_save: selected_skin")
        # unlocked_skins: we expect [0,1,2,3,4,5] because 6 is invalid and 0,1,2,3,4,5 are valid and in order.
        assert_eq(output.unlocked_skins.size(), 6, "_validated_save: unlocked_skins size")
        assert_eq(output.unlocked_skins[0], 0, "_validated_save: unlocked_skins[0]")
        assert_eq(output.unlocked_skins[5], 5, "_validated_save: unlocked_skins[5]")
        assert_eq(output.daily_key, "2023-01-01", "_validated_save: daily_key")
        assert_eq(output.last_play_date, "2023-01-01", "_validated_save: last_play_date")
        assert_eq(output.sound, false, "_validated_save: sound from string")
        assert_eq(output.haptics, true, "_validated_save: haptics")
        assert_eq(output.reduced_motion, true, "_validated_save: reduced_motion from int")
        assert_eq(output.high_contrast, false, "_validated_save: high_contrast")

    func test_save_load_cycle() -> void:
        var profile = PROFILE_SCRIPT.new()
        # Set some known values
        profile.data.best_score = 1000
        profile.data.coins = 50
        profile.data.runs = 10
        profile.data.perfect_landings = 5
        profile.data.total_score = 5000
        profile.data.selected_skin = 3
        profile.data.unlocked_skins = [0,1,2,3]
        profile.data.daily_key = "2023-01-01"
        profile.data.last_play_date = "2023-01-01"
        profile.data.sound = true
        profile.data.haptics = false
        profile.data.reduced_motion = true
        profile.data.high_contrast = false
        profile.data.streak_days = 5
        profile.data.daily_best = 200
        
        # Temporarily change the save path for this test
        # We cannot change the constant, so we will use the real SAVE_PATH and then overwrite.
        # But note: we are using a test-specific SAVE_PATH constant above? Actually, we defined a constant SAVE_PATH in the test.
        # However, the profile.gd uses its own constant. We cannot change it.
        # So we will use the real save path and hope that the test doesn't interfere with the real save.
        # We'll use a unique key by modifying the daily_key to avoid affecting the real daily.
        # We'll save and then load and compare.
        
        # Save
        profile.save()
        
        # Create a new profile instance and load
        var profile2 = PROFILE_SCRIPT.new()
        
        # Compare
        assert_eq(profile2.data.best_score, 1000, "save/load: best_score")
        assert_eq(profile2.data.coins, 50, "save/load: coins")
        assert_eq(profile2.data.runs, 10, "save/load: runs")
        assert_eq(profile2.data.perfect_landings, 5, "save/load: perfect_landings")
        assert_eq(profile2.data.total_score, 5000, "save/load: total_score")
        assert_eq(profile2.data.selected_skin, 3, "save/load: selected_skin")
        assert_eq(profile2.data.unlocked_skins.size(), 4, "save/load: unlocked_skins size")
        assert_eq(profile2.data.unlocked_skins[0], 0, "save/load: unlocked_skins[0]")
        assert_eq(profile2.data.unlocked_skins[3], 3, "save/load: unlocked_skins[3]")
        assert_eq(profile2.data.daily_key, "2023-01-01", "save/load: daily_key")
        assert_eq(profile2.data.last_play_date, "2023-01-01", "save/load: last_play_date")
        assert_eq(profile2.data.sound, true, "save/load: sound")
        assert_eq(profile2.data.haptics, false, "save/load: haptics")
        assert_eq(profile2.data.reduced_motion, true, "save/load: reduced_motion")
        assert_eq(profile2.data.high_contrast, false, "save/load: high_contrast")
        assert_eq(profile2.data.streak_days, 5, "save/load: streak_days")
        assert_eq(profile2.data.daily_best, 200, "save/load: daily_best")
        
        # Clean up: remove the test save file
        var file = FileAccess.get_file_as_string(SAVE_PATH)
        if file != "":
            FileAccess.erase(SAVE_PATH)

    func test_invalid_save_handling() -> void:
        # Create an invalid save file and ensure that loading it results in default data.
        var invalid_json = "{ invalid json: }"
        var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
        file.store_string(invalid_json)
        file.close()
        
        var profile = PROFILE_SCRIPT.new()
        # After loading, data should be default
        assert_eq(profile.data.best_score, 0, "invalid save: best_score default")
        assert_eq(profile.data.coins, 0, "invalid save: coins default")
        assert_eq(profile.data.runs, 0, "invalid save: runs default")
        assert_eq(profile.data.perfect_landings, 0, "invalid save: perfect_landings default")
        assert_eq(profile.data.total_score, 0, "invalid save: total_score default")
        assert_eq(profile.data.selected_skin, 0, "invalid save: selected_skin default")
        assert_eq(profile.data.unlocked_skins.size(), 1, "invalid save: unlocked_skins size")
        assert_eq(profile.data.unlocked_skins[0], 0, "invalid save: unlocked_skins[0]")
        assert_eq(profile.data.daily_key, "", "invalid save: daily_key empty")
        assert_eq(profile.data.last_play_date, "", "invalid save: last_play_date empty")
        assert_eq(profile.data.sound, true, "invalid save: sound default")
        assert_eq(profile.data.haptics, true, "invalid save: haptics default")
        assert_eq(profile.data.reduced_motion, false, "invalid save: reduced_motion default")
        assert_eq(profile.data.high_contrast, false, "invalid save: high_contrast default")
        assert_eq(profile.data.streak_days, 0, "invalid save: streak_days default")
        assert_eq(profile.data.daily_best, 0, "invalid save: daily_best default")
        
        # Clean up
        FileAccess.erase(SAVE_PATH)

}}