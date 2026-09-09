package com.keyva.app.widget

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.provider.MediaStore
import android.speech.RecognizerIntent
import android.view.KeyEvent
import android.view.View
import android.view.inputmethod.EditorInfo
import android.view.inputmethod.InputMethodManager
import android.widget.EditText
import android.widget.TextView
import android.widget.Toast
import androidx.core.content.FileProvider
import com.keyva.app.R
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import java.io.File
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * The floating card. Opens over the launcher (dialog theme, dimmed behind),
 * never brings the app forward. Three modes:
 *
 *   text   - keyboard up immediately; Done/send → line goes to Dart.
 *   voice  - system speech recogniser; result lands in the field, sent
 *            automatically after a beat so you can catch a mishear.
 *   camera - system camera; photo saved to cache; path goes to Dart, where
 *            ML Kit describes it. Optional caption from the field.
 *
 * Handing off = one broadcast to HomeWidgetBackgroundIntent. The headless
 * Flutter engine runs CaptureService (parser + matcher + write) and
 * refreshes the widget. This activity is gone before that finishes.
 */
class QuickCaptureActivity : Activity() {

    companion object {
        const val EXTRA_MODE = "mode"
        private const val RC_SPEECH = 41
        private const val RC_CAMERA = 42
    }

    private lateinit var input: EditText
    private lateinit var status: TextView
    private var photoFile: File? = null
    private var mode = "text"

    override fun onCreate(savedInstanceState: Bundle?) {
        setTheme(R.style.KeyvaQuickCapture)
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_quick_capture)
        setFinishOnTouchOutside(true)

        input = findViewById(R.id.input)
        status = findViewById(R.id.status)
        findViewById<TextView>(R.id.eyebrow).text =
            "Keyva · " + SimpleDateFormat("HH:mm", Locale.getDefault()).format(Date())
        findViewById<View>(R.id.btn_send).setOnClickListener { submit() }
        findViewById<View>(R.id.btn_mic).setOnClickListener { startSpeech() }
        input.setOnEditorActionListener { _, actionId, event ->
            if (actionId == EditorInfo.IME_ACTION_DONE ||
                (event?.keyCode == KeyEvent.KEYCODE_ENTER && event.action == KeyEvent.ACTION_DOWN)
            ) { submit(); true } else false
        }

        mode = intent.getStringExtra(EXTRA_MODE) ?: "text"
        when (mode) {
            "voice" -> startSpeech()
            "camera" -> startCamera()
            else -> input.post { showKeyboard() }
        }
    }

    private fun showKeyboard() {
        input.requestFocus()
        (getSystemService(INPUT_METHOD_SERVICE) as InputMethodManager)
            .showSoftInput(input, InputMethodManager.SHOW_IMPLICIT)
    }

    // ------------------------------------------------------------ voice

    private fun startSpeech() {
        val i = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
            putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
            putExtra(RecognizerIntent.EXTRA_PROMPT, "What happened, or what's next?")
            putExtra(RecognizerIntent.EXTRA_MAX_RESULTS, 1)
        }
        try {
            startActivityForResult(i, RC_SPEECH)
        } catch (_: Exception) {
            Toast.makeText(this, "Speech recognition isn't available here", Toast.LENGTH_SHORT).show()
            showKeyboard()
        }
    }

    // ----------------------------------------------------------- camera

    private fun startCamera() {
        val dir = File(cacheDir, "quick_capture").apply { mkdirs() }
        val f = File(dir, "photo_${System.currentTimeMillis()}.jpg")
        photoFile = f
        val uri = FileProvider.getUriForFile(this, "$packageName.fileprovider", f)
        val i = Intent(MediaStore.ACTION_IMAGE_CAPTURE).apply {
            putExtra(MediaStore.EXTRA_OUTPUT, uri)
            addFlags(Intent.FLAG_GRANT_WRITE_URI_PERMISSION)
        }
        try {
            startActivityForResult(i, RC_CAMERA)
        } catch (_: Exception) {
            Toast.makeText(this, "No camera app found", Toast.LENGTH_SHORT).show()
            finish()
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        when (requestCode) {
            RC_SPEECH -> {
                val text = data?.getStringArrayListExtra(RecognizerIntent.EXTRA_RESULTS)?.firstOrNull()
                if (resultCode == RESULT_OK && !text.isNullOrBlank()) {
                    input.setText(text)
                    input.setSelection(text.length)
                    status.text = "Logging in a moment — tap to edit"
                    status.visibility = View.VISIBLE
                    // A beat to catch a mishear; any keystroke cancels auto-send.
                    input.postDelayed({ if (!edited) submit(modality = "voice") }, 1800)
                    input.setOnKeyListener { _, _, _ -> edited = true; false }
                    input.setOnClickListener { edited = true; status.visibility = View.GONE }
                } else if (mode == "voice") {
                    showKeyboard()
                }
            }
            RC_CAMERA -> {
                val f = photoFile
                if (resultCode == RESULT_OK && f != null && f.exists() && f.length() > 0) {
                    send("keyva://widget/photo?path=${Uri.encode(f.absolutePath)}&line=${Uri.encode(input.text.toString().trim())}")
                } else {
                    finish()
                }
            }
        }
    }

    private var edited = false

    // ------------------------------------------------------------ submit

    private fun submit(modality: String = "text") {
        val line = input.text.toString().trim()
        if (line.isEmpty()) { finish(); return }
        send("keyva://widget/text?line=${Uri.encode(line)}&modality=$modality")
    }

    private fun send(uri: String) {
        // Fire the headless isolate and get out of the way.
        HomeWidgetBackgroundIntent.getBroadcast(this, Uri.parse(uri)).send()
        Toast.makeText(this, "Logged", Toast.LENGTH_SHORT).show()
        finish()
        overridePendingTransition(0, android.R.anim.fade_out)
    }
}
