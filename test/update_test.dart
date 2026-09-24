import 'package:flutter_test/flutter_test.dart';
import 'package:gleichda/state/updates.dart';

void main() {
  test('Versionen vergleichen', () {
    expect(compareVersions('0.2.0', '0.10.0'), lessThan(0));
    expect(compareVersions('v0.3.0', '0.2.9'), greaterThan(0));
    expect(compareVersions('0.2.0', 'v0.2.0'), 0);
    // Vorabversionen: älter als die fertige Version, untereinander nach Nummer.
    expect(compareVersions('0.4.8-vorab.2', '0.4.8'), lessThan(0));
    expect(compareVersions('0.4.8-vorab.2', '0.4.8-vorab.1'), greaterThan(0));
    expect(compareVersions('0.4.8-vorab.1', '0.4.7'), greaterThan(0));
    expect(compareVersions('0.4.8+12', '0.4.8'), 0);
  });

  test('Vorabversionen nur mit Schalter', () {
    Map<String, dynamic> rel(String tag, {bool pre = false}) => {
          'tag_name': tag,
          'prerelease': pre,
          'assets': [
            {'name': 'Gleich.da-$tag.apk', 'browser_download_url': 'https://example.org/$tag.apk'},
          ],
        };
    final list = [rel('v0.4.9-vorab.1', pre: true), rel('v0.4.8')];
    expect(newestRelease(list, prerelease: false)!.version, '0.4.8');
    expect(newestRelease(list, prerelease: true)!.version, '0.4.9-vorab.1');
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

  test('Versteckter Speicher: keine GitHub-Adresse, Liste wie tool/release.sh sie schreibt', () {
    expect(releasesUrl, '$updateStore/release.json');
    expect(allReleasesUrl, '$updateStore/releases.json');
    expect(updateStore.contains('github'), isFalse);
    final liste = [
      {
        'tag_name': 'v0.5.0', 'draft': false, 'prerelease': false, 'body': 'Neu',
        'assets': [{'name': 'Gleich.da.apk', 'browser_download_url': '$updateStore/Gleich.da.apk', 'size': 70000000}],
      },
      {
        'tag_name': 'v0.5.1-vorab.1', 'draft': false, 'prerelease': true, 'body': 'Vorab',
        'assets': [{'name': 'Gleich.da-vorab.apk', 'browser_download_url': '$updateStore/Gleich.da-vorab.apk', 'size': 70000001}],
      },
    ];
    expect(newestRelease(liste, prerelease: false)!.version, '0.5.0');
    expect(newestRelease(liste, prerelease: true)!.version, '0.5.1-vorab.1');
    expect(newestRelease(liste, prerelease: true)!.size, 70000001);
  });
}
