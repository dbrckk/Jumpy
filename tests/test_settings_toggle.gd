extends Node

const MAIN_SCENE_PATH = "res://scenes/Main.tscn"

func _ready() -> void:
    var main_scene = load(MAIN_SCENE_PATH)
    var main_instance = main_scene.instantiate()
    add_child(main_instance)
    
    yield(main_instance, "ready")
    yield(get_tree(), "process_frame")
    
    # Ensure we are in READY state and settings are closed
    if main_instance.state != "READY" or main_instance.settings_open:
        # Reset to ready if needed
        main_instance.state = "READY"
        main_instance.settings_open = false
        main_instance.show_menu(true)  # This will refresh the UI
    
    # Find the Sound setting button
    var sound_button = main_instance.ui.get("setting_sound")
    if sound_button == null:
        print("FAILED: test_settings_toggle - could not find setting_sound button")
        push_error("test_settings_toggle failed: missing UI element")
        main_instance.queue_free()
        get_tree().quit()
        return
    
    # Get initial sound state from Profile
    var initial_sound = Profile.data.sound
    
    # Simulate a tap on the sound button
    # We'll call the pressed function directly
    sound_button.pressed.emit()
    
    # Check that the preference was toggled
    var new_sound = Profile.data.sound
    if new_sound != initial_sound:
        print("PASSED: test_settings_toggle - sound toggled from " + str(initial_sound) + " to " + str(new_sound))
    else:
        print("FAILED: test_settings_toggle - sound did not toggle")
        push_error("test_settings_toggle failed: sound not toggled")
    
    # Toggle back
    sound_button.pressed.emit()
    if Profile.data.sound == initial_sound:
        print("PASSED: test_settings_toggle - sound toggled back")
    else:
        print("FAILED: test_settings_toggle - sound did not toggle back")
        push_error("test_settings_toggle failed: sound not toggled back")
    
    main_instance.queue_free()
    get_tree().quit()
