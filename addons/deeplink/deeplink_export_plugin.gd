extends EditorExportPlugin

func _supports_platform(platform: EditorExportPlatform) -> bool:
	return platform is EditorExportPlatformAndroid

## Injects the capydungeon:// intent-filter into the <activity> element
## so Android routes OAuth deep-link callbacks back to the app.
func _get_android_manifest_activity_element_contents(
		_platform: EditorExportPlatform, _debug: bool) -> String:
	return """
		<intent-filter>
			<action android:name="android.intent.action.VIEW" />
			<category android:name="android.intent.category.DEFAULT" />
			<category android:name="android.intent.category.BROWSABLE" />
			<data android:scheme="capydungeon" android:host="auth" />
		</intent-filter>
"""
