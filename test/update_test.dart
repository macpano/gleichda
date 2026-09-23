import 'package:flutter_test/flutter_test.dart';
import 'package:gleichda/state/updates.dart';

void main() {
  test('Versionen vergleichen', () {
    expect(compareVersions('0.2.0', '0.10.0'), lessThan(0));
    expect(compareVersions('v0.3.0', '0.2.9'), greaterThan(0));
    expect(compareVersions('0.2.0', 'v0.2.0'), 0);
  });

  test('Release mit APK wird erkannt, ohne APK nicht', () {
    final info = UpdateInfo.fromRelease({
      'tag_name': 'v0.3.0',
      'body': 'Neu',
      'assets': [
        {'name': 'gleichda-0.3.0.apk', 'browser_download_url': 'https://example.org/a.apk', 'size': 72338579},
      ],
    })!;
    expect(info.version, '0.3.0');
    expect(info.apkUrl, endsWith('.apk'));
    expect(info.size, 72338579);
    expect(UpdateInfo.fromRelease({'tag_name': 'v1', 'assets': []}), isNull);
    final s = const UpdateState(current: '0.2.0').copyWith(latest: info);
    expect(s.hasUpdate, isTrue);
    // Die Meldung erscheint erst, wenn die APK geladen ist.
    expect(s.ready, isFalse);
    expect(s.copyWith(apkPath: '/x/gleichda-0.3.0.apk').ready, isTrue);
  });
}
