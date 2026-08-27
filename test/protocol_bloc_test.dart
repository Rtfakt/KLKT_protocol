import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klkt_protocol/features/protocol/domain/entities/pathology.dart';
import 'package:klkt_protocol/features/protocol/domain/entities/selected_pathology.dart';
import 'package:klkt_protocol/features/protocol/presentation/bloc/protocol_bloc.dart';
import 'package:klkt_protocol/features/protocol/presentation/bloc/protocol_event.dart';
import 'package:klkt_protocol/features/protocol/presentation/bloc/protocol_state.dart';

import 'fixtures/fake_pathology_repository.dart';

void main() {
  ProtocolBloc buildBloc() => ProtocolBloc(catalog: FakePathologyRepository());

  group('ProtocolBloc: выбор зубов', () {
    blocTest<ProtocolBloc, ProtocolState>(
      'toggle выбора зуба добавляет и убирает FDI',
      build: buildBloc,
      act: (bloc) => bloc
        ..add(const ToothSelectionToggled(16))
        ..add(const ToothSelectionToggled(11))
        ..add(const ToothSelectionToggled(16)),
      expect: () => const [
        ProtocolState(selectedFdis: {16}),
        ProtocolState(selectedFdis: {16, 11}),
        ProtocolState(selectedFdis: {11}),
      ],
    );

    blocTest<ProtocolBloc, ProtocolState>(
      'toggle статуса «удален» добавляет и убирает FDI',
      build: buildBloc,
      act: (bloc) => bloc
        ..add(const ExtractedToggled(48))
        ..add(const ExtractedToggled(48)),
      expect: () => const [
        ProtocolState(extractedFdis: {48}),
        ProtocolState(extractedFdis: {}),
      ],
    );
  });

  group('ProtocolBloc: патологии', () {
    blocTest<ProtocolBloc, ProtocolState>(
      'зубная патология без выбранных зубов не добавляется, '
      'но шлёт уведомление',
      build: buildBloc,
      act: (bloc) {
        expectLater(bloc.notices, emits('Сначала выберите зубы в формуле'));
        bloc.add(const PathologyToggled('tooth_simple'));
      },
      expect: () => const <ProtocolState>[],
    );

    blocTest<ProtocolBloc, ProtocolState>(
      'зубная патология добавляется на выбранные зубы '
      'в анатомическом порядке',
      build: buildBloc,
      seed: () => const ProtocolState(selectedFdis: {36, 12}),
      act: (bloc) => bloc.add(const PathologyToggled('tooth_simple')),
      verify: (bloc) {
        final finding = bloc.state.findings.single;
        expect(finding.pathologyId, 'tooth_simple');
        expect(finding.toothFdis, [12, 36]);
        // Без динамических полей активация не происходит.
        expect(bloc.state.activeFindingUid, isNull);
      },
    );

    blocTest<ProtocolBloc, ProtocolState>(
      'патология с размером сразу становится активной '
      'и получает пустые Measurements',
      build: buildBloc,
      seed: () => const ProtocolState(selectedFdis: {21}),
      act: (bloc) => bloc.add(const PathologyToggled('tooth_size')),
      verify: (bloc) {
        final finding = bloc.state.findings.single;
        expect(finding.measurements, const Measurements());
        expect(bloc.state.activeFindingUid, finding.uid);
      },
    );

    blocTest<ProtocolBloc, ProtocolState>(
      'повторный клик той же патологией по тем же зубам снимает находку',
      build: buildBloc,
      seed: () => const ProtocolState(selectedFdis: {16, 17}),
      act: (bloc) => bloc
        ..add(const PathologyToggled('tooth_simple'))
        ..add(const PathologyToggled('tooth_simple')),
      verify: (bloc) {
        expect(bloc.state.findings, isEmpty);
        expect(bloc.state.activeFindingUid, isNull);
      },
    );

    blocTest<ProtocolBloc, ProtocolState>(
      'общая патология добавляется без зубов и снимается повторным кликом',
      build: buildBloc,
      act: (bloc) => bloc
        ..add(const PathologyToggled('general_side'))
        ..add(const PathologyToggled('general_side')),
      verify: (bloc) => expect(bloc.state.findings, isEmpty),
    );

    blocTest<ProtocolBloc, ProtocolState>(
      'удаление находки сбрасывает активную, если удалили её',
      build: buildBloc,
      act: (bloc) => bloc
        ..add(const PathologyToggled('general_side'))
        ..add(const FindingRemoved('f1')),
      verify: (bloc) {
        expect(bloc.state.findings, isEmpty);
        expect(bloc.state.activeFindingUid, isNull);
      },
    );
  });

  group('ProtocolBloc: динамические поля', () {
    blocTest<ProtocolBloc, ProtocolState>(
      'изменения применяются только к активной находке',
      build: buildBloc,
      seed: () => const ProtocolState(
        findings: [
          SelectedPathology(uid: 'a', pathologyId: 'general_side'),
          SelectedPathology(uid: 'b', pathologyId: 'general_side'),
        ],
        activeFindingUid: 'b',
      ),
      act: (bloc) => bloc.add(const SideChanged(Side.left)),
      verify: (bloc) {
        expect(bloc.state.findings[0].side, isNull);
        expect(bloc.state.findings[1].side, Side.left);
      },
    );

    blocTest<ProtocolBloc, ProtocolState>(
      'без активной находки изменения игнорируются',
      build: buildBloc,
      seed: () => const ProtocolState(
        findings: [
          SelectedPathology(uid: 'a', pathologyId: 'general_side'),
        ],
      ),
      act: (bloc) => bloc.add(const SideChanged(Side.right)),
      expect: () => const <ProtocolState>[],
    );

    blocTest<ProtocolBloc, ProtocolState>(
      'размеры накапливаются по осям, смена количества сохраняет значения',
      build: buildBloc,
      seed: () => const ProtocolState(
        findings: [
          SelectedPathology(
            uid: 'a',
            pathologyId: 'tooth_size',
            toothFdis: [21],
            measurements: Measurements(),
          ),
        ],
        activeFindingUid: 'a',
      ),
      act: (bloc) => bloc
        ..add(const MeasurementsChanged(x: '4'))
        ..add(const SizeCountChanged(2))
        ..add(const MeasurementsChanged(y: '5')),
      verify: (bloc) {
        expect(
          bloc.state.findings.single.measurements,
          const Measurements(count: 2, x: '4', y: '5'),
        );
      },
    );

    blocTest<ProtocolBloc, ProtocolState>(
      'FindingActivated переключает активную находку',
      build: buildBloc,
      seed: () => const ProtocolState(
        findings: [
          SelectedPathology(uid: 'a', pathologyId: 'general_side'),
        ],
      ),
      act: (bloc) => bloc.add(const FindingActivated('a')),
      expect: () => const [
        ProtocolState(
          findings: [
            SelectedPathology(uid: 'a', pathologyId: 'general_side'),
          ],
          activeFindingUid: 'a',
        ),
      ],
    );
  });

  group('ProtocolBloc: очистка', () {
    blocTest<ProtocolBloc, ProtocolState>(
      'Cleared возвращает пустое состояние',
      build: buildBloc,
      seed: () => const ProtocolState(
        selectedFdis: {16},
        extractedFdis: {48},
        findings: [
          SelectedPathology(uid: 'a', pathologyId: 'general_side'),
        ],
        activeFindingUid: 'a',
      ),
      act: (bloc) => bloc.add(const Cleared()),
      expect: () => const [ProtocolState()],
    );
  });
}
