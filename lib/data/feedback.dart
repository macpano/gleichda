import 'dart:convert';

import 'package:dio/dio.dart';

import 'transit_provider.dart' show ProviderException;

/// Kennung beim Formulardienst FormSubmit (https://formsubmit.co): eine
/// zufällige Zeichenfolge, die FormSubmit nach der einmaligen Bestätigung
/// vergibt. Sie ersetzt die Empfängeradresse – die Adresse selbst steht
/// weder in der App noch im öffentlichen Quelltext. Leer = noch nicht
/// eingerichtet; dann lässt sich nichts senden.
const feedbackEndpoint = '3fd5b4a000f7c070296a9963c8c4d658';

enum FeedbackKind {
  feature('Funktion vorschlagen', 'Vorschlag'),
  bug('Fehler melden', 'Fehler');

  const FeedbackKind(this.title, this.subject);

  final String title;
  final String subject;
}

/// Schickt eine Rückmeldung an den Entwickler (per E-Mail über FormSubmit).
class FeedbackSender {
  FeedbackSender(this._dio);

  final Dio _dio;

  bool get ready => feedbackEndpoint.isNotEmpty;

  Future<void> send({required FeedbackKind kind, required String text, String? reply, String? device}) async {
    if (!ready) throw const ProviderException('Das Formular ist noch nicht eingerichtet.');
    try {
      final res = await _dio.post<String>(
        'https://formsubmit.co/ajax/$feedbackEndpoint',
        data: {
          '_subject': 'Gleich.da – ${kind.subject}',
          '_template': 'table',
          '_captcha': 'false',
          'Art': kind.title,
          'Nachricht': text,
          if (reply != null && reply.isNotEmpty) ...{'Antwort an': reply, '_replyto': reply},
          'App und Gerät': ?device,
        },
        // FormSubmit nimmt nur Anfragen „von einer Webseite“ an; die Freischaltung
        // gilt für diese Herkunft (eingerichtet 24.09.2026).
        options: Options(headers: {
          'Accept': 'application/json',
          'Origin': 'https://github.com',
          'Referer': 'https://github.com/macpano/gleich.da',
        }, contentType: Headers.jsonContentType, responseType: ResponseType.plain),
      );
      // FormSubmit antwortet mit JSON, kennzeichnet es aber als text/html –
      // deshalb als Text lesen (vorher: „Senden hat nicht geklappt“, obwohl
      // die Nachricht angekommen war).
      if (!feedbackAccepted(res.data)) throw const ProviderException('Die Nachricht wurde nicht angenommen.');
    } on DioException catch (e) {
      final offline = e.type == DioExceptionType.connectionError || e.type == DioExceptionType.connectionTimeout;
      throw ProviderException(offline ? 'Keine Internetverbindung.' : 'Senden hat nicht geklappt.',
          cause: e, offline: offline);
    }
  }
}

/// Hat FormSubmit die Nachricht angenommen? `{"success":"true", …}`.
bool feedbackAccepted(String? body) {
  try {
    final ok = (jsonDecode(body ?? '') as Map)['success'];
    return ok == true || ok == 'true';
  } catch (_) {
    return false;
  }
}
