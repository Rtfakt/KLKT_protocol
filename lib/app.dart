import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/theme/app_theme.dart';
import 'features/protocol/data/catalog/static_pathology_repository.dart';
import 'features/protocol/domain/repositories/pathology_repository.dart';
import 'features/protocol/domain/services/report_generator.dart';
import 'features/protocol/presentation/pages/protocol_page.dart';

class KlktProtocolApp extends StatelessWidget {
  const KlktProtocolApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<PathologyRepository>(
          create: (_) => const StaticPathologyRepository(),
        ),
        RepositoryProvider<ReportGenerator>(
          create: (context) =>
              ReportGenerator(catalog: context.read<PathologyRepository>()),
        ),
      ],
      child: MaterialApp(
        title: 'Протокол КЛКТ',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: const ProtocolPage(),
      ),
    );
  }
}
