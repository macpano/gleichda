import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/feedback.dart';
import '../../data/transit_provider.dart' show ProviderException;
import '../../state/providers.dart';
import '../../state/updates.dart';
import '../theme.dart';
import '../widgets.dart';

final feedbackProvider = Provider((ref) => FeedbackSender(ref.watch(dioProvider)));

/// Funktion vorschlagen oder Fehler melden – geht per E-Mail an den
/// Entwickler, ohne dass eine Adresse zu sehen ist.
class FeedbackScreen extends ConsumerStatefulWidget {
  const FeedbackScreen({super.key, required this.kind});

  final FeedbackKind kind;

  @override
  ConsumerState<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends ConsumerState<FeedbackScreen> {
  final _text = TextEditingController();
  final _reply = TextEditingController();
  bool _withDevice = true;
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _text.dispose();
    _reply.dispose();
    super.dispose();
  }

  String _device() {
    final version = ref.read(updateProvider).current;
    String os;
    try {
      os = '${Platform.operatingSystem} ${Platform.operatingSystemVersion}';
    } catch (_) {
      os = 'unbekannt';
    }
    return 'Gleich.da $version · $os';
  }

  Future<void> _send() async {
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await ref.read(feedbackProvider).send(
            kind: widget.kind,
            text: _text.text.trim(),
            reply: _reply.text.trim(),
            device: _withDevice ? _device() : null,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Danke! Deine Nachricht ist angekommen.')));
      Navigator.of(context).pop();
    } on ProviderException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final bug = widget.kind == FeedbackKind.bug;
    final ready = ref.watch(feedbackProvider).ready;
    return Scaffold(
      body: ListView(
        padding: pagePadding(context),
        children: [
          SubpageHeader(title: widget.kind.title, backLabel: 'Mehr'),
          const SizedBox(height: 8),
          Text(
            bug
                ? 'Was ist passiert, und was hättest du erwartet? Ein Bildschirmfoto kannst du leider noch nicht anhängen – '
                    'beschreib am besten, wo in der App es war.'
                : 'Was fehlt dir, oder was würde die App für dich besser machen?',
            style: context.t.secondary.copyWith(color: c.muted, height: 1.4),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _text,
            minLines: 6,
            maxLines: 12,
            maxLength: 4000,
            textCapitalization: TextCapitalization.sentences,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(hintText: bug ? 'Beschreibung des Fehlers' : 'Dein Vorschlag'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _reply,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              hintText: 'Deine E-Mail für eine Antwort (freiwillig)',
              prefixIcon: Icon(Icons.alternate_email, size: 20),
            ),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: () => setState(() => _withDevice = !_withDevice),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(children: [
                Checkbox(value: _withDevice, onChanged: (v) => setState(() => _withDevice = v ?? true)),
                const SizedBox(width: 4),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('App-Version und Android-Version mitsenden', style: TextStyle(fontSize: 15, color: c.ink)),
                    OneLine(_device(), style: TextStyle(fontSize: 13, color: c.muted)),
                  ]),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 12),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(_error!, style: TextStyle(color: c.red)),
            ),
          if (!ready)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text('Das Formular wird gerade eingerichtet und kann noch nicht senden.',
                  style: TextStyle(color: c.muted)),
            ),
          SizedBox(
            height: 48,
            child: FilledButton(
              style: FilledButton.styleFrom(shape: buttonShape(context)),
              onPressed: !ready || _sending || _text.text.trim().length < 10 ? null : _send,
              child: _sending
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Senden', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Gesendet wird nur, was du hier eingibst (und auf Wunsch die Versionen), per E-Mail über den Dienst '
            'FormSubmit an den Entwickler. Kein Standort, keine Fahrten.',
            style: TextStyle(fontSize: 12, height: 1.5, color: c.muted),
          ),
        ],
      ),
    );
  }
}
