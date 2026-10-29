import 'package:flutter/material.dart';

import 'dental_formula_grid.dart';
import 'finding_composer.dart';
import 'live_preview.dart';
import 'pathology_panel.dart';

/// Рабочая область протокола одного исследования:
/// слева Live Preview (40%), справа формула + композер + патологии (60%).
///
/// Ожидает в контексте [ProtocolBloc], [PathologyRepository],
/// [ProtocolReportGenerator] и [FindingValidator] своей вкладки.
class ProtocolWorkspace extends StatelessWidget {
  const ProtocolWorkspace({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Левая зона — Live Preview (40%).
          const Expanded(flex: 4, child: LivePreview()),
          const SizedBox(width: 12),
          // Правая зона — панель управления (60%).
          Expanded(
            flex: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: const DentalFormulaGrid(),
                  ),
                ),
                const SizedBox(height: 10),
                const FindingComposer(),
                const SizedBox(height: 10),
                const Expanded(child: PathologyPanel()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
