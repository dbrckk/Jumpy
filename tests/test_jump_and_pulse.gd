extends Node

const MAIN_SCENE_PATH = "res://scenes/Main.tscn"

func _ready() -> void:
    var main_scene = load(MAIN_SCENE_PATH)
    var main_instance = main_scene.instantiate()
    add_child(main_instance)
    
    yield(main_instance, "ready")
    yield(get_tree(), "process_frame")
    
    # Start a run
    var event = InputEventKey.new()
    event.physical_keycode = 32
    event.pressed = true
    main_instance._unhandled_input(event)
    
    # Wait a bit for the jump to start
    yield(get_tree(), "process_frame")
    yield(get_tree(), "process_frame")
    
    # Simulate a pulse (tap while in air)
    event.pressed = true  # Ensure pressed is true
    main_instance._unhandled_input(event)
    
    # Check that pulse_available is now false
    if not main_instance.pulse_available:
        print("PASSED: test_jump_and_pulse - pulse_available is false after pulse")
    else:
        print("FAILED: test_jump_and_pulse - pulse_available is still true")
        push_error("test_jump_and_pulse failed")
    
    main_instance.queue_free()
    get_tree().quit()

