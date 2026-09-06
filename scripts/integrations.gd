extends Node

# Central integration boundary. Core gameplay never depends on an external SDK.
# Replace the internals when production plugins are installed; see SETUP_REQUIRED.txt.

func event(name: String, params: Dictionary = {}) -> void:
	print("[analytics] ", name, " ", params)

func haptic(duration_ms: int = 22) -> void:
	if bool(Profile.data.haptics) and OS.has_feature("mobile"):
		Input.vibrate_handheld(duration_ms)

func rewarded_available(_placement: String) -> bool:
	return false

func show_rewarded(_placement: String, callback: Callable) -> void:
	# Development fallback deliberately grants nothing automatically.
	if callback.is_valid():
		callback.call(false)

func share_score(score: int, daily: bool = false) -> void:
	var mode := "DAILY" if daily else "RUN"
	var text := "JUMPY %s — %d. Beat me. #Jumpy" % [mode, score]
	DisplayServer.clipboard_set(text)
	# Native Android/iOS share sheet is optional. Clipboard fallback always works.
	event("share_score", {"score": score, "daily": daily})

func leaderboard_submit(score: int, daily: bool = false) -> void:
	# No-op until Play Games/Game Center is configured.
	event("leaderboard_submit_local", {"score": score, "daily": daily})
