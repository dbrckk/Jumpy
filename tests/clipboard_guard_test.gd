# regression test for clipboard guard in share_score
extends="GodotTest"

class_name ClipboardGuardTest

func test_share_score_with_clipboard_feature() -> void:
    # Mock DisplayServer to have clipboard feature
    DisplayServerMock.has_feature_impl = func(feature: int) -> bool:
        if feature == DisplayServer.FEATURE_CLIPBOARD:
            return true
        return false
    
    DisplayServerMock.clipboard_set_impl = func(text: String) -> void:
        clipboard_set_called = true
        clipboard_captured_text = text
    
    # Call share_score
    Integrations.share_score(100, false)
    
    # Verify clipboard was called with correct text
    assert_true(clipboard_set_called, "clipboard_set should be called when FEATURE_CLIPBOARD is available")
    assert_eq(clipboard_captured_text, "JUMPY RUN — 100. Beat me. #Jumpy", "clipboard text should match expected format")
    
    # Verify share_score event was fired
    assert_true(share_score_event_fired, "share_score event should be fired")
    assert_eq(share_score_score, 100, "event score should match")
    assert_false(share_score_daily, "event daily should be false")

func test_share_score_without_clipboard_feature() -> void:
    # Mock DisplayServer to NOT have clipboard feature
    DisplayServerMock.has_feature_impl = func(feature: int) -> bool:
        return false
    
    clipboard_set_called = false
    
    # Call share_score
    Integrations.share_score(200, true)
    
    # Verify clipboard was NOT called
    assert_false(clipboard_set_called, "clipboard_set should NOT be called when FEATURE_CLIPBOARD is unavailable")
    
    # Verify share_unavailable event was fired
    assert_true(share_unavailable_event_fired, "share_unavailable event should be fired")
    assert_eq(share_unavailable_score, 200, "unavailable event score should match")
    assert_true(share_unavailable_daily, "unavailable event daily should be true")

func test_share_score_daily_mode() -> void:
    # Mock DisplayServer with clipboard feature
    DisplayServerMock.has_feature_impl = func(feature: int) -> bool:
        if feature == DisplayServer.FEATURE_CLIPBOARD:
            return true
        return false
    
    DisplayServerMock.clipboard_set_impl = func(text: String) -> void:
        clipboard_set_called = true
        clipboard_captured_text = text
    
    # Call share_score in daily mode
    Integrations.share_score(500, true)
    
    # Verify correct text format for daily mode
    assert_eq(clipboard_captured_text, "JUMPY DAILY — 500. Beat me. #Jumpy", "daily mode clipboard text should show DAILY")

# Mock state tracking
var clipboard_set_called: bool = false
var clipboard_captured_text: String = ""
var share_score_event_fired: bool = false
var share_score_score: int = 0
var share_score_daily: bool = false
var share_unavailable_event_fired: bool = false
var share_unavailable_score: int = 0
var share_unavailable_daily: bool = false

# Mock DisplayServer implementation for testing
class DisplayServerMock:
    static var has_feature_impl: Callable = func(feature: int) -> bool: return true
    static var clipboard_set_impl: Callable = func(text: String) -> void: pass
    
    static func has_feature(feature: int) -> bool:
        return has_feature_impl.call(feature)
    
    static func clipboard_set(text: String) -> void:
        return clipboard_set_impl.call(text)
    
    static func FEATURE_CLIPBOARD: int = 15

# Override integration events for testing
func event(event_name: String, data: Dictionary) -> void:
    if event_name == "share_score":
        share_score_event_fired = true
        share_score_score = data.get("score", 0)
        share_score_daily = data.get("daily", false)
    elif event_name == "share_unavailable":
        share_unavailable_event_fired = true
        share_unavailable_score = data.get("score", 0)
        share_unavailable_daily = data.get("daily", false)
