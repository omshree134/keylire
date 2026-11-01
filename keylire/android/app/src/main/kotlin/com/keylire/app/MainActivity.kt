package com.keylire.app

import android.content.ClipData
import android.content.Intent
import android.graphics.BitmapFactory
import android.net.Uri
import androidx.core.content.ContextCompat
import androidx.core.content.FileProvider
import com.google.mlkit.genai.common.DownloadCallback
import com.google.mlkit.genai.common.FeatureStatus
import com.google.mlkit.genai.common.GenAiException
import com.google.mlkit.genai.imagedescription.ImageDescriber
import com.google.mlkit.genai.imagedescription.ImageDescriberOptions
import com.google.mlkit.genai.imagedescription.ImageDescription
import com.google.mlkit.genai.imagedescription.ImageDescriptionRequest
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.concurrent.Executors
import java.util.concurrent.atomic.AtomicBoolean

class MainActivity : FlutterFragmentActivity() {
    private var imageDescriber: ImageDescriber? = null
    private var backupChannel: MethodChannel? = null
    private val backupIo = Executors.newSingleThreadExecutor()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.keylire.app/image_description",
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "status" -> checkImageDescriptionStatus(result)
                "download" -> downloadImageDescriptionModel(result)
                "describe" -> {
                    val path = call.argument<String>("path")
                    if (path == null) {
                        result.error("bad_path", "No image path supplied", null)
                    } else {
                        describeImage(path, result)
                    }
                }
                else -> result.notImplemented()
            }
        }

        backupChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.keylire.app/backup",
        ).also { channel ->
            channel.setMethodCallHandler { call, result ->
                when (call.method) {
                    "share" -> {
                        val path = call.argument<String>("path")
                        if (path == null) {
                            result.error("bad_path", "No backup path supplied", null)
                        } else {
                            shareBackup(
                                File(path),
                                call.argument<String>("mimeType") ?: "application/octet-stream",
                                result,
                            )
                        }
                    }
                    "takePendingImport" -> {
                        val pendingIntent = intent
                        backupIo.execute {
                            val path = copyBackupFromIntent(pendingIntent)
                            runOnUiThread { result.success(path) }
                        }
                    }
                    else -> result.notImplemented()
                }
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        backupIo.execute {
            val path = copyBackupFromIntent(intent)
            if (path != null) {
                runOnUiThread {
                    backupChannel?.invokeMethod("backupOpened", path)
                }
            }
        }
    }

    private fun shareBackup(
        file: File,
        mimeType: String,
        result: MethodChannel.Result,
    ) {
        if (!file.exists()) {
            result.error("missing_file", "Backup file no longer exists", null)
            return
        }
        try {
            val exportDir = File(cacheDir, "exports").apply { mkdirs() }
            val shareableFile = File(exportDir, file.name)
            file.copyTo(shareableFile, overwrite = true)

            val uri = FileProvider.getUriForFile(
                this,
                "$packageName.fileprovider",
                shareableFile,
            )
            val send = Intent(Intent.ACTION_SEND).apply {
                type = mimeType
                putExtra(Intent.EXTRA_STREAM, uri)
                putExtra(Intent.EXTRA_SUBJECT, "Keylire export: ${file.name}")
                clipData = ClipData.newRawUri(file.name, uri)
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            }
            val chooser = Intent.createChooser(send, "Share Keylire export").apply {
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            }
            startActivity(chooser)
            result.success(null)
        } catch (error: Throwable) {
            result.error("share_failed", error.message ?: "Could not share backup", null)
        }
    }

    private fun isKeylireBackupUri(uri: Uri): Boolean {
        val path = uri.path?.lowercase() ?: ""
        if (path.endsWith(".keylire")) return true
        if (uri.scheme == "content") {
            try {
                contentResolver.query(uri, arrayOf(android.provider.OpenableColumns.DISPLAY_NAME), null, null, null)?.use { cursor ->
                    if (cursor.moveToFirst()) {
                        val name = cursor.getString(0)?.lowercase() ?: ""
                        if (name.endsWith(".keylire")) return true
                    }
                }
            } catch (_: Throwable) {}
        }
        return false
    }

    private fun copyBackupFromIntent(source: Intent?): String? {
        if (source == null) return null
        val uri: Uri = when (source.action) {
            Intent.ACTION_VIEW -> source.data
            Intent.ACTION_SEND -> {
                source.getParcelableExtra<Uri>(Intent.EXTRA_STREAM)
                    ?: source.clipData?.takeIf { it.itemCount > 0 }?.getItemAt(0)?.uri
            }
            else -> null
        } ?: return null

        if (source.action == Intent.ACTION_SEND && !isKeylireBackupUri(uri)) {
            return null
        }

        return try {
            val target = File(cacheDir, "keylire-import-${System.currentTimeMillis()}.keylire")
            val input = when (uri.scheme) {
                "content" -> contentResolver.openInputStream(uri)
                "file" -> uri.path?.let { File(it).inputStream() }
                else -> null
            } ?: return null
            input.use { from -> target.outputStream().use { to -> from.copyTo(to) } }
            source.action = null
            source.data = null
            target.absolutePath
        } catch (_: Throwable) {
            null
        }
    }

    private fun describer(): ImageDescriber {
        val existing = imageDescriber
        if (existing != null) return existing
        return ImageDescription.getClient(ImageDescriberOptions.builder(this).build())
            .also { imageDescriber = it }
    }

    private fun checkImageDescriptionStatus(result: MethodChannel.Result) {
        try {
            val future = describer().checkFeatureStatus()
            future.addListener(
                {
                    try {
                        val value = when (future.get()) {
                            FeatureStatus.DOWNLOADABLE -> "downloadable"
                            FeatureStatus.DOWNLOADING -> "downloading"
                            FeatureStatus.AVAILABLE -> "available"
                            else -> "unavailable"
                        }
                        result.success(value)
                    } catch (_: Throwable) {
                        result.success("unavailable")
                    }
                },
                ContextCompat.getMainExecutor(this),
            )
        } catch (_: Throwable) {
            result.success("unavailable")
        }
    }

    private fun downloadImageDescriptionModel(result: MethodChannel.Result) {
        val completed = AtomicBoolean(false)
        fun successOnce() {
            if (completed.compareAndSet(false, true)) result.success(null)
        }
        fun errorOnce(error: Throwable) {
            if (completed.compareAndSet(false, true)) {
                result.error("model_download", error.message ?: "Model download failed", null)
            }
        }
        try {
            val future = describer().downloadFeature(
                object : DownloadCallback {
                    override fun onDownloadStarted(bytesToDownload: Long) = Unit
                    override fun onDownloadProgress(totalBytesDownloaded: Long) = Unit
                    override fun onDownloadCompleted() = successOnce()
                    override fun onDownloadFailed(e: GenAiException) = errorOnce(e)
                },
            )
            future.addListener(
                {
                    try {
                        future.get()
                        successOnce()
                    } catch (error: Throwable) {
                        errorOnce(error)
                    }
                },
                ContextCompat.getMainExecutor(this),
            )
        } catch (error: Throwable) {
            errorOnce(error)
        }
    }

    private fun describeImage(path: String, result: MethodChannel.Result) {
        val bitmap = BitmapFactory.decodeFile(path)
        if (bitmap == null) {
            result.error("image_decode", "Could not decode the image", null)
            return
        }
        try {
            val request = ImageDescriptionRequest.builder(bitmap).build()
            val future = describer().runInference(request)
            future.addListener(
                {
                    try {
                        result.success(future.get().description)
                    } catch (error: Throwable) {
                        result.error(
                            "image_description",
                            error.message ?: "Image description failed",
                            null,
                        )
                    } finally {
                        bitmap.recycle()
                    }
                },
                ContextCompat.getMainExecutor(this),
            )
        } catch (error: Throwable) {
            bitmap.recycle()
            result.error("image_description", error.message, null)
        }
    }

    override fun onDestroy() {
        imageDescriber?.close()
        imageDescriber = null
        backupChannel?.setMethodCallHandler(null)
        backupChannel = null
        backupIo.shutdown()
        super.onDestroy()
    }
}
