class_name AdManager
extends Node

## Centralised ad manager for Capy Dungeon.
##
## ── Plugin ─────────────────────────────────────────────────────────────────
## Uses poingstudios/godot-admob-plugin (MobileAds singleton).
## Install via Godot Asset Store (search "AdMob" by Poing Studios) or:
##   https://github.com/poingstudios/godot-admob-plugin
## After installing, enable in Project → Project Settings → Plugins, then
## add your AdMob App ID in Project Settings → General → Admob → Android/iOS.
##
## ── Ad unit IDs ────────────────────────────────────────────────────────────
## Debug exports use Google's official test units. Release exports use the
## production units below, so development never depends on live-ad inventory.
## Real IDs look like: ca-app-pub-1234567890123456/1234567890
## ─────────────────────────────────────────────────────────────────────────

const TEST_REWARDED_ANDROID: String = "ca-app-pub-3940256099942544/5224354917"
const TEST_REWARDED_IOS: String = "ca-app-pub-3940256099942544/1712485313"
const TEST_INTERSTITIAL_ANDROID: String = "ca-app-pub-3940256099942544/1033173712"
const TEST_INTERSTITIAL_IOS: String = "ca-app-pub-3940256099942544/4411468910"

# Keep true while testing internal/debug builds. Set false before public release.
const FORCE_TEST_ADS: bool = true
const NATIVE_ADMOB_SINGLETON: StringName = &"PoingGodotAdMob"

const AD_UNIT_REWARDED_ANDROID: String = "ca-app-pub-9375037645592356/8574160982"
const AD_UNIT_REWARDED_IOS: String = "ca-app-pub-9375037645592356/7548067502"
const AD_UNIT_INTERSTITIAL_ANDROID: String = "ca-app-pub-9375037645592356/2200324324"
const AD_UNIT_INTERSTITIAL_IOS: String = "ca-app-pub-9375037645592356/4808976683"

# ── Signals ───────────────────────────────────────────────────────────────────
## Emitted when a rewarded ad finishes and the reward should be granted.
signal rewarded_ad_completed
## Emitted when a rewarded ad is dismissed without completing (no reward).
signal rewarded_ad_skipped
## Emitted when a rewarded ad has finished loading and is ready.
signal rewarded_ad_loaded
## Emitted when rewarded ad cannot be loaded or shown.
signal rewarded_ad_unavailable
## Emitted when an interstitial ad closes (used for post-match / between screens).
signal interstitial_closed

# ── Plugin state ──────────────────────────────────────────────────────────────
var _plugin_available: bool = false
var _can_simulate_ads: bool = false
## Loaded RewardedAd instance (null while loading / not yet preloaded).
var _rewarded_ad    = null
## Loaded InterstitialAd instance.
var _interstitial_ad = null
## Set to true by the OnUserEarnedRewardListener so the dismissal handler
## knows whether to emit rewarded_ad_completed or rewarded_ad_skipped.
var _reward_earned: bool = false
## Re-usable load callbacks (created once in _ready, never replaced).
var _rewarded_load_cb     = null
var _interstitial_load_cb = null
var _rewarded_retry_timer: Timer = null
var _interstitial_retry_timer: Timer = null
var _rewarded_request_timeout: Timer = null
var _rewarded_loading: bool = false
var _rewarded_show_pending: bool = false
var _rewarded_show_in_progress: bool = false
var _reward_listener = null
var _mobile_ads_initialized: bool = false
var _mobile_ads_init_watchdog: Timer = null

# ── Fake-ad state (desktop / dev only) ───────────────────────────────────────
const FAKE_AD_DURATION: float = 3.0
var _fake_timer:    float = 0.0
var _showing_fake:  bool  = false
var _fake_rewarded: bool  = false
var _fake_layer: CanvasLayer = null

# ─────────────────────────────────────────────────────────────────────────────

func _ready() -> void:
	_plugin_available = Engine.has_singleton(NATIVE_ADMOB_SINGLETON)
	print("AdManager: startup platform=%s debug=%s native_singleton=%s available=%s force_test=%s" % [OS.get_name(), OS.is_debug_build(), NATIVE_ADMOB_SINGLETON, _plugin_available, FORCE_TEST_ADS])
	_can_simulate_ads = OS.has_feature("editor") or OS.get_name() in ["Windows", "macOS", "Linux"]
	_rewarded_retry_timer = Timer.new()
	_rewarded_retry_timer.one_shot = true
	_rewarded_retry_timer.wait_time = 10.0
	_rewarded_retry_timer.timeout.connect(_preload_rewarded)
	add_child(_rewarded_retry_timer)

	_interstitial_retry_timer = Timer.new()
	_interstitial_retry_timer.one_shot = true
	_interstitial_retry_timer.wait_time = 10.0
	_interstitial_retry_timer.timeout.connect(_preload_interstitial)
	add_child(_interstitial_retry_timer)

	_rewarded_request_timeout = Timer.new()
	_rewarded_request_timeout.one_shot = true
	_rewarded_request_timeout.wait_time = 12.0
	_rewarded_request_timeout.timeout.connect(_on_rewarded_request_timeout)
	add_child(_rewarded_request_timeout)

	_mobile_ads_init_watchdog = Timer.new()
	_mobile_ads_init_watchdog.one_shot = true
	_mobile_ads_init_watchdog.wait_time = 4.0
	_mobile_ads_init_watchdog.timeout.connect(_on_mobile_ads_init_watchdog_timeout)
	add_child(_mobile_ads_init_watchdog)

	if _plugin_available:
		_init_plugin()
	else:
		push_warning(
			"AdManager: native singleton '%s' not found; MobileAds is not available in this export. " % NATIVE_ADMOB_SINGLETON +
			"Fake ads are enabled only in editor/desktop simulation mode."
		)

# ── Plugin initialisation ─────────────────────────────────────────────────────

func _init_plugin() -> void:
	var mobile_ads := Engine.get_singleton(NATIVE_ADMOB_SINGLETON)
	if mobile_ads == null:
		push_warning("AdManager: native AdMob singleton became unavailable during initialization.")
		return
	print("AdManager: initializing Google Mobile Ads SDK")
	var init_callback := Callable(self, "_on_native_mobile_ads_initialized")
	if mobile_ads.has_signal("on_initialization_complete") and not mobile_ads.is_connected("on_initialization_complete", init_callback):
		mobile_ads.connect("on_initialization_complete", init_callback, CONNECT_ONE_SHOT)
	mobile_ads.initialize()
	if _mobile_ads_init_watchdog != null:
		_mobile_ads_init_watchdog.start()

func _on_native_mobile_ads_initialized(status: Dictionary = {}) -> void:
	print("AdManager: Google Mobile Ads SDK initialization completed; adapters=%d" % status.size())
	_on_mobile_ads_initialized()

func _on_mobile_ads_initialized() -> void:
	if _mobile_ads_initialized:
		return
	_mobile_ads_initialized = true
	if _mobile_ads_init_watchdog != null:
		_mobile_ads_init_watchdog.stop()
	print("AdManager: building callbacks and preloading ads")
	_build_rewarded_callback()
	_build_interstitial_callback()
	_preload_rewarded()
	_preload_interstitial()

func _on_mobile_ads_init_watchdog_timeout() -> void:
	if _mobile_ads_initialized:
		return
	push_warning("AdManager: Mobile Ads initialization callback timed out after 4s; attempting guarded preload.")
	_on_mobile_ads_initialized()

func _build_rewarded_callback() -> void:
	# All plugin classes accessed via ClassDB.instantiate() so the script
	# parses cleanly when the plugin is not installed.
	_rewarded_load_cb = ClassDB.instantiate("RewardedAdLoadCallback")
	if _rewarded_load_cb == null:
		push_warning("AdManager: RewardedAdLoadCallback class is unavailable.")
		return

	_rewarded_load_cb.on_ad_failed_to_load = func(error) -> void:
		_rewarded_loading = false
		_rewarded_ad = null
		var message: String = str(error.message)
		push_warning("AdManager: rewarded load failed unit=%s error=%s" % [_get_rewarded_unit_id(), message])
		if _rewarded_show_pending:
			_rewarded_show_pending = false
			_stop_rewarded_request_timeout()
			rewarded_ad_unavailable.emit()
		if _rewarded_retry_timer != null and _rewarded_retry_timer.is_stopped():
			_rewarded_retry_timer.start()

	_rewarded_load_cb.on_ad_loaded = func(loaded_ad) -> void:
		_rewarded_loading = false
		_rewarded_ad = loaded_ad
		print("AdManager: rewarded ad loaded unit=%s" % _get_rewarded_unit_id())
		var fsc = ClassDB.instantiate("FullScreenContentCallback")
		if fsc == null:
			push_warning("AdManager: FullScreenContentCallback class is unavailable.")
			_rewarded_ad = null
			if _rewarded_show_pending:
				_rewarded_show_pending = false
				_stop_rewarded_request_timeout()
				rewarded_ad_unavailable.emit()
			return

		fsc.on_ad_dismissed_full_screen_content = func() -> void:
			print("AdManager: rewarded ad dismissed reward_earned=%s" % _reward_earned)
			_rewarded_show_in_progress = false
			_reward_listener = null
			if _reward_earned:
				rewarded_ad_completed.emit()
			else:
				rewarded_ad_skipped.emit()
			_reward_earned = false
			_rewarded_ad = null
			_preload_rewarded()

		fsc.on_ad_failed_to_show_full_screen_content = func(error) -> void:
			_rewarded_show_in_progress = false
			_reward_listener = null
			push_warning("AdManager: rewarded show failed error=%s" % str(error.message))
			rewarded_ad_unavailable.emit()
			_rewarded_ad = null
			_preload_rewarded()

		_rewarded_ad.full_screen_content_callback = fsc
		rewarded_ad_loaded.emit()

		# A user may tap before preload finishes. Show automatically as soon as
		# the SDK returns a loaded ad instead of leaving the UI spinning.
		if _rewarded_show_pending:
			_rewarded_show_pending = false
			_stop_rewarded_request_timeout()
			call_deferred("_show_real_rewarded_ad")

func _build_interstitial_callback() -> void:
	_interstitial_load_cb = ClassDB.instantiate("InterstitialAdLoadCallback")
	_interstitial_load_cb.on_ad_failed_to_load = func(error) -> void:
		push_warning("AdManager: interstitial ad failed to load — " + error.message)
		if _interstitial_retry_timer != null and _interstitial_retry_timer.is_stopped():
			_interstitial_retry_timer.start()
	_interstitial_load_cb.on_ad_loaded = func(ad) -> void:
		_interstitial_ad = ad
		var fsc = ClassDB.instantiate("FullScreenContentCallback")
		fsc.on_ad_dismissed_full_screen_content = func() -> void:
			interstitial_closed.emit()
			_interstitial_ad = null
			_preload_interstitial()      # pre-load for next show
		fsc.on_ad_failed_to_show_full_screen_content = func(error) -> void:
			push_warning("AdManager: interstitial ad failed to show — " + error.message)
			interstitial_closed.emit()
			_interstitial_ad = null
			_preload_interstitial()
		_interstitial_ad.full_screen_content_callback = fsc

func _preload_rewarded() -> void:
	if not _plugin_available or not _mobile_ads_initialized or _rewarded_ad != null or _rewarded_loading:
		return
	if _rewarded_load_cb == null:
		if _rewarded_show_pending:
			_rewarded_show_pending = false
			_stop_rewarded_request_timeout()
			rewarded_ad_unavailable.emit()
		return

	var loader = ClassDB.instantiate("RewardedAdLoader")
	var request = ClassDB.instantiate("AdRequest")
	if loader == null or request == null:
		push_warning("AdManager: rewarded ad plugin classes are unavailable.")
		if _rewarded_show_pending:
			_rewarded_show_pending = false
			_stop_rewarded_request_timeout()
			rewarded_ad_unavailable.emit()
		return

	_rewarded_loading = true
	var unit_id := _get_rewarded_unit_id()
	print("AdManager: loading rewarded ad unit=%s test=%s" % [unit_id, FORCE_TEST_ADS or OS.is_debug_build()])
	loader.load(unit_id, request, _rewarded_load_cb)

func _preload_interstitial() -> void:
	if not _plugin_available or not _mobile_ads_initialized:
		return
	if _interstitial_load_cb == null:
		return
	var loader = ClassDB.instantiate("InterstitialAdLoader")
	var request = ClassDB.instantiate("AdRequest")
	if loader == null or request == null:
		push_warning("AdManager: interstitial ad plugin classes are unavailable.")
		return
	var unit_id := _get_interstitial_unit_id()
	loader.load(unit_id, request, _interstitial_load_cb)

func _get_rewarded_unit_id() -> String:
	if FORCE_TEST_ADS or OS.is_debug_build():
		return TEST_REWARDED_ANDROID if OS.get_name() == "Android" else TEST_REWARDED_IOS
	if OS.get_name() == "Android":
		return AD_UNIT_REWARDED_ANDROID
	var configured := str(ProjectSettings.get_setting("ad_units/ios/rewarded_unit_id", ""))
	if configured.is_empty():
		# Backward compatibility with older project setting key.
		configured = str(ProjectSettings.get_setting("admob/ios/rewarded_unit_id", ""))
	return configured if not configured.is_empty() else AD_UNIT_REWARDED_IOS

func _get_interstitial_unit_id() -> String:
	if FORCE_TEST_ADS or OS.is_debug_build():
		return TEST_INTERSTITIAL_ANDROID if OS.get_name() == "Android" else TEST_INTERSTITIAL_IOS
	if OS.get_name() == "Android":
		return AD_UNIT_INTERSTITIAL_ANDROID
	var configured := str(ProjectSettings.get_setting("ad_units/ios/interstitial_unit_id", ""))
	if configured.is_empty():
		# Backward compatibility with older project setting key.
		configured = str(ProjectSettings.get_setting("admob/ios/interstitial_unit_id", ""))
	return configured if not configured.is_empty() else AD_UNIT_INTERSTITIAL_IOS

# ── Public API ────────────────────────────────────────────────────────────────

## Show a rewarded ad. Emits rewarded_ad_completed on success, rewarded_ad_skipped on dismiss.
func show_rewarded_ad() -> void:
	print("AdManager: rewarded show requested plugin=%s initialized=%s loaded=%s loading=%s" % [_plugin_available, _mobile_ads_initialized, _rewarded_ad != null, _rewarded_loading])
	if _plugin_available:
		if _rewarded_show_in_progress or _rewarded_show_pending:
			return
		if _rewarded_ad != null:
			_show_real_rewarded_ad()
		else:
			_rewarded_show_pending = true
			_start_rewarded_request_timeout()
			_preload_rewarded()
	elif _can_simulate_ads:
		if not _showing_fake:
			_show_fake_ad(true)
	else:
		rewarded_ad_unavailable.emit()

## Show an interstitial ad (no reward). Emits interstitial_closed when done.
func show_interstitial_ad() -> void:
	if _plugin_available:
		_show_real_interstitial_ad()
	elif _can_simulate_ads:
		if not _showing_fake:
			_show_fake_ad(false)
	else:
		interstitial_closed.emit()

# ── Real ad implementations ───────────────────────────────────────────────────

func _show_real_rewarded_ad() -> void:
	if _rewarded_ad == null:
		# This can happen if the loaded ad expired between readiness check and show.
		_rewarded_show_pending = true
		_start_rewarded_request_timeout()
		_preload_rewarded()
		return
	if _rewarded_retry_timer != null:
		_rewarded_retry_timer.stop()

	_rewarded_show_in_progress = true
	_reward_earned = false
	print("AdManager: showing rewarded ad unit=%s" % _get_rewarded_unit_id())
	_reward_listener = ClassDB.instantiate("OnUserEarnedRewardListener")
	if _reward_listener == null:
		_rewarded_show_in_progress = false
		push_warning("AdManager: OnUserEarnedRewardListener class is unavailable.")
		rewarded_ad_unavailable.emit()
		return

	# _reward_earned is read by the FullScreenContentCallback dismissal handler.
	_reward_listener.on_user_earned_reward = func(reward) -> void:
		_reward_earned = true
		print("AdManager: reward earned amount=%s type=%s" % [str(reward.amount), str(reward.type)])
	_rewarded_ad.show(_reward_listener)

func is_rewarded_ready() -> bool:
	if _can_simulate_ads and not _plugin_available:
		return true
	return _rewarded_ad != null

func request_rewarded_ad() -> void:
	_preload_rewarded()

func _start_rewarded_request_timeout() -> void:
	if _rewarded_request_timeout != null:
		_rewarded_request_timeout.start()

func _stop_rewarded_request_timeout() -> void:
	if _rewarded_request_timeout != null:
		_rewarded_request_timeout.stop()

func _on_rewarded_request_timeout() -> void:
	if not _rewarded_show_pending:
		return
	_rewarded_show_pending = false
	push_warning("AdManager: rewarded ad request timed out.")
	rewarded_ad_unavailable.emit()

func _show_real_interstitial_ad() -> void:
	if _interstitial_ad == null:
		push_warning("AdManager: interstitial ad not ready yet — emitting closed immediately")
		interstitial_closed.emit()
		return
	_interstitial_ad.show()

# ── Fake-ad implementations (desktop / dev) ───────────────────────────────────

func _process(delta: float) -> void:
	if not _showing_fake:
		return
	_fake_timer -= delta
	if _fake_layer != null:
		var lbl := _fake_layer.get_node_or_null("countdown")
		if lbl != null:
			(lbl as Label).text = "Ad closes in %d…" % maxi(1, int(ceil(_fake_timer)))
	if _fake_timer <= 0.0:
		_finish_fake_ad(true)

func _show_fake_ad(is_rewarded: bool) -> void:
	_showing_fake  = true
	_fake_rewarded = is_rewarded
	_fake_timer    = FAKE_AD_DURATION

	_fake_layer = CanvasLayer.new()
	_fake_layer.layer = 128
	get_tree().current_scene.add_child(_fake_layer)

	var view: Vector2 = get_viewport().get_visible_rect().size

	var bg := ColorRect.new()
	bg.color = Color(0.0, 0.0, 0.0, 0.92)
	bg.size  = view
	_fake_layer.add_child(bg)

	var title := Label.new()
	title.name = "title"
	title.text = "📺  Watching Ad…"
	title.add_theme_font_size_override("font_size", 42)
	title.add_theme_color_override("font_color", Color(0.98, 0.88, 0.30))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(0, view.y * 0.32); title.size = Vector2(view.x, 60)
	_fake_layer.add_child(title)

	var sub := Label.new()
	sub.text = "(Dev mode — simulated ad)"
	sub.add_theme_font_size_override("font_size", 22)
	sub.add_theme_color_override("font_color", Color(0.55, 0.55, 0.55))
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.position = Vector2(0, view.y * 0.32 + 64); sub.size = Vector2(view.x, 36)
	_fake_layer.add_child(sub)

	var countdown := Label.new()
	countdown.name = "countdown"
	countdown.text = "Ad closes in %d…" % int(ceil(_fake_timer))
	countdown.add_theme_font_size_override("font_size", 28)
	countdown.add_theme_color_override("font_color", Color(0.70, 0.70, 0.70))
	countdown.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	countdown.position = Vector2(0, view.y * 0.55); countdown.size = Vector2(view.x, 44)
	_fake_layer.add_child(countdown)

func _finish_fake_ad(earned_reward: bool) -> void:
	_showing_fake = false
	_fake_timer   = 0.0
	if _fake_layer != null:
		_fake_layer.queue_free()
		_fake_layer = null
	if _fake_rewarded:
		if earned_reward:
			rewarded_ad_completed.emit()
		else:
			rewarded_ad_skipped.emit()
	else:
		interstitial_closed.emit()
