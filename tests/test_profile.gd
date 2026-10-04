extends UnitTest

const SAVE_PATH := "user://jumpy_save.json"
const BACKUP_PATH := "user://jumpy_save.json.backup"

func _setup_method() -> void:
    # Backup existing save if any
    if FileAccess.file_exists(SAVE_PATH):
        FileAccess.rename(SAVE_PATH, BACKUP_PATH)

func _teardown_method() -> void:
    # Remove test save and restore backup
    if FileAccess.file_exists(SAVE_PATH):
        FileAccess.remove(SAVE_PATH)
    if FileAccess.file_exists(BACKUP_PATH):
        FileAccess.rename(BACKUP_PATH, SAVE_PATH)

func test_load_defaults() -> void:
    # Ensure no save file
    assert_false(FileAccess.file_exists(SAVE_PATH))
    var profile := Profile.new()
    # Call _ready to load data (which will load defaults)
    profile._ready()
    assert_equals(profile.data, Profile.DEFAULT_DATA.duplicate(true))
    profile.queue_free()

func test_load_valid_save() -> void:
    # Create a valid save
    var valid_data := {
        "version": 1,
        "best_score": 1500,
        "coins": 50,
        "runs": 10,
        "perfect_landings": 100,
        "total_score": 5000,
        "selected_skin": 2,
        "unlocked_skins": [0, 1, 2],
        "daily_best": 800,
        "daily_key": "2026-09-09",
        "streak_days": 5,
        "last_play_date": "2026-09-08",
        "sound": false,
        "haptics": true,
        "reduced_motion": true,
        "high_contrast": false
    }
    var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    assert_not_null(file)
    file.store_string(JSON.stringify(valid_data))
    file.close()
    
    var profile := Profile.new()
    profile._ready()
    assert_equals(profile.data.best_score, 1500)
    assert_equals(profile.data.coins, 50)
    assert_equals(profile.data.runs, 10)
    assert_equals(profile.data.perfect_landings, 100)
    assert_equals(profile.data.total_score, 5000)
    assert_equals(profile.data.selected_skin, 2)
    assert_equals(profile.data.unlocked_skins, [0, 1, 2])
    assert_equals(profile.data.daily_best, 800)
    assert_equals(profile.data.daily_key, "2026-09-09")
    assert_equals(profile.data.streak_days, 5)
    assert_equals(profile.data.last_play_date, "2026-09-08")
    assert_equals(profile.data.sound, false)
    assert_equals(profile.data.haptics, true)
    assert_equals(profile.data.reduced_motion, true)
    assert_equals(profile.data.high_contrast, false)
    profile.queue_free()

func test_load_invalid_json() -> void:
    # Write invalid JSON
    var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    assert_not_null(file)
    file.store_string("not json")
    file.close()
    
    var profile := Profile.new()
    profile._ready()
    # Should fall back to defaults
    assert_equals(profile.data, Profile.DEFAULT_DATA.duplicate(true))
    profile.queue_free()

func test_load_oversized_file() -> void:
    # Create a file larger than 256 KiB
    var oversized := ""
    for i in 262145:  # 256*1024 + 1
        oversized += "x"
    var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    assert_not_null(file)
    file.store_string(oversized)
    file.close()
    
    var profile := Profile.new()
    profile._ready()
    # Should fall back to defaults
    assert_equals(profile.data, Profile.DEFAULT_DATA.duplicate(true))
    profile.queue_free()

func test_save_and_load() -> void:
    var profile := Profile.new()
    profile._ready()
    # Modify data
    profile.data.best_score = 2000
    profile.data.coins = 75
    profile.data.runs = 5
    profile.data.perfect_landings = 20
    profile.data.total_score = 3000
    profile.data.selected_skin = 3
    profile.data.unlocked_skins = [0, 1, 2, 3]
    profile.data.daily_best = 1200
    profile.data.daily_key = "2026-09-10"
    profile.data.streak_days = 3
    profile.data.last_play_date = "2026-09-09"
    profile.data.sound = true
    profile.data.haptics = false
    profile.data.reduced_motion = false
    profile.data.high_contrast = true
    profile.save()
    profile.queue_free()
    
    # Reload
    var profile2 := Profile.new()
    profile2._ready()
    assert_equals(profile2.data.best_score, 2000)
    assert_equals(profile2.data.coins, 75)
    assert_equals(profile2.data.runs, 5)
    assert_equals(profile2.data.perfect_landings, 20)
    assert_equals(profile2.data.total_score, 3000)
    assert_equals(profile2.data.selected_skin, 3)
    assert_equals(profile2.data.unlocked_skins, [0, 1, 2, 3])
    assert_equals(profile2.data.daily_best, 1200)
    assert_equals(profile2.data.daily_key, "2026-09-10")
    assert_equals(profile2.data.streak_days, 3)
    assert_equals(profile2.data.last_play_date, "2026-09-09")
    assert_equals(profile2.data.sound, true)
    assert_equals(profile2.data.haptics, false)
    assert_equals(profile2.data.reduced_motion, false)
    assert_equals(profile2.data.high_contrast, true)
    profile2.queue_free()

func test_save_integer_validation() -> void:
    # Test _save_integer with various inputs
    var profile := Profile.new()
    # We'll test via the save process by setting data and saving
    # But we can also test the private method by using reflection? Not directly.
    # Instead, we test the effect on saved data.
    # We'll set invalid values and see if they are corrected.
    
    # Test negative -> fallback to 0
    profile.data.best_score = -5
    profile.save()
    var p2 := Profile.new()
    p2._ready()
    assert_equals(p2.data.best_score, 0)
    p2.queue_free()
    profile.queue_free()
    
    # Test non-integer float -> fallback to 0
    profile = Profile.new()
    profile._ready()
    profile.data.best_score = 10.5
    profile.save()
    p2 = Profile.new()
    p2._ready()
    assert_equals(p2.data.best_score, 0)
    p2.queue_free()
    profile.queue_free()
    
    # Test too large -> fallback to 0 (maximum is 2147483647)
    profile = Profile.new()
    profile._ready()
    profile.data.best_score = 2147483648
    profile.save()
    p2 = Profile.new()
    p2._ready()
    assert_equals(p2.data.best_score, 0)
    p2.queue_free()
    profile.queue_free()
    
    # Test valid integer within range
    profile = Profile.new()
    profile._ready()
    profile.data.best_score = 1000000
    profile.save()
    p2 = Profile.new()
    p2._ready()
    assert_equals(p2.data.best_score, 1000000)
    p2.queue_free()
    profile.queue_free()

func test_save_date_validation() -> void:
    var profile := Profile.new()
    profile._ready()
    
    # Valid date
    profile.data.last_play_date = "2026-09-09"
    profile.save()
    var p2 := Profile.new()
    p2._ready()
    assert_equals(p2.data.last_play_date, "2026-09-09")
    p2.queue_free()
    
    # Invalid format
    profile = Profile.new()
    profile._ready()
    profile.data.last_play_date = "2026/09/09"
    profile.save()
    p2 = Profile.new()
    p2._ready()
    assert_equals(p2.data.last_play_date, "")  # invalid -> empty string
    p2.queue_free()
    profile.queue_free()
    
    # Invalid month
    profile = Profile.new()
    profile._ready()
    profile.data.last_play_date = "2026-13-09"
    profile.save()
    p2 = Profile.new()
    p2._ready()
    assert_equals(p2.data.last_play_date, "")
    p2.queue_free()
    profile.queue_free()
    
    # Invalid day
    profile = Profile.new()
    profile._ready()
    profile.data.last_play_date = "2026-09-31"
    profile.save()
    p2 = Profile.new()
    p2._ready()
    assert_equals(p2.data.last_play_date, "")
    p2.queue_free()
    profile.queue_free()
    
    profile.queue_free()

func test_unlock_skins_and_select_skin() -> void:
    var profile := Profile.new()
    profile._ready()
    # Start with only skin 0 unlocked
    assert_equals(profile.data.unlocked_skins, [0])
    assert_equals(profile.data.selected_skin, 0)
    
    # Earn enough total score to unlock skin 1 (milestone 250)
    profile.data.total_score = 250
    profile._unlock_earned_skins()
    assert_equals(profile.data.unlocked_skins, [0, 1])
    # selected_skin should remain 0 if still unlocked
    assert_equals(profile.data.selected_skin, 0)
    
    # Now select skin 1
    profile.select_skin(1)
    assert_equals(profile.data.selected_skin, 1)
    
    # Try to select a locked skin (say 5) -> should stay at 1
    profile.select_skin(5)
    assert_equals(profile.data.selected_skin, 1)
    
    # Unlock skin 5 by reaching milestone 10000
    profile.data.total_score = 10000
    profile._unlock_earned_skins()
    assert_equals(profile.data.unlocked_skins, [0, 1, 2, 3, 4, 5])  # milestones: [0,250,900,2200,5000,10000]
    # Now we can select skin 5
    profile.select_skin(5)
    assert_equals(profile.data.selected_skin, 5)
    
    profile.queue_free()

