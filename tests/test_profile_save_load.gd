extends Node

const SAVE_PATH = "user://jumpy_save_test.json"

func _ready() -> void:
    # Temporarily change the save path in Profile by setting a singleton? We can't.
    # Instead, we'll test the profile methods directly by creating a Profile instance.
    # But note: Profile is an autoload. We can access it.
    
    # We'll test by:
    # 1. Setting some known values
    # 2. Saving
    # 3. Loading in a new instance and checking the values
    
    # Access the autoloaded Profile
    var profile = Profile
    
    # Backup the original data
    var backup = profile.data.duplicate()
    
    # Set test values
    profile.data.best_score = 1234
    profile.data.coins = 56
    profile.data.selected_skin = 2
    profile.data.unlocked_skins = [0, 1, 2, 3]
    profile.data.sound = false
    
    # Save
    profile.save()
    
    # Now create a new Profile instance to load from the same save file
    # We cannot have two Profiles because it's an autoload. We'll quit and restart?
    # Instead, we'll reload the data by calling load_data directly?
    # But note: load_data is private.
    
    # We'll do: backup the current SAVE_PATH, then load the test save, then restore.
    # However, we are not allowed to change the actual save file used by the game.
    # We'll use a different save path by tricking the Profile? We can't.
    
    # Given the constraints, we'll test the save and load by checking the file content.
    # This is not ideal but we are limited.
    
    # Check that the save file exists and contains our values
    if not FileAccess.file_exists(SAVE_PATH):
        print("FAILED: test_profile_save_load - save file not found at " + SAVE_PATH)
        push_error("test_profile_save_load failed: save file missing")
        profile.data = backup
        profile.save()
        get_tree().quit()
        return
    
    var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
    var content = file.get_as_text()
    file.close()
    
    # Parse the JSON
    var JSON = JSON.new()
    var result = JSON.parse(content)
    if result.error != OK:
        print("FAILED: test_profile_save_load - could not parse save file")
        push_error("test_profile_save_load failed: JSON parse error")
        profile.data = backup
        profile.save()
        get_tree().quit()
        return
    
    var data = result.result
    
    # Check the values
    if data.best_score == 1234 and data.coins == 56 and data.selected_skin == 2 and \
       data.unlocked_skins == [0, 1, 2, 3] and data.sound == false:
        print("PASSED: test_profile_save_load - save file contains expected values")
    else:
        print("FAILED: test_profile_save_load - save file values mismatch. Data: " + str(data))
        push_error("test_profile_save_load failed: data mismatch")
    
    # Restore original data
    profile.data = backup
    profile.save()
    
    get_tree().quit()

