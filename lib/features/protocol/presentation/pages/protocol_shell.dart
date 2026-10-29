import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/catalog/static_pathology_repository.dart';
import '../../domain/entities/study_type.dart';
import '../../domain/repositories/pathology_repository.dart';
import '../../domain/services/finding_validator.dart';
import '../../domain/services/opg_report_generator.dart';
import '../../domain/services/report_generator.dart';
import '../bloc/protocol_bloc.dart';
import '../bloc/protocol_event.dart';
import '../widgets/protocol_workspace.dart';

/// Конфигурация вкладки исследования: справочник, генератор и валидатор.
class StudyConfig {
  const StudyConfig({
    required this.type,
    required this.label,
    required this.catalog,
    required this.generator,
    required this.validator,
  });

  final StudyType type;
  final String label;
  final PathologyRepository catalog;
  final ProtocolReportGenerator generator;
  final FindingValidator validator;
}

/// Оболочка протокола: вкладки исследований (КЛКТ / ОПГ) с независимыми
/// сессиями. [IndexedStack] сохраняет находки при переключении вкладок,
/// Enter / Esc обрабатываются только для активной вкладки.
class ProtocolShell extends StatefulWidget {
  const ProtocolShell({super.key, this.studies});

  /// Переопределение вкладок (для тестов); null — КЛКТ + ОПГ.
  final List<StudyConfig>? studies;

  @override
  State<ProtocolShell> createState() => _ProtocolShellState();
}

class _ProtocolShellState extends State<ProtocolShell>
    with SingleTickerProviderStateMixin {
  late final List<StudyConfig> _studies;
  late final List<ProtocolBloc> _blocs;
  late final TabController _tabController;

  static List<StudyConfig> _defaultStudies() {
    const cbctCatalog = StaticPathologyRepository();
    const opgCatalog = StaticPathologyRepository.opg();
    return const [
      StudyConfig(
        type: StudyType.cbct,
        label: 'КЛКТ',
        catalog: cbctCatalog,
        generator: ReportGenerator(catalog: cbctCatalog),
        validator: FindingValidator(catalog: cbctCatalog),
      ),
      StudyConfig(
        type: StudyType.opg,
        label: 'ОПГ',
        catalog: opgCatalog,
        generator: OpgReportGenerator(catalog: opgCatalog),
        validator: FindingValidator.opg(catalog: opgCatalog),
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    _studies = widget.studies ?? _defaultStudies();
    _blocs = [
      for (final study in _studies)
        ProtocolBloc(catalog: study.catalog, studyType: study.type),
    ];
    _tabController = TabController(length: _studies.length, vsync: this)
      ..addListener(_onTabChanged);
    HardwareKeyboard.instance.addHandler(_onKey);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKey);
    _tabController
      ..removeListener(_onTabChanged)
      ..dispose();
    for (final bloc in _blocs) {
      bloc.close();
    }
    super.dispose();
  }

  void _onTabChanged() {
    // Слушатель висит и на анимации индикатора: без этой проверки
    // каждый кадр переключения пересобирает обе вкладки.
    if (_tabController.indexIsChanging || !mounted) return;
    setState(() {});
  }

  /// Enter / Esc для активной вкладки.
  ///
  /// После клика по зубу или чипу патологии фокус остаётся на них, а не в
  /// композере. Material при этом обрабатывает Enter как [ActivateIntent]
  /// (повторный Enter по чипу снимает черновик вместо добавления в протокол).
  bool _onKey(KeyEvent event) {
    if (!mounted || event is! KeyDownEvent) return false;

    final key = event.logicalKey;
    final isEnter =
        key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter;
    final isEscape = key == LogicalKeyboardKey.escape;
    if (!isEnter && !isEscape) return false;

    final bloc = _blocs[_tabController.index];
    final state = bloc.state;

    if (isEscape) {
      // Открытый dropdown / диалог должен закрыться сам.
      if (Navigator.of(context).canPop()) return false;
      if (!state.hasDrafts && state.selectedFdis.isEmpty && !state.isEditing) {
        return false;
      }
      bloc.add(const DraftDiscarded());
      return true;
    }

    if (!state.hasDrafts) return false;
    bloc.add(const DraftCommitted());
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Заголовка нет — иначе над вкладками остаётся пустая панель.
        toolbarHeight: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: [for (final study in _studies) Tab(text: study.label)],
        ),
      ),
      body: IndexedStack(
        index: _tabController.index,
        children: [
          for (var i = 0; i < _studies.length; i++)
            _StudyScope(config: _studies[i], bloc: _blocs[i]),
        ],
      ),
    );
  }
}

/// DI одной вкладки: справочник, генератор, валидатор и bloc сессии.
class _StudyScope extends StatelessWidget {
  const _StudyScope({required this.config, required this.bloc});

  final StudyConfig config;
  final ProtocolBloc bloc;

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<PathologyRepository>.value(value: config.catalog),
        RepositoryProvider<ProtocolReportGenerator>.value(
          value: config.generator,
        ),
        RepositoryProvider<FindingValidator>.value(value: config.validator),
      ],
      child: BlocProvider.value(
        value: bloc,
        child: const _NoticeListener(child: ProtocolWorkspace()),
      ),
    );
  }
}

/// Показывает SnackBar на одноразовые уведомления из [ProtocolBloc.notices].
class _NoticeListener extends StatefulWidget {
  const _NoticeListener({required this.child});

  final Widget child;

  @override
  State<_NoticeListener> createState() => _NoticeListenerState();
}

class _NoticeListenerState extends State<_NoticeListener> {
  StreamSubscription<ProtocolNotice>? _subscription;

  @override
  void initState() {
    super.initState();
    final bloc = context.read<ProtocolBloc>();
    _subscription = bloc.notices.listen((notice) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            margin: AppTheme.snackBarMargin,
            content: Text(notice.message),
            action: notice.undoable
                ? SnackBarAction(
                    label: 'Отменить',
                    onPressed: () => bloc.add(const LastCommitUndone()),
                  )
                : null,
          ),
        );
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
