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
## The constants below use Google's official TEST IDs so integration can be
## verified without a live AdMob account.
## ⚠️  BEFORE PUBLISHING: replace every constant with your real AdMob IDs.
## Real IDs look like:  ca-app-pub-1234567890123456/1234567890
## ─────────────────────────────────────────────────────────────────────────

# ── Ad unit IDs — swap for real IDs before publishing ─────────────────────────
## Android rewarded test ID (replace: ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX)
const AD_UNIT_REWARDED_ANDROID:     String = "ca-app-pub-3940256099942544/5224354917"
## iOS rewarded test ID (replace: ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX)
const AD_UNIT_REWARDED_IOS:         String = "ca-app-pub-3940256099942544/1712485313"
## Android interstitial test ID (replace: ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX)
const AD_UNIT_INTERSTITIAL_ANDROID: String = "ca-app-pub-3940256099942544/1033173712"
## iOS interstitial test ID (replace: ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX)
const AD_UNIT_INTERSTITIAL_IOS:     String = "ca-app-pub-3940256099942544/4411468910"

# ── Signals ───────────────────────────────────────────────────────────────────
## Emitted when a rewarded ad finishes and the reward should be granted.
signal rewarded_ad_completed
## Emitted when a rewarded ad is dismissed without completing (no reward).
signal rewarded_ad_skipped
## Emitted when an interstitial ad closes (used for post-match / between screens).
signal interstitial_closed

# ── Plugin state ──────────────────────────────────────────────────────────────
var _plugin_available: bool = false
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

# ── Fake-ad state (desktop / dev only) ───────────────────────────────────────
const FAKE_AD_DURATION: float = 3.0
var _fake_timer:    float = 0.0
var _showing_fake:  bool  = false
var _fake_rewarded: bool  = false
var _fake_layer: CanvasLayer = null

# ─────────────────────────────────────────────────────────────────────────────

func _ready() -> void:
	_plugin_available = Engine.has_singleton("MobileAds")
	if _plugin_available:
		_init_plugin()
	else:
		push_warning(
			"AdManager: MobileAds singleton not found — running fake ads. " +
			"Install godot-admob-plugin and rebuild the Android/iOS export to enable real ads."
		)

# ── Plugin initialisation ─────────────────────────────────────────────────────

func _init_plugin() -> void:
	Engine.get_singleton("MobileAds").initialize()
	_build_rewarded_callback()
	_build_interstitial_callback()
	_preload_rewarded()
	_preload_interstitial()

func _build_rewarded_callback() -> void:
	# All plugin classes accessed via ClassDB.instantiate() so the script
	# parses cleanly when the plugin is not installed.
	_rewarded_load_cb = ClassDB.instantiate("RewardedAdLoadCallback")
	_rewarded_load_cb.on_ad_failed_to_load = func(error) -> void:
		push_warning("AdManager: rewarded ad failed to load — " + error.message)
	_rewarded_load_cb.on_ad_loaded = func(ad) -> void:
		_rewarded_ad = ad
		var fsc = ClassDB.instantiate("FullScreenContentCallback")
		fsc.on_ad_dismissed_full_screen_content = func() -> void:
			if _reward_earned:
				rewarded_ad_completed.emit()
			else:
				rewarded_ad_skipped.emit()
			_reward_earned = false
			_rewarded_ad   = null
			_preload_rewarded()          # pre-load for next show
		fsc.on_ad_failed_to_show_full_screen_content = func(error) -> void:
			push_warning("AdManager: rewarded ad failed to show — " + error.message)
			rewarded_ad_skipped.emit()
			_rewarded_ad = null
			_preload_rewarded()
		_rewarded_ad.full_screen_content_callback = fsc

func _build_interstitial_callback() -> void:
	_interstitial_load_cb = ClassDB.instantiate("InterstitialAdLoadCallback")
	_interstitial_load_cb.on_ad_failed_to_load = func(error) -> void:
		push_warning("AdManager: interstitial ad failed to load — " + error.message)
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
	var unit_id := AD_UNIT_REWARDED_ANDROID if OS.get_name() == "Android" \
		else AD_UNIT_REWARDED_IOS
	ClassDB.instantiate("RewardedAdLoader").load(unit_id, ClassDB.instantiate("AdRequest"), _rewarded_load_cb)

func _preload_interstitial() -> void:
	var unit_id := AD_UNIT_INTERSTITIAL_ANDROID if OS.get_name() == "Android" \
		else AD_UNIT_INTERSTITIAL_IOS
	ClassDB.instantiate("InterstitialAdLoader").load(unit_id, ClassDB.instantiate("AdRequest"), _interstitial_load_cb)

# ── Public API ────────────────────────────────────────────────────────────────

## Show a rewarded ad. Emits rewarded_ad_completed on success, rewarded_ad_skipped on dismiss.
func show_rewarded_ad() -> void:
	if _plugin_available:
		_show_real_rewarded_ad()
	else:
		_show_fake_ad(true)

## Show an interstitial ad (no reward). Emits interstitial_closed when done.
func show_interstitial_ad() -> void:
	if _plugin_available:
		_show_real_interstitial_ad()
	else:
		_finish_fake_ad(false)

# ── Real ad implementations ───────────────────────────────────────────────────

func _show_real_rewarded_ad() -> void:
	if _rewarded_ad == null:
		push_warning("AdManager: rewarded ad not ready yet — falling back to fake")
		_show_fake_ad(true)
		return
	var listener = ClassDB.instantiate("OnUserEarnedRewardListener")
	# _reward_earned is read by the FullScreenContentCallback dismissal handler.
	listener.on_user_earned_reward = func(_reward) -> void:
		_reward_earned = true
	_rewarded_ad.show(listener)

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
