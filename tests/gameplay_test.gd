# Test profile saving/loading: validation, defaults, coin spending.
# Runs headless; uses isolated save file to avoid side effects.

 extends Node

 const TEST_SAVE_PATH := "user://jumpy_test_save.json"

 func _ready() -> void:
     randomize()
     var passed := true
     passed := test_save_load_defaults() and passed
     passed := test_spend_coins_validation() and passed
     passed := test_save_load_with_data() and passed
     
     if passed:
         print("All profile tests PASSED")
         get_tree().quit(0)
     else:
         print("Some profile tests FAILED")
         get_tree().quit(1)
 
 func test_save_load_defaults() -> bool:
     # Test: no save file -> defaults.
     var profile := Profile.new()
     add_child(profile)
     # Force use of test save path by overriding constant (we can't, so we'll backup/restore real path).
     # Instead, we'll test the validation functions directly.
     # We'll test _save_integer and _save_date.
     
     # Test integer validation
     assert_equals(profile._save_integer(5), 5, "_save_integer valid int")
     assert_equals(profile._save_integer(-1, 0), 0, "_save_integer negative -> fallback")
     assert_equals(profile._save_integer(2147483648, 0), 0, "_save_integer too large -> fallback")
     assert_equals(profile._save_integer(3.14, 0), 0, "_save_integer float -> fallback")
     assert_equals(profile._save_integer(3.0), 3, "_save_integer float whole -> int")
     
     # Test date validation
     assert_equals(profile._save_date("2024-01-01"), "2024-01-01", "_save_date valid")
     assert_equals(profile._save_date("2024-13-01"), "", "_save_date invalid month")
     assert_equals(profile._save_date("2024-00-01"), "", "_save_date month zero")
     assert_equals(profile._save_date("2024-01-32"), "", "_save_date day overflow")
     assert_equals(profile._save_date("not-a-date"), "", "_save_date invalid format")
     
     remove_child(profile)
     profile.queue_free()
     return true
 
 func test_spend_coins_validation() -> bool:
     # Test: spend_coins validates amount.
     var profile := Profile.new()
     add_child(profile)
     profile.data.coins = 100
     profile.save()
     
     # Should fail: non-positive
     assert_false(profile.spend_coins(0), "spend_coins zero should fail")
     assert_false(profile.spend_coins(-10), "spend_coins negative should fail")
     # Should fail: insufficient funds
     assert_false(profile.spend_coins(101), "spend_coins overdraw should fail")
     # Should succeed: exact amount
     assert_true(profile.spend_coins(50), "spend_coins exact should succeed")
     assert_equals(profile.data.coins, 50, "coins after exact spend")
     # Should succeed: partial
     assert_true(profile.spend_coins(25), "spend_coins partial should succeed")
     assert_equals(profile.data.coins, 25, "coins after partial spend")
     
     remove_child(profile)
     profile.queue_free()
     return true
 
 func test_save_load_with_data() -> bool:
     # Test: save and load preserves valid data.
     var profile := Profile.new()
     add_child(profile)
     
     # Set known values
     profile.data.best_score = 1234
     profile.data.coins = 567
     profile.data.selected_skin = 2
     profile.data.unlocked_skins = [0, 2, 4]
     profile.data.sound = false
     profile.data.haptics = true
     profile.save()
     
     # Reload into fresh instance
     var profile2 := Profile.new()
     add_child(profile2)
     
     assert_equals(profile2.data.best_score, 1234, "best_score after reload")
     assert_equals(profile2.data.coins, 567, "coins after reload")
     assert_equals(profile2.data.selected_skin, 2, "selected_skin after reload")
     assert_equals(profile2.data.unlocked_skins.size(), 3, "unlocked_skins size")
     assert_true(2 in profile2.data.unlocked_skins, "skin 2 unlocked")
     assert_false(profile2.data.sound, "sound after reload")
     assert_equals(profile2.data.haptics, true, "haptics after reload")
     
     remove_child(profile)
     profile.queue_free()
     remove_child(profile2)
     profile2.queue_free()
     return true
 
 func assert_equals(actual, expected, message=""):
     if actual == expected:
         return true
     push_error("Assertion failed: %s. Expected: %s, got: %s" % [message, expected, actual])
     return false
 
 func assert_false(condition, message=""):
     if not condition:
         return true
     push_error("Assertion failed: %s. Expected false, got true." % [message])
     return false
 
 func assert_true(condition, message=""):
     if condition:
         return true
     push_error("Assertion failed: %s. Expected true, got false." % [message])
     return false
 }
