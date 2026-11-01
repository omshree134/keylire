package com.keylire.app.widget

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import com.keylire.app.R
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetPlugin
import org.json.JSONArray
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * Keylire home-screen widget.
 *
 *  - Bed / Up / key chips / due-now ghost: a broadcast to the headless Dart
 *    isolate (HomeWidgetBackgroundIntent). No UI, no app, ~200 ms.
 *  - Camera / mic / "Log one line…": open QuickCaptureActivity, a floating
 *    card over the launcher. It hands the result to the same isolate.
 *
 * Data comes from home_widget SharedPreferences, written by
 * WidgetSyncService in Dart after every change:
 *   kv_last_line, kv_last_time, kv_count, kv_chips (json array of
 *   {id, name, minute?, ghostId?, at?})
 */
class KeylireWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(context: Context, mgr: AppWidgetManager, ids: IntArray) {
        for (id in ids) mgr.updateAppWidget(id, build(context))
    }

    companion object {
        fun refreshAll(context: Context) {
            val mgr = AppWidgetManager.getInstance(context)
            val ids = mgr.getAppWidgetIds(android.content.ComponentName(context, KeylireWidgetProvider::class.java))
            for (id in ids) mgr.updateAppWidget(id, build(context))
        }

        fun build(context: Context): RemoteViews {
            val prefs = HomeWidgetPlugin.getData(context)
            val v = RemoteViews(context.packageName, R.layout.widget_keylire)

            val count = prefs.getInt("kv_count", 0)
            val last = prefs.getString("kv_last_line", null)
            val lastTime = prefs.getString("kv_last_time", null)
            v.setTextViewText(R.id.title, if (count == 0) "Today" else "Today · $count ${if (count == 1) "entry" else "entries"}")
            v.setTextViewText(R.id.last_line, if (last.isNullOrBlank()) "Nothing yet — tap Up" else "${lastTime ?: ""}  $last".trim())
            v.setTextViewText(R.id.now, SimpleDateFormat("HH:mm", Locale.getDefault()).format(Date()))

            // fixed chips
            v.setOnClickPendingIntent(R.id.chip_bed, background(context, "keylire://widget/bed"))
            v.setOnClickPendingIntent(R.id.chip_up, background(context, "keylire://widget/up"))

            // ranked chips
            val slots = intArrayOf(R.id.chip_0, R.id.chip_1, R.id.chip_2, R.id.chip_3)
            val chips = try { JSONArray(prefs.getString("kv_chips", "[]")) } catch (_: Exception) { JSONArray() }
            for ((i, slot) in slots.withIndex()) {
                if (i >= chips.length()) { v.setViewVisibility(slot, View.GONE); continue }
                val c = chips.getJSONObject(i)
                val name = c.optString("name")
                val ghostId = c.optInt("ghostId", -1)
                val at = c.optString("at", "")
                v.setViewVisibility(slot, View.VISIBLE)
                if (ghostId > 0) {
                    v.setTextViewText(slot, if (at.isEmpty()) "○ $name" else "○ $name $at")
                    v.setInt(slot, "setBackgroundResource", R.drawable.bg_pill_ghost)
                    v.setOnClickPendingIntent(slot, background(context, "keylire://widget/ghost?id=$ghostId"))
                } else {
                    v.setTextViewText(slot, name)
                    v.setInt(slot, "setBackgroundResource", R.drawable.bg_pill)
                    v.setOnClickPendingIntent(slot, background(context, "keylire://widget/chip?id=${c.optInt("id")}&name=${Uri.encode(name)}"))
                }
            }

            // doors → floating card
            v.setOnClickPendingIntent(R.id.btn_text, quick(context, "text"))
            v.setOnClickPendingIntent(R.id.btn_mic, quick(context, "voice"))
            v.setOnClickPendingIntent(R.id.btn_camera, quick(context, "camera"))
            v.setOnClickPendingIntent(R.id.header, openApp(context))
            return v
        }

        private fun background(context: Context, uri: String): PendingIntent =
            HomeWidgetBackgroundIntent.getBroadcast(context, Uri.parse(uri))

        private fun quick(context: Context, mode: String): PendingIntent {
            val i = Intent(context, QuickCaptureActivity::class.java).apply {
                putExtra(QuickCaptureActivity.EXTRA_MODE, mode)
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK or Intent.FLAG_ACTIVITY_NO_ANIMATION
            }
            return PendingIntent.getActivity(
                context, mode.hashCode(), i,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
        }

        private fun openApp(context: Context): PendingIntent {
            val i = context.packageManager.getLaunchIntentForPackage(context.packageName)!!
            return PendingIntent.getActivity(context, 99, i, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        }
    }
}
