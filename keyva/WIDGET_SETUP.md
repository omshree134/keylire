# Android widget — manifest & gradle additions

Package assumed `com.keyva.app`. If yours differs, rename the Kotlin package
in `android/app/src/main/kotlin/com/keyva/app/widget/` and the two class
references below.

## AndroidManifest.xml — inside `<application>`

```xml
<!-- Home-screen widget -->
<receiver
    android:name=".widget.KeyvaWidgetProvider"
    android:exported="true"
    android:label="Keyva">
    <intent-filter>
        <action android:name="android.appwidget.action.APPWIDGET_UPDATE" />
    </intent-filter>
    <meta-data
        android:name="android.appwidget.provider"
        android:resource="@xml/widget_keyva_info" />
</receiver>

<!-- home_widget: runs keyvaWidgetBackground() in a headless engine -->
<receiver
    android:name="es.antonborri.home_widget.HomeWidgetBackgroundReceiver"
    android:exported="true">
    <intent-filter>
        <action android:name="es.antonborri.home_widget.action.BACKGROUND" />
    </intent-filter>
</receiver>
<service
    android:name="es.antonborri.home_widget.HomeWidgetBackgroundService"
    android:permission="android.permission.BIND_JOB_SERVICE"
    android:exported="true" />

<!-- The floating capture card. Not a task, no recents entry, no app window. -->
<activity
    android:name=".widget.QuickCaptureActivity"
    android:theme="@style/KeyvaQuickCapture"
    android:excludeFromRecents="true"
    android:noHistory="true"
    android:taskAffinity=""
    android:launchMode="singleInstance"
    android:exported="false"
    android:windowSoftInputMode="stateVisible|adjustResize" />

<!-- Camera output for the widget's photo door -->
<provider
    android:name="androidx.core.content.FileProvider"
    android:authorities="${applicationId}.fileprovider"
    android:exported="false"
    android:grantUriPermissions="true">
    <meta-data
        android:name="android.support.FILE_PROVIDER_PATHS"
        android:resource="@xml/file_paths" />
</provider>
```

Also inside `<application>`'s main `<activity>` (MainActivity), for iOS-style
"open with the door ready" links and the header tap:

```xml
<intent-filter>
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="keyva" />
</intent-filter>
```

Top-level permissions (most are already there via plugins):

```xml
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.CAMERA" />
<queries>
    <intent><action android:name="android.speech.RecognitionService" /></intent>
    <intent><action android:name="android.media.action.IMAGE_CAPTURE" /></intent>
</queries>
```

## android/app/build.gradle(.kts)

```kotlin
dependencies {
    implementation("androidx.core:core-ktx:1.13.1")   // FileProvider
}
```

`minSdk` 26+ (home_widget background needs JobIntentService; ML Kit needs 21+).

## How it behaves

| Tap                     | What happens                                              | App opens? |
|-------------------------|-----------------------------------------------------------|------------|
| Bed / Up / key chip     | broadcast → headless Dart → CaptureService → widget repaint | no |
| ○ ghost chip (due now)  | same, `completePlanned`                                    | no |
| "Log one line…"         | floating card, keyboard up; Done → headless Dart           | no |
| mic                     | floating card → system recogniser → auto-send after 1.8 s | no |
| camera                  | floating card → system camera → ML Kit in headless Dart    | no |
| header (date/last line) | opens Keyva on Today                                       | yes |

Below the auto-assign threshold a line is saved **unfiled** (never lost);
Today shows "unfiled · tap to file". Training mode (first two weeks) means
most widget lines will be unfiled — that's expected; the picker needs the app.

## Testing without the launcher

```
adb shell am broadcast -a es.antonborri.home_widget.action.BACKGROUND \
  -n com.keyva.app/es.antonborri.home_widget.HomeWidgetBackgroundReceiver \
  -d "keyva://widget/text?line=gym%2045%20min"
```
