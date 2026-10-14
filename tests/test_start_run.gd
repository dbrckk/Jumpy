extends Node

const MAIN_SCENE_PATH = "res://scenes/Main.tscn"

func _ready() -> void:
    var main_scene = load(MAIN_SCENE_PATH)
    var main_instance = main_scene.instantiate()
    add_child(main_instance)
    
    # Wait for the main instance to be ready
    yield(main_instance, "ready")
    yield(get_tree(), "process_frame")  # Wait for one frame to let _ready logic settle
    
    # Simulate a tap (spacebar key press)
    var event = InputEventKey.new()
    event.physical_keycode = 32  # Spacebar
    event.pressed = true
    main_instance._unhandled_input(event)
    
    # Check that the state is now PLAYING
    if main_instance.state == "PLAYING":
        print("PASSED: test_start_run")
    else:
        print("FAILED: test_start_run - state: " + main_instance.state)
        push_error("test_start_run failed")
    
    # Clean up
    main_instance.queue_free()
    get_tree().quit()

