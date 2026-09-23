import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ota_update/ota_update.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'providers.dart';

/// Neueste Veröffentlichung auf GitHub (öffentliches Repository, kein Token).
const releasesUrl = 'https://api.github.com/repos/macpano/gleichda/releases/latest';

/// Vergleicht Versionen wie „0.2.0“ und „v0.10.1“: negativ, wenn [a] älter ist.
int compareVersions(String a, String b) {
  List<int> parts(String v) => v
      .replaceFirst(RegExp(r'^[vV]'), '')
      .split(RegExp(r'[.+-]'))
      .map((p) => int.tryParse(p) ?? 0)
      .toList();
  final x = parts(a), y = parts(b);
  for (var i = 0; i < 3; i++) {
    final d = (i < x.length ? x[i] : 0) - (i < y.length ? y[i] : 0);
    if (d != 0) return d;
  }
  return 0;
}

class UpdateInfo {
  const UpdateInfo({required this.version, required this.apkUrl, this.notes, this.pageUrl});

  final String version;
  final String apkUrl;
  final String? notes;
  final String? pageUrl;

  /// Aus der Antwort von `releases/latest`; null ohne APK-Anhang.
  static UpdateInfo? fromRelease(Map<String, dynamic> json) {
    final tag = json['tag_name'] as String?;
    final assets = (json['assets'] as List?)?.whereType<Map>() ?? const [];
    final apk = assets.where((a) => (a['name'] as String? ?? '').endsWith('.apk')).firstOrNull;
    if (tag == null || apk == null) return null;
    return UpdateInfo(
      version: tag.replaceFirst(RegExp(r'^[vV]'), ''),
      apkUrl: apk['browser_download_url'] as String,
      notes: json['body'] as String?,
      pageUrl: json['html_url'] as String?,
    );
  }
}

enum UpdatePhase { idle, checking, upToDate, available, downloading, installing, failed }

class UpdateState {
  const UpdateState({
    required this.current,
    this.phase = UpdatePhase.idle,
    this.latest,
    this.checkedAt,
    this.progress,
    this.error,
  });

  final String current;
  final UpdatePhase phase;
  final UpdateInfo? latest;
  final DateTime? checkedAt;

  /// Download-Fortschritt in Prozent.
  final int? progress;
  final String? error;

  bool get hasUpdate => latest != null && compareVersions(latest!.version, current) > 0;

  UpdateState copyWith({
    UpdatePhase? phase,
    UpdateInfo? latest,
    DateTime? checkedAt,
    int? progress,
    String? error,
  }) =>
      UpdateState(
        current: current,
        phase: phase ?? this.phase,
        latest: latest ?? this.latest,
        checkedAt: checkedAt ?? this.checkedAt,
        progress: progress,
        error: error,
      );
}

/// Prüft beim Start und danach alle 6 Stunden, ob es eine neuere Version
/// gibt. Einspielen nur auf Tipp: Die APK wird geladen und dem
/// Android-Installer übergeben.
class UpdateController extends Notifier<UpdateState> {
  Timer? _timer;
  StreamSubscription<OtaEvent>? _download;

  static const interval = Duration(hours: 6);

  @override
  UpdateState build() {
    ref.onDispose(() {
      _timer?.cancel();
      _download?.cancel();
    });
    Future.microtask(_init);
    return const UpdateState(current: '');
  }

  Future<void> _init() async {
    try {
      final info = await PackageInfo.fromPlatform();
      state = UpdateState(current: info.version);
    } catch (_) {
      return; // Tests ohne Plattform
    }
    if (!Platform.isAndroid) return;
    final auto = await ref.read(repositoryProvider).setting('updateAuto');
    if (auto == 'false') return;
    await check();
    _timer = Timer.periodic(interval, (_) => check());
  }

  /// Nach längerer Pause im Hintergrund erneut prüfen.
  void resume() {
    final at = state.checkedAt;
    if (at != null && DateTime.now().difference(at) > interval) check();
  }

  Future<void> check() async {
    if (state.current.isEmpty || state.phase == UpdatePhase.downloading) return;
    state = state.copyWith(phase: UpdatePhase.checking);
    try {
      final res = await ref.read(dioProvider).get<Map<String, dynamic>>(
            releasesUrl,
            options: Options(headers: {'Accept': 'application/vnd.github+json'}),
          );
      final info = UpdateInfo.fromRelease(res.data ?? const {});
      final next = state.copyWith(latest: info, checkedAt: DateTime.now());
      state = next.copyWith(phase: next.hasUpdate ? UpdatePhase.available : UpdatePhase.upToDate);
    } catch (_) {
      state = state.copyWith(phase: UpdatePhase.failed, error: 'Keine Verbindung zu GitHub', checkedAt: DateTime.now());
    }
  }

  void install() {
    final info = state.latest;
    if (info == null) return;
    _download?.cancel();
    state = state.copyWith(phase: UpdatePhase.downloading, progress: 0);
    try {
      _download = OtaUpdate()
          .execute(info.apkUrl, destinationFilename: 'gleichda-${info.version}.apk')
          .listen((e) {
        switch (e.status) {
          case OtaStatus.DOWNLOADING:
            state = state.copyWith(phase: UpdatePhase.downloading, progress: int.tryParse(e.value ?? ''));
          case OtaStatus.INSTALLING:
          case OtaStatus.INSTALLATION_DONE:
            state = state.copyWith(phase: UpdatePhase.installing);
          default:
            state = state.copyWith(
              phase: UpdatePhase.failed,
              error: e.status == OtaStatus.PERMISSION_NOT_GRANTED_ERROR
                  ? 'Installation nicht erlaubt. Bitte „Unbekannte Apps installieren“ für Gleichda zulassen.'
                  : 'Aktualisierung fehlgeschlagen (${e.status.name}).',
            );
        }
      }, onError: (Object _) {
        state = state.copyWith(phase: UpdatePhase.failed, error: 'Download fehlgeschlagen.');
      });
    } catch (_) {
      state = state.copyWith(phase: UpdatePhase.failed, error: 'Aktualisierung nicht möglich.');
    }
  }

  Future<void> setAuto(bool on) async {
    await ref.read(repositoryProvider).setSetting('updateAuto', '$on');
    _timer?.cancel();
    if (on) {
      await check();
      _timer = Timer.periodic(interval, (_) => check());
    }
  }
}

final updateProvider = NotifierProvider<UpdateController, UpdateState>(UpdateController.new);

final updateAutoProvider = StreamProvider<bool>(
    (ref) => ref.watch(repositoryProvider).watchSetting('updateAuto').map((v) => v != 'false'));
