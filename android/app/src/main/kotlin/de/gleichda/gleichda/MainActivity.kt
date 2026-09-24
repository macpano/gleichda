package de.gleichda.gleichda

import android.content.Context
import android.content.Intent
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.view.Surface
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    // Die Flutter-Engine lebt unabhängig vom Fenster: Wischt man die App weg,
    // läuft die Begleitung (Dart-Zeitgeber, GPS) weiter, solange der
    // Vordergrunddienst den Prozess am Leben hält. Beim nächsten Öffnen hängt
    // sich das Fenster wieder an dieselbe Engine – der Zustand ist noch da.
    override fun provideFlutterEngine(context: Context): FlutterEngine {
        FlutterEngineCache.getInstance().get(ENGINE)?.let { return it }
        return FlutterEngine(context.applicationContext).also {
            it.dartExecutor.executeDartEntrypoint(DartExecutor.DartEntrypoint.createDefault())
            FlutterEngineCache.getInstance().put(ENGINE, it)
        }
    }

    override fun shouldDestroyEngineWithHost(): Boolean = false

    companion object {
        private const val ENGINE = "gleichda"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Kompass für die Fußweg-Karte: Blickrichtung in Grad (0 = Norden) aus
        // dem Drehvektor-Sensor, passend zur Bildschirmdrehung.
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, "de.gleichda/compass")
            .setStreamHandler(object : EventChannel.StreamHandler {
                private var listener: SensorEventListener? = null

                override fun onListen(arguments: Any?, sink: EventChannel.EventSink) {
                    val sm = applicationContext.getSystemService(Context.SENSOR_SERVICE) as SensorManager
                    val sensor = sm.getDefaultSensor(Sensor.TYPE_ROTATION_VECTOR)
                    if (sensor == null) {
                        sink.endOfStream()
                        return
                    }
                    val rot = FloatArray(9)
                    val remapped = FloatArray(9)
                    val orientation = FloatArray(3)
                    listener = object : SensorEventListener {
                        override fun onSensorChanged(e: SensorEvent) {
                            SensorManager.getRotationMatrixFromVector(rot, e.values)
                            val rotation = try {
                                @Suppress("DEPRECATION")
                                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) display?.rotation else windowManager.defaultDisplay.rotation
                            } catch (_: Exception) {
                                Surface.ROTATION_0
                            }
                            val (x, y) = when (rotation) {
                                Surface.ROTATION_90 -> SensorManager.AXIS_Y to SensorManager.AXIS_MINUS_X
                                Surface.ROTATION_180 -> SensorManager.AXIS_MINUS_X to SensorManager.AXIS_MINUS_Y
                                Surface.ROTATION_270 -> SensorManager.AXIS_MINUS_Y to SensorManager.AXIS_X
                                else -> SensorManager.AXIS_X to SensorManager.AXIS_Y
                            }
                            SensorManager.remapCoordinateSystem(rot, x, y, remapped)
                            SensorManager.getOrientation(remapped, orientation)
                            sink.success((Math.toDegrees(orientation[0].toDouble()) + 360.0) % 360.0)
                        }

                        override fun onAccuracyChanged(s: Sensor?, accuracy: Int) {}
                    }
                    sm.registerListener(listener, sensor, SensorManager.SENSOR_DELAY_UI)
                }

                override fun onCancel(arguments: Any?) {
                    val sm = applicationContext.getSystemService(Context.SENSOR_SERVICE) as SensorManager
                    listener?.let { sm.unregisterListener(it) }
                    listener = null
                }
            })
        // Selbst-Aktualisierung: die geladene APK dem System-Installer übergeben.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "de.gleichda/update")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "canInstall" -> result.success(canInstall())
                    "openInstallSettings" -> {
                        openInstallSettings()
                        result.success(null)
                    }
                    "install" -> {
                        val path = call.argument<String>("path")
                        if (path == null || !File(path).exists()) {
                            result.error("missing", "APK fehlt", null)
                        } else if (!canInstall()) {
                            openInstallSettings()
                            result.success("permission")
                        } else {
                            install(File(path))
                            result.success("started")
                        }
                    }
                    // App weitergeben: die eigene APK über das Teilen-Menü (WhatsApp, Signal, E-Mail …).
                    // Erstinstallation ohne Download-Link (Nutzerwunsch 24.09.2026).
                    "share" -> {
                        val text = call.argument<String>("text") ?: ""
                        Thread {
                            try {
                                shareSelf(text)
                                runOnUiThread { result.success(null) }
                            } catch (e: Exception) {
                                runOnUiThread { result.error("share", e.message, null) }
                            }
                        }.start()
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun shareSelf(text: String) {
        val version = packageManager.getPackageInfo(packageName, 0).versionName ?: ""
        // Unter files/updates, weil nur dieser Ordner im FileProvider freigegeben ist (res/xml/filepaths.xml).
        val dir = File(filesDir, "updates/weitergeben").apply { mkdirs() }
        dir.listFiles()?.forEach { it.delete() }
        val out = File(dir, "Gleich.da-$version.apk")
        File(applicationInfo.sourceDir).copyTo(out, overwrite = true)
        val uri = FileProvider.getUriForFile(this, "$packageName.updates", out)
        val send = Intent(Intent.ACTION_SEND)
            .setType("application/vnd.android.package-archive")
            .putExtra(Intent.EXTRA_STREAM, uri)
            .putExtra(Intent.EXTRA_TEXT, text)
            .addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        send.clipData = android.content.ClipData.newRawUri("", uri)
        startActivity(
            Intent.createChooser(send, "Gleich.da weitergeben")
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_GRANT_READ_URI_PERMISSION)
        )
    }

    private fun canInstall(): Boolean =
        Build.VERSION.SDK_INT < Build.VERSION_CODES.O || packageManager.canRequestPackageInstalls()

    private fun openInstallSettings() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startActivity(
                Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES, Uri.parse("package:$packageName"))
                    .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            )
        }
    }

    private fun install(apk: File) {
        val uri = FileProvider.getUriForFile(this, "$packageName.updates", apk)
        startActivity(
            Intent(Intent.ACTION_VIEW)
                .setDataAndType(uri, "application/vnd.android.package-archive")
                .addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_ACTIVITY_NEW_TASK)
        )
    }
}
