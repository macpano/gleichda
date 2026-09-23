package de.gleichda.gleichda

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.embedding.engine.dart.DartExecutor
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
                    else -> result.notImplemented()
                }
            }
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
