import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

import 'providers.dart';

/// Neueste Veröffentlichung auf GitHub (öffentliches Repository, kein Token).
const releasesUrl = 'https://api.github.com/repos/macpano/gleich.da/releases/latest';

/// Alle Veröffentlichungen, auch Vorabversionen (Schalter „Vorabversionen
/// erhalten“).
const allReleasesUrl = 'https://api.github.com/repos/macpano/gleich.da/releases?per_page=15';

/// Übergabe an den Android-Installer (MainActivity.kt).
const _channel = MethodChannel('de.gleichda/update');

/// Vergleicht Versionen wie „0.2.0“, „v0.10.1“ und Vorabversionen wie
/// „0.4.8-vorab.2“: negativ, wenn [a] älter ist. Eine Vorabversion ist älter
/// als die gleichnamige fertige Version („0.4.8-vorab.2“ < „0.4.8“).
int compareVersions(String a, String b) {
  ({List<int> core, int? pre}) parse(String v) {
    final clean = v.replaceFirst(RegExp(r'^[vV]'), '').split('+').first;
    final dash = clean.indexOf('-');
    final core = (dash < 0 ? clean : clean.substring(0, dash)).split('.').map((p) => int.tryParse(p) ?? 0).toList();
    final pre = dash < 0 ? null : int.tryParse(RegExp(r'(\d+)$').firstMatch(clean.substring(dash))?.group(1) ?? '') ?? 0;
    return (core: core, pre: pre);
  }

  final x = parse(a), y = parse(b);
  for (var i = 0; i < 3; i++) {
    final d = (i < x.core.length ? x.core[i] : 0) - (i < y.core.length ? y.core[i] : 0);
    if (d != 0) return d;
  }
  if (x.pre == null && y.pre == null) return 0;
  if (x.pre == null) return 1;
  if (y.pre == null) return -1;
  return x.pre!.compareTo(y.pre!);
}

/// Neueste Veröffentlichung aus der Liste `releases` (ohne Entwürfe), auf
/// Wunsch mit Vorabversionen.
UpdateInfo? newestRelease(List<dynamic> releases, {required bool prerelease}) {
  UpdateInfo? best;
  for (final r in releases.whereType<Map<String, dynamic>>()) {
    if (r['draft'] == true) continue;
    if (r['prerelease'] == true && !prerelease) continue;
    final info = UpdateInfo.fromRelease(r);
    if (info == null) continue;
    if (best == null || compareVersions(info.version, best.version) > 0) best = info;
  }
  return best;
}

class UpdateInfo {
  const UpdateInfo({required this.version, required this.apkUrl, this.size, this.notes, this.pageUrl});

  final String version;
  final String apkUrl;

  /// Größe der APK in Bytes laut GitHub; dient zur Prüfung des Downloads.
  final int? size;
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
      size: (apk['size'] as num?)?.toInt(),
      notes: json['body'] as String?,
      pageUrl: json['html_url'] as String?,
    );
  }
}

enum UpdatePhase { idle, checking, upToDate, available, downloading, ready, installing, failed }

class UpdateState {
  const UpdateState({
    required this.current,
    this.phase = UpdatePhase.idle,
    this.latest,
    this.checkedAt,
    this.progress,
    this.error,
    this.apkPath,
  });

  final String current;
  final UpdatePhase phase;
  final UpdateInfo? latest;
  final DateTime? checkedAt;

  /// Download-Fortschritt in Prozent.
  final int? progress;
  final String? error;

  /// Fertig geladene und geprüfte APK der neuesten Version.
  final String? apkPath;

  bool get hasUpdate => latest != null && compareVersions(latest!.version, current) > 0;

  /// Bereit zum Installieren: Die Meldung „Update verfügbar“ erscheint.
  bool get ready => hasUpdate && apkPath != null;

  UpdateState copyWith({
    UpdatePhase? phase,
    UpdateInfo? latest,
    DateTime? checkedAt,
    int? progress,
    String? error,
    String? apkPath,
  }) =>
      UpdateState(
        current: current,
        phase: phase ?? this.phase,
        latest: latest ?? this.latest,
        checkedAt: checkedAt ?? this.checkedAt,
        progress: progress,
        error: error,
        apkPath: apkPath ?? this.apkPath,
      );
}

/// Prüft beim Öffnen und danach alle 6 Stunden, ob es eine neuere Version
/// gibt, und lädt sie gleich im Hintergrund. Erst wenn die APK vollständig
/// da und geprüft ist, erscheint die Meldung „Update verfügbar“; ein Tipp auf
/// „Installieren“ übergibt sie dem Android-Installer (der immer selbst noch
/// einmal fragt).
class UpdateController extends Notifier<UpdateState> {
  Timer? _timer;
  CancelToken? _download;

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

  Future<bool> get _auto async => await ref.read(repositoryProvider).setting('updateAuto') != 'false';

  Future<void> _init() async {
    try {
      final info = await PackageInfo.fromPlatform();
      state = UpdateState(current: info.version);
    } catch (_) {
      return; // Tests ohne Plattform
    }
    if (!Platform.isAndroid) return;
    if (!await _auto) return;
    await check(download: true);
    _timer = Timer.periodic(interval, (_) => check(download: true));
  }

  /// Bei jedem Öffnen der App (auch aus dem Hintergrund) neu abgleichen –
  /// höchstens einmal pro Minute, damit schnelles Hin- und Herwechseln
  /// GitHub nicht mit Anfragen überhäuft.
  Future<void> resume() async {
    if (!await _auto) return;
    final at = state.checkedAt;
    if (at == null || DateTime.now().difference(at) > const Duration(minutes: 1)) {
      await check(download: true);
    } else if (state.phase == UpdatePhase.failed && state.hasUpdate) {
      await download();
    }
  }

  Future<void> check({bool download = false}) async {
    if (state.current.isEmpty ||
        state.phase == UpdatePhase.downloading ||
        state.phase == UpdatePhase.checking) {
      return;
    }
    state = state.copyWith(phase: UpdatePhase.checking);
    try {
      final opts = Options(headers: {'Accept': 'application/vnd.github+json'});
      final dio = ref.read(dioProvider);
      final UpdateInfo? info;
      if (await ref.read(repositoryProvider).setting('updatePrerelease') == 'true') {
        final res = await dio.get<List<dynamic>>(allReleasesUrl, options: opts);
        info = newestRelease(res.data ?? const [], prerelease: true);
      } else {
        final res = await dio.get<Map<String, dynamic>>(releasesUrl, options: opts);
        info = UpdateInfo.fromRelease(res.data ?? const {});
      }
      final next = state.copyWith(latest: info, checkedAt: DateTime.now());
      state = next.copyWith(phase: next.hasUpdate ? UpdatePhase.available : UpdatePhase.upToDate);
    } catch (_) {
      state = state.copyWith(phase: UpdatePhase.failed, error: 'Keine Verbindung zu GitHub', checkedAt: DateTime.now());
      return;
    }
    await _cleanup();
    if (download && state.hasUpdate) await this.download();
  }

  /// Unter Android `files/updates` – dieser Ordner ist im FileProvider
  /// freigegeben (res/xml/filepaths.xml).
  Future<Directory> _dir() async => Directory('${(await getApplicationSupportDirectory()).path}/updates');

  File _fileFor(Directory dir, UpdateInfo info) => File('${dir.path}/gleichda-${info.version}.apk');

  /// Vollständig und wirklich eine APK (ZIP-Kopf „PK“), keine Fehlerseite.
  Future<bool> _valid(File f, UpdateInfo info) async {
    if (!await f.exists()) return false;
    final len = await f.length();
    if (info.size != null && len != info.size) return false;
    if (len < 1024 * 1024) return false;
    final head = await f.openRead(0, 2).first;
    return head.length == 2 && head[0] == 0x50 && head[1] == 0x4B;
  }

  /// Ältere geladene Fassungen entfernen.
  Future<void> _cleanup() async {
    try {
      final dir = await _dir();
      if (!await dir.exists()) return;
      final keep = state.hasUpdate ? _fileFor(dir, state.latest!).path : null;
      await for (final f in dir.list()) {
        if (f is File && f.path != keep) await f.delete();
      }
    } catch (_) {}
  }

  /// Lädt die neueste Fassung im Hintergrund.
  Future<void> download() async {
    final info = state.latest;
    if (info == null || !state.hasUpdate || state.phase == UpdatePhase.downloading) return;
    try {
      final dir = await _dir();
      await dir.create(recursive: true);
      final file = _fileFor(dir, info);
      if (await _valid(file, info)) {
        state = state.copyWith(phase: UpdatePhase.ready, apkPath: file.path);
        return;
      }
      final part = File('${file.path}.part');
      state = state.copyWith(phase: UpdatePhase.downloading, progress: 0);
      _download = CancelToken();
      await ref.read(dioProvider).download(
        info.apkUrl,
        part.path,
        cancelToken: _download,
        options: Options(receiveTimeout: const Duration(minutes: 10)),
        onReceiveProgress: (got, total) {
          if (total <= 0) return;
          final p = (got * 100 / total).floor();
          if (p != state.progress) state = state.copyWith(phase: UpdatePhase.downloading, progress: p);
        },
      );
      if (await file.exists()) await file.delete();
      await part.rename(file.path);
      if (!await _valid(file, info)) {
        await file.delete();
        state = state.copyWith(phase: UpdatePhase.failed, error: 'Download unvollständig, wird erneut versucht.');
        return;
      }
      state = state.copyWith(phase: UpdatePhase.ready, apkPath: file.path);
    } catch (_) {
      state = state.copyWith(phase: UpdatePhase.failed, error: 'Download fehlgeschlagen, wird erneut versucht.');
    }
  }

  /// Übergibt die geladene APK dem Android-Installer; lädt vorher, falls
  /// nötig.
  Future<void> install() async {
    if (state.apkPath == null) {
      await download();
      if (state.apkPath == null) return;
    }
    try {
      final r = await _channel.invokeMethod<String>('install', {'path': state.apkPath});
      state = r == 'permission'
          ? state.copyWith(
              phase: UpdatePhase.ready,
              error: 'Bitte „Apps aus dieser Quelle zulassen“ einschalten und dann erneut auf Installieren tippen.')
          : state.copyWith(phase: UpdatePhase.installing);
    } on PlatformException catch (e) {
      state = state.copyWith(phase: UpdatePhase.failed, error: 'Installation nicht möglich (${e.message}).');
    }
  }

  Future<void> setAuto(bool on) async {
    await ref.read(repositoryProvider).setSetting('updateAuto', '$on');
    _timer?.cancel();
    if (on) {
      await check(download: true);
      _timer = Timer.periodic(interval, (_) => check(download: true));
    }
  }
}

final updateProvider = NotifierProvider<UpdateController, UpdateState>(UpdateController.new);

/// Vorabversionen erhalten (Zwischenstände, nicht für alle gedacht).
final updatePrereleaseProvider = StreamProvider<bool>(
    (ref) => ref.watch(repositoryProvider).watchSetting('updatePrerelease').map((v) => v == 'true'));

final updateAutoProvider = StreamProvider<bool>(
    (ref) => ref.watch(repositoryProvider).watchSetting('updateAuto').map((v) => v != 'false'));
