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

  const simpleDraft = SelectedPathology(
    uid: ProtocolState.draftUid,
    pathologyId: 'tooth_simple',
  );

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

  group('ProtocolBloc: черновики', () {
    blocTest<ProtocolBloc, ProtocolState>(
      'выбор патологии создаёт черновик, а не находку',
      build: buildBloc,
      act: (bloc) => bloc.add(const PathologySelected('tooth_simple')),
      verify: (bloc) {
        expect(bloc.state.findings, isEmpty);
        expect(bloc.state.drafts.single.pathologyId, 'tooth_simple');
      },
    );

    blocTest<ProtocolBloc, ProtocolState>(
      'патология с размером получает пустые Measurements в черновике',
      build: buildBloc,
      act: (bloc) => bloc.add(const PathologySelected('tooth_size')),
      verify: (bloc) {
        expect(bloc.state.drafts.single.measurements, const Measurements());
      },
    );

    blocTest<ProtocolBloc, ProtocolState>(
      'патология с двумя размерами по умолчанию открывает count = 2',
      build: buildBloc,
      act: (bloc) => bloc.add(const PathologySelected('tooth_size_two')),
      verify: (bloc) {
        expect(
          bloc.state.drafts.single.measurements,
          const Measurements(count: 2),
        );
      },
    );

    blocTest<ProtocolBloc, ProtocolState>(
      'повторный клик по той же патологии снимает черновик',
      build: buildBloc,
      act: (bloc) => bloc
        ..add(const PathologySelected('tooth_simple'))
        ..add(const PathologySelected('tooth_simple')),
      verify: (bloc) => expect(bloc.state.drafts, isEmpty),
    );

    blocTest<ProtocolBloc, ProtocolState>(
      'выбор второй патологии добавляет черновик и сохраняет уточнения первой',
      build: buildBloc,
      act: (bloc) => bloc
        ..add(const PathologySelected('general_side'))
        ..add(const SideChanged(Side.left))
        ..add(const PathologySelected('tooth_simple')),
      verify: (bloc) {
        expect(bloc.state.drafts, hasLength(2));
        expect(bloc.state.drafts.map((d) => d.pathologyId), [
          'general_side',
          'tooth_simple',
        ]);
        expect(bloc.state.drafts.first.side, Side.left);
      },
    );

    blocTest<ProtocolBloc, ProtocolState>(
      'повторный клик снимает только эту патологию из набора',
      build: buildBloc,
      act: (bloc) => bloc
        ..add(const PathologySelected('tooth_simple'))
        ..add(const PathologySelected('tooth_extracted'))
        ..add(const PathologySelected('tooth_extracted')),
      verify: (bloc) {
        expect(bloc.state.drafts, hasLength(1));
        expect(bloc.state.drafts.single.pathologyId, 'tooth_simple');
      },
    );

    blocTest<ProtocolBloc, ProtocolState>(
      'DraftDiscarded сбрасывает черновики и выбор зубов',
      build: buildBloc,
      seed: () =>
          const ProtocolState(selectedFdis: {16}, drafts: [simpleDraft]),
      act: (bloc) => bloc.add(const DraftDiscarded()),
      expect: () => const [ProtocolState()],
    );
  });

  group('ProtocolBloc: коммит черновика', () {
    blocTest<ProtocolBloc, ProtocolState>(
      'коммит зубной патологии добавляет находку в анатомическом порядке '
      'и обнуляет выбор зубов и черновики',
      build: buildBloc,
      seed: () =>
          const ProtocolState(selectedFdis: {36, 12}, drafts: [simpleDraft]),
      act: (bloc) => bloc.add(const DraftCommitted()),
      verify: (bloc) {
        final finding = bloc.state.findings.single;
        expect(finding.pathologyId, 'tooth_simple');
        expect(finding.toothFdis, [12, 36]);
        expect(bloc.state.selectedFdis, isEmpty);
        expect(bloc.state.drafts, isEmpty);
        expect(bloc.state.editingUid, isNull);
        expect(bloc.state.lastCommittedFdis, {12, 36});
        expect(bloc.state.lastCommittedUids, [finding.uid]);
      },
    );

    blocTest<ProtocolBloc, ProtocolState>(
      'коммит двух зубных патологий на один зуб даёт две находки',
      build: buildBloc,
      seed: () => const ProtocolState(
        selectedFdis: {36},
        drafts: [
          simpleDraft,
          SelectedPathology(
            uid: ProtocolState.draftUid,
            pathologyId: 'tooth_extracted',
          ),
        ],
      ),
      act: (bloc) => bloc.add(const DraftCommitted()),
      verify: (bloc) {
        expect(bloc.state.findings, hasLength(2));
        expect(bloc.state.findings.map((f) => f.pathologyId), [
          'tooth_simple',
          'tooth_extracted',
        ]);
        for (final f in bloc.state.findings) {
          expect(f.toothFdis, [36]);
        }
        expect(bloc.state.drafts, isEmpty);
        expect(bloc.state.selectedFdis, isEmpty);
        expect(bloc.state.lastCommittedFdis, {36});
        expect(bloc.state.lastCommittedUids, hasLength(2));
      },
    );

    blocTest<ProtocolBloc, ProtocolState>(
      'коммит зубной патологии без зубов не проходит и шлёт уведомление',
      build: buildBloc,
      seed: () => const ProtocolState(drafts: [simpleDraft]),
      act: (bloc) {
        expectLater(
          bloc.notices.map((n) => n.message),
          emits('Выберите зубы в формуле'),
        );
        bloc.add(const DraftCommitted());
      },
      expect: () => const <ProtocolState>[],
    );

    blocTest<ProtocolBloc, ProtocolState>(
      'коммит с незаполненными обязательными полями не проходит',
      build: buildBloc,
      seed: () => const ProtocolState(
        selectedFdis: {21},
        drafts: [
          SelectedPathology(
            uid: ProtocolState.draftUid,
            pathologyId: 'tooth_size',
            measurements: Measurements(),
          ),
        ],
      ),
      act: (bloc) {
        expectLater(
          bloc.notices.map((n) => n.message),
          emits('Заполните обязательные поля'),
        );
        bloc.add(const DraftCommitted());
      },
      expect: () => const <ProtocolState>[],
    );

    blocTest<ProtocolBloc, ProtocolState>(
      'общая патология коммитится без зубов и не трогает lastCommittedFdis',
      build: buildBloc,
      seed: () => const ProtocolState(lastCommittedFdis: {16}),
      act: (bloc) => bloc
        ..add(const PathologySelected('general_side'))
        ..add(const SideChanged(Side.left))
        ..add(const DraftCommitted()),
      verify: (bloc) {
        final finding = bloc.state.findings.single;
        expect(finding.pathologyId, 'general_side');
        expect(finding.toothFdis, isEmpty);
        expect(finding.side, Side.left);
        expect(bloc.state.drafts, isEmpty);
        expect(bloc.state.lastCommittedFdis, {16});
      },
    );

    blocTest<ProtocolBloc, ProtocolState>(
      'уведомление о добавлении содержит зубы и допускает undo',
      build: buildBloc,
      seed: () =>
          const ProtocolState(selectedFdis: {16, 17}, drafts: [simpleDraft]),
      act: (bloc) {
        expectLater(
          bloc.notices,
          emits(
            predicate<ProtocolNotice>(
              (n) =>
                  n.undoable &&
                  n.message == 'Добавлено: 1.6, 1.7 — Зубная без уточнений',
            ),
          ),
        );
        bloc.add(const DraftCommitted());
      },
    );

    blocTest<ProtocolBloc, ProtocolState>(
      'уведомление о пачке содержит число находок',
      build: buildBloc,
      seed: () => const ProtocolState(
        selectedFdis: {36},
        drafts: [
          simpleDraft,
          SelectedPathology(
            uid: ProtocolState.draftUid,
            pathologyId: 'tooth_extracted',
          ),
        ],
      ),
      act: (bloc) {
        expectLater(
          bloc.notices,
          emits(
            predicate<ProtocolNotice>(
              (n) => n.undoable && n.message == 'Добавлено: 3.6 — 2 находки',
            ),
          ),
        );
        bloc.add(const DraftCommitted());
      },
    );
  });

  group('ProtocolBloc: возврат зубов и undo', () {
    blocTest<ProtocolBloc, ProtocolState>(
      'TeethRestored возвращает прошлый набор зубов',
      build: buildBloc,
      seed: () => const ProtocolState(lastCommittedFdis: {16, 17}),
      act: (bloc) => bloc.add(const TeethRestored()),
      verify: (bloc) => expect(bloc.state.selectedFdis, {16, 17}),
    );

    blocTest<ProtocolBloc, ProtocolState>(
      'TeethRestored без прошлого набора ничего не делает',
      build: buildBloc,
      act: (bloc) => bloc.add(const TeethRestored()),
      expect: () => const <ProtocolState>[],
    );

    blocTest<ProtocolBloc, ProtocolState>(
      'LastCommitUndone убирает находку и возвращает черновик с зубами',
      build: buildBloc,
      seed: () =>
          const ProtocolState(selectedFdis: {16}, drafts: [simpleDraft]),
      act: (bloc) => bloc
        ..add(const DraftCommitted())
        ..add(const LastCommitUndone()),
      verify: (bloc) {
        expect(bloc.state.findings, isEmpty);
        expect(bloc.state.selectedFdis, {16});
        expect(bloc.state.drafts.single.pathologyId, 'tooth_simple');
        expect(bloc.state.lastCommittedUids, isEmpty);
      },
    );

    blocTest<ProtocolBloc, ProtocolState>(
      'LastCommitUndone снимает пачку и возвращает оба черновика',
      build: buildBloc,
      seed: () => const ProtocolState(
        selectedFdis: {36},
        drafts: [
          simpleDraft,
          SelectedPathology(
            uid: ProtocolState.draftUid,
            pathologyId: 'tooth_extracted',
          ),
        ],
      ),
      act: (bloc) => bloc
        ..add(const DraftCommitted())
        ..add(const LastCommitUndone()),
      verify: (bloc) {
        expect(bloc.state.findings, isEmpty);
        expect(bloc.state.selectedFdis, {36});
        expect(bloc.state.drafts.map((d) => d.pathologyId), [
          'tooth_simple',
          'tooth_extracted',
        ]);
        expect(bloc.state.lastCommittedUids, isEmpty);
      },
    );
  });

  group('ProtocolBloc: правка находки', () {
    blocTest<ProtocolBloc, ProtocolState>(
      'FindingEditRequested загружает находку в черновик и выбор зубов',
      build: buildBloc,
      seed: () => const ProtocolState(
        findings: [
          SelectedPathology(
            uid: 'a',
            pathologyId: 'tooth_size',
            toothFdis: [21],
            measurements: Measurements(x: '4'),
          ),
        ],
      ),
      act: (bloc) => bloc.add(const FindingEditRequested('a')),
      verify: (bloc) {
        expect(bloc.state.editingUid, 'a');
        expect(bloc.state.selectedFdis, {21});
        expect(bloc.state.drafts.single.pathologyId, 'tooth_size');
        expect(
          bloc.state.drafts.single.measurements,
          const Measurements(x: '4'),
        );
      },
    );

    blocTest<ProtocolBloc, ProtocolState>(
      'в режиме правки второй чип заменяет патологию, а не добавляет',
      build: buildBloc,
      seed: () => const ProtocolState(
        findings: [
          SelectedPathology(
            uid: 'a',
            pathologyId: 'tooth_size',
            toothFdis: [21],
            measurements: Measurements(x: '4'),
          ),
        ],
      ),
      act: (bloc) => bloc
        ..add(const FindingEditRequested('a'))
        ..add(const PathologySelected('tooth_simple')),
      verify: (bloc) {
        expect(bloc.state.editingUid, 'a');
        expect(bloc.state.drafts, hasLength(1));
        expect(bloc.state.drafts.single.pathologyId, 'tooth_simple');
        expect(bloc.state.drafts.single.measurements, isNull);
      },
    );

    blocTest<ProtocolBloc, ProtocolState>(
      'коммит в режиме правки перезаписывает находку на месте без дубля',
      build: buildBloc,
      seed: () => const ProtocolState(
        findings: [
          SelectedPathology(
            uid: 'a',
            pathologyId: 'tooth_size',
            toothFdis: [21],
            measurements: Measurements(x: '4'),
          ),
          SelectedPathology(
            uid: 'b',
            pathologyId: 'tooth_simple',
            toothFdis: [11],
          ),
        ],
      ),
      act: (bloc) => bloc
        ..add(const FindingEditRequested('a'))
        ..add(const ToothSelectionToggled(22))
        ..add(const MeasurementsChanged(x: '7'))
        ..add(const DraftCommitted()),
      verify: (bloc) {
        expect(bloc.state.findings, hasLength(2));
        final updated = bloc.state.findings.first;
        expect(updated.uid, 'a');
        expect(updated.toothFdis, [21, 22]);
        expect(updated.measurements?.x, '7');
        expect(bloc.state.editingUid, isNull);
        expect(bloc.state.drafts, isEmpty);
        expect(bloc.state.selectedFdis, isEmpty);
      },
    );

    blocTest<ProtocolBloc, ProtocolState>(
      'до коммита правка меняет только черновик, находка не трогается',
      build: buildBloc,
      seed: () => const ProtocolState(
        findings: [
          SelectedPathology(
            uid: 'a',
            pathologyId: 'general_side',
            side: Side.left,
          ),
        ],
      ),
      act: (bloc) => bloc
        ..add(const FindingEditRequested('a'))
        ..add(const SideChanged(Side.right)),
      verify: (bloc) {
        expect(bloc.state.findings.single.side, Side.left);
        expect(bloc.state.drafts.single.side, Side.right);
      },
    );

    blocTest<ProtocolBloc, ProtocolState>(
      'удаление редактируемой находки сбрасывает черновик и режим правки',
      build: buildBloc,
      seed: () => const ProtocolState(
        findings: [SelectedPathology(uid: 'a', pathologyId: 'general_side')],
      ),
      act: (bloc) => bloc
        ..add(const FindingEditRequested('a'))
        ..add(const FindingRemoved('a')),
      verify: (bloc) {
        expect(bloc.state.findings, isEmpty);
        expect(bloc.state.editingUid, isNull);
        expect(bloc.state.drafts, isEmpty);
      },
    );
  });

  group('ProtocolBloc: динамические поля черновика', () {
    blocTest<ProtocolBloc, ProtocolState>(
      'без черновика изменения игнорируются',
      build: buildBloc,
      act: (bloc) => bloc.add(const SideChanged(Side.right)),
      expect: () => const <ProtocolState>[],
    );

    blocTest<ProtocolBloc, ProtocolState>(
      'размеры накапливаются по осям, смена количества сохраняет значения',
      build: buildBloc,
      seed: () => const ProtocolState(
        drafts: [
          SelectedPathology(
            uid: ProtocolState.draftUid,
            pathologyId: 'tooth_size',
            measurements: Measurements(),
          ),
        ],
      ),
      act: (bloc) => bloc
        ..add(const MeasurementsChanged(x: '4'))
        ..add(const SizeCountChanged(2))
        ..add(const MeasurementsChanged(y: '5')),
      verify: (bloc) {
        expect(
          bloc.state.drafts.single.measurements,
          const Measurements(count: 2, x: '4', y: '5'),
        );
      },
    );

    blocTest<ProtocolBloc, ProtocolState>(
      'pathologyId направляет уточнение в нужный черновик',
      build: buildBloc,
      seed: () => const ProtocolState(
        drafts: [
          SelectedPathology(
            uid: ProtocolState.draftUid,
            pathologyId: 'tooth_size',
            measurements: Measurements(),
          ),
          SelectedPathology(
            uid: ProtocolState.draftUid,
            pathologyId: 'general_side',
          ),
        ],
      ),
      act: (bloc) => bloc
        ..add(const MeasurementsChanged(pathologyId: 'tooth_size', x: '4'))
        ..add(const SideChanged(Side.left, pathologyId: 'general_side')),
      verify: (bloc) {
        expect(bloc.state.drafts[0].measurements?.x, '4');
        expect(bloc.state.drafts[1].side, Side.left);
      },
    );

    blocTest<ProtocolBloc, ProtocolState>(
      'без pathologyId при нескольких черновиках изменение игнорируется',
      build: buildBloc,
      seed: () => const ProtocolState(
        drafts: [
          SelectedPathology(
            uid: ProtocolState.draftUid,
            pathologyId: 'tooth_size',
            measurements: Measurements(),
          ),
          SelectedPathology(
            uid: ProtocolState.draftUid,
            pathologyId: 'general_side',
          ),
        ],
      ),
      act: (bloc) => bloc.add(const MeasurementsChanged(x: '4')),
      expect: () => const <ProtocolState>[],
    );
  });

  group('ProtocolBloc: соседний зуб', () {
    const adjacentDraft = SelectedPathology(
      uid: ProtocolState.draftUid,
      pathologyId: 'tooth_adjacent',
      adjacentFdi: 15,
    );

    blocTest<ProtocolBloc, ProtocolState>(
      'принимается только зуб рядом с выбранными',
      build: buildBloc,
      seed: () => const ProtocolState(
        selectedFdis: {16},
        drafts: [
          SelectedPathology(
            uid: ProtocolState.draftUid,
            pathologyId: 'tooth_adjacent',
          ),
        ],
      ),
      act: (bloc) => bloc
        ..add(const AdjacentChanged(21, pathologyId: 'tooth_adjacent'))
        ..add(const AdjacentChanged(15, pathologyId: 'tooth_adjacent')),
      expect: () => const [
        ProtocolState(selectedFdis: {16}, drafts: [adjacentDraft]),
      ],
    );

    blocTest<ProtocolBloc, ProtocolState>(
      'смена выбранных зубов сбрасывает соседа, который больше не рядом',
      build: buildBloc,
      seed: () =>
          const ProtocolState(selectedFdis: {16, 17}, drafts: [adjacentDraft]),
      act: (bloc) => bloc.add(const ToothSelectionToggled(16)),
      expect: () => const [
        ProtocolState(
          selectedFdis: {17},
          drafts: [
            SelectedPathology(
              uid: ProtocolState.draftUid,
              pathologyId: 'tooth_adjacent',
            ),
          ],
        ),
      ],
    );

    blocTest<ProtocolBloc, ProtocolState>(
      'сосед остаётся, если он всё ещё контактирует с набором',
      build: buildBloc,
      seed: () =>
          const ProtocolState(selectedFdis: {16}, drafts: [adjacentDraft]),
      act: (bloc) => bloc.add(const ToothSelectionToggled(17)),
      expect: () => const [
        ProtocolState(selectedFdis: {16, 17}, drafts: [adjacentDraft]),
      ],
    );

    blocTest<ProtocolBloc, ProtocolState>(
      'коммит с зубом не рядом не проходит',
      build: buildBloc,
      seed: () => const ProtocolState(
        selectedFdis: {16},
        drafts: [
          SelectedPathology(
            uid: ProtocolState.draftUid,
            pathologyId: 'tooth_adjacent',
            adjacentFdi: 21,
          ),
        ],
      ),
      act: (bloc) => bloc.add(const DraftCommitted()),
      expect: () => const <ProtocolState>[],
      verify: (bloc) => expect(bloc.state.findings, isEmpty),
    );

    blocTest<ProtocolBloc, ProtocolState>(
      'коммит сохраняет соседний зуб',
      build: buildBloc,
      seed: () =>
          const ProtocolState(selectedFdis: {16}, drafts: [adjacentDraft]),
      act: (bloc) => bloc.add(const DraftCommitted()),
      verify: (bloc) {
        final finding = bloc.state.findings.single;
        expect(finding.toothFdis, [16]);
        expect(finding.adjacentFdi, 15);
        expect(bloc.state.drafts, isEmpty);
      },
    );
  });

  group('ProtocolBloc: очистка', () {
    blocTest<ProtocolBloc, ProtocolState>(
      'Cleared возвращает пустое состояние',
      build: buildBloc,
      seed: () => const ProtocolState(
        selectedFdis: {16},
        extractedFdis: {48},
        findings: [SelectedPathology(uid: 'a', pathologyId: 'general_side')],
        drafts: [simpleDraft],
        editingUid: 'a',
        lastCommittedFdis: {16},
        lastCommittedUids: ['a'],
      ),
      act: (bloc) => bloc.add(const Cleared()),
      expect: () => const [ProtocolState()],
    );
  });
}
