import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets.dart';

/// Meldungen und Linienabos.
// TODO: Meldungsliste aus EFA XML_ADDINFO_REQUEST und GTFS-RT (Schritt 12).
class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) => ListView(
        padding: pagePadding(context),
        children: [
          Text('Meldungen', style: context.t.screenTitle),
          const SizedBox(height: 16),
          const Notice('Die Meldungsliste folgt in einem der nächsten Schritte. '
              'Meldungen zu einer Fahrt stehen schon jetzt in der Fahrt selbst.'),
        ],
      );
}
