import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'data/db/database.dart';
import 'state/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('de');
  final db = AppDatabase();
  runApp(ProviderScope(
    overrides: [databaseProvider.overrideWithValue(db)],
    child: const GleichdaApp(),
  ));
}
