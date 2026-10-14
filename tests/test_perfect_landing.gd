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
    
    # Let the player fall and land on the first platform
    # We'll wait a few frames and then check for landing
    # Note: This is timing-dependent and might be flaky. We'll wait a bit longer.
    for i in 10:
        yield(get_tree(), "process_frame")
        if main_instance.on_ground:
            break
    
    # If we landed, check that it was a perfect landing (by checking flow increase)
    # We know the first platform is wide enough to be perfect if landed in the center.
    # We'll check that flow > 1.0 and combo == 1
    if main_instance.on_ground and main_instance.flow > 1.0 and main_instance.combo == 1:
        print("PASSED: test_perfect_landing - landed perfectly, flow: " + str(main_instance.flow) + ", combo: " + str(main_instance.combo))
    else:
        print("FAILED: test_perfect_landing - not landed perfectly. on_ground: " + str(main_instance.on_ground) + ", flow: " + str(main_instance.flow) + ", combo: " + str(main_instance.combo))
        push_error("test_perfect_landing failed")
    
    main_instance.queue_free()
    get_tree().quit()
