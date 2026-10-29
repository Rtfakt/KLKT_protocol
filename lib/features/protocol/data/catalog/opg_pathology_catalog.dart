import '../../domain/entities/pathology.dart';

/// Справочник патологий для ортопантомограммы (ОПГ): 9 групп.
///
/// Порядок групп задаёт порядок строк заключения (шаблонный протокол:
/// адентия → имплантаты → кариес → эндо → периодонтит → пародонт → прочее)
/// и порядок патологий внутри одной зубной строки описания.
/// Номер зуба в описание подставляет [OpgReportGenerator] префиксом
/// «1.6 зуб — » / «В области 1.6 — », поэтому в descriptionTemplate его нет.
///
/// Плейсхолдер {teeth} в заключении: после «области», «зуба», «зубов» или «:»
/// подставляются только номера; иначе — «зуба 1.6» / «зубов 1.6, 2.4»
/// (для [ToothRefStyle.area] — «в области 1.6»).
class OpgPathologyCatalog {
  OpgPathologyCatalog._();

  static final List<PathologyGroup> groups = _buildGroups();

  static final Map<String, Pathology> byId = {
    for (final g in groups)
      for (final p in g.items) p.id: p,
  };

  static List<PathologyGroup> _buildGroups() {
    final raw = <PathologyGroup>[
      PathologyGroup(
        id: 'og1',
        order: 1,
        title: '1. Зубной ряд и положение зубов',
        items: [
          const Pathology(
            id: 'opg_crowding',
            groupId: 'og1',
            name: 'Тесное положение зубов',
            // Раздел «Тесное положение зубов: … сегментов» генератор ОПГ
            // строит из квадрантов выбранных зубов; шаблон — запасной.
            descriptionTemplate: 'тесное положение {teeth}',
            conclusionTemplate: 'тесное положение зубов',
            frequency: 5,
            scope: PathologyScope.tooth,
            significance: 2,
            omitFromConclusion: true,
          ),
          const Pathology(
            id: 'opg_retention',
            groupId: 'og1',
            name: 'Ретинирован, дистопирован',
            descriptionTemplate: 'ретенция и дистопия {teeth}',
            conclusionTemplate: 'ретенция и дистопия {teeth}',
            frequency: 4,
            scope: PathologyScope.tooth,
            significance: 3,
          ),
        ],
      ),
      PathologyGroup(
        id: 'og2',
        order: 2,
        title: '2. Имплантаты и хирургическое лечение',
        items: [
          const Pathology(
            id: 'opg_implant_ok',
            groupId: 'og2',
            name: 'Дентальный имплантат, без признаков периимплантита',
            descriptionTemplate:
                'дентальные имплантаты, признаков периимплантита '
                'не визуализируется',
            conclusionTemplate: 'дентальный имплантат в области {teeth}',
            refStyle: ToothRefStyle.area,
            frequency: 5,
            scope: PathologyScope.tooth,
            significance: 2,
          ),
          const Pathology(
            id: 'opg_periimplantitis',
            groupId: 'og2',
            name: 'Периимплантит (резорбция кости у имплантата)',
            descriptionTemplate:
                'дентальный имплантат с зоной резорбции костной ткани '
                'по периферии',
            conclusionTemplate: 'признаки периимплантита в области {teeth}',
            refStyle: ToothRefStyle.area,
            frequency: 3,
            scope: PathologyScope.tooth,
            significance: 5,
          ),
          const Pathology(
            id: 'opg_socket',
            groupId: 'og2',
            name: 'Лунка удалённого зуба в стадии организации',
            descriptionTemplate: 'лунка удалённого зуба в стадии организации',
            conclusionTemplate: 'состояние после удаления {teeth}',
            refStyle: ToothRefStyle.area,
            frequency: 3,
            scope: PathologyScope.tooth,
            significance: 2,
          ),
          const Pathology(
            id: 'opg_bone_graft',
            groupId: 'og2',
            name: 'Состояние после костной пластики / синус-лифтинга',
            descriptionTemplate: 'признаки костной пластики / синус-лифтинга',
            conclusionTemplate:
                'состояние после костной пластики в области {teeth}',
            refStyle: ToothRefStyle.area,
            frequency: 2,
            scope: PathologyScope.tooth,
            significance: 2,
          ),
        ],
      ),
      PathologyGroup(
        id: 'og3',
        order: 3,
        title: '3. Кариозные и некариозные поражения',
        items: [
          const Pathology(
            id: 'opg_caries_dentin',
            groupId: 'og3',
            name: 'Просветление коронки в проекции дентина',
            descriptionTemplate:
                'в коронковой части участок просветления в проекции дентина',
            conclusionTemplate: 'признаки кариеса {teeth}',
            frequency: 5,
            scope: PathologyScope.tooth,
            significance: 3,
          ),
          const Pathology(
            id: 'opg_caries_pulp',
            groupId: 'og3',
            name: 'Просветление, распространяющееся до камеры зуба',
            descriptionTemplate:
                'в коронковой части участок просветления, '
                'распространяющийся до камеры зуба',
            conclusionTemplate: 'глубокий кариозный процесс {teeth}',
            frequency: 4,
            scope: PathologyScope.tooth,
            significance: 4,
          ),
          const Pathology(
            id: 'opg_crown_defect',
            groupId: 'og3',
            name: 'Дефект коронки до проекции камеры зуба',
            descriptionTemplate: 'дефект коронки до проекции камеры зуба',
            conclusionTemplate: 'дефект коронки {teeth}',
            frequency: 3,
            scope: PathologyScope.tooth,
            significance: 3,
          ),
        ],
      ),
      PathologyGroup(
        id: 'og4',
        order: 4,
        title: '4. Эндодонтическое лечение',
        items: [
          const Pathology(
            id: 'opg_endo_treated',
            groupId: 'og4',
            name: 'Признаки эндодонтического лечения',
            descriptionTemplate: 'признаки эндодонтического лечения',
            conclusionTemplate:
                'состояние после эндодонтического лечения {teeth}',
            frequency: 5,
            scope: PathologyScope.tooth,
            significance: 2,
          ),
          const Pathology(
            id: 'opg_endo_partial',
            groupId: 'og4',
            name: 'Неполная обтурация корневых каналов',
            descriptionTemplate: 'неполная обтурация корневых каналов',
            conclusionTemplate: 'неполная обтурация корневых каналов {teeth}',
            frequency: 4,
            scope: PathologyScope.tooth,
            significance: 4,
          ),
          const Pathology(
            id: 'opg_endo_excess',
            groupId: 'og4',
            name: 'Избыточная обтурация, материал за верхушкой',
            descriptionTemplate:
                'избыточная обтурация корневых каналов с выходом '
                'пломбировочного материала за верхушку',
            conclusionTemplate:
                'выведение пломбировочного материала за верхушку {teeth}',
            frequency: 3,
            scope: PathologyScope.tooth,
            significance: 4,
          ),
        ],
      ),
      PathologyGroup(
        id: 'og5',
        order: 5,
        title: '5. Периапикальные изменения',
        items: [
          const Pathology(
            id: 'opg_apical_lucency',
            groupId: 'og5',
            name: 'Просветление апикально (киста / расширение щели)',
            descriptionTemplate:
                'участок просветления апикально — не исключается '
                'наличие апикальной кисты, расширения периодонтальной щели',
            conclusionTemplate: 'признаки периодонтита {teeth}',
            frequency: 5,
            scope: PathologyScope.tooth,
            significance: 4,
          ),
          const Pathology(
            id: 'opg_pdl_widening',
            groupId: 'og5',
            name: 'Расширение периодонтальной щели',
            descriptionTemplate: 'расширение периодонтальной щели',
            conclusionTemplate: 'расширение периодонтальной щели {teeth}',
            frequency: 4,
            scope: PathologyScope.tooth,
            significance: 3,
          ),
        ],
      ),
      PathologyGroup(
        id: 'og6',
        order: 6,
        title: '6. Пародонт',
        items: [
          const Pathology(
            id: 'opg_pockets',
            groupId: 'og6',
            name: 'Пародонтальные карманы',
            descriptionTemplate: 'пародонтальные карманы',
            conclusionTemplate: 'пародонтальные карманы (смотрите описание)',
            refStyle: ToothRefStyle.area,
            frequency: 5,
            scope: PathologyScope.tooth,
            significance: 4,
          ),
          const Pathology(
            id: 'opg_ridge_reduction',
            groupId: 'og6',
            name: 'Снижение альвеолярных гребней',
            descriptionTemplate: 'снижение альвеолярных гребней',
            conclusionTemplate: 'снижение альвеолярных гребней',
            frequency: 4,
            scope: PathologyScope.general,
            significance: 4,
          ),
          const Pathology(
            id: 'opg_recession_cervical',
            groupId: 'og6',
            name: 'Рецессия генерализованная до уровня шейки',
            descriptionTemplate: 'рецессия генерализованная до уровня шейки',
            conclusionTemplate: 'признаки пародонтита, рецессия костной ткани',
            frequency: 4,
            scope: PathologyScope.general,
            significance: 4,
          ),
          const Pathology(
            id: 'opg_recession_third',
            groupId: 'og6',
            name: 'Рецессия генерализованная до 1/3 длины корня',
            descriptionTemplate: 'рецессия генерализованная до 1/3 длины корня',
            conclusionTemplate: 'признаки пародонтита, рецессия костной ткани',
            frequency: 3,
            scope: PathologyScope.general,
            significance: 4,
          ),
        ],
      ),
      PathologyGroup(
        id: 'og7',
        order: 7,
        title: '7. Ортодонтическое лечение',
        items: [
          const Pathology(
            id: 'opg_brackets',
            groupId: 'og7',
            name: 'Брекет-система',
            descriptionTemplate:
                'брекет-система на верхнем и нижнем зубных рядах',
            conclusionTemplate:
                'состояние на фоне ортодонтического лечения (брекет-система)',
            frequency: 4,
            scope: PathologyScope.general,
            significance: 1,
          ),
          const Pathology(
            id: 'opg_retainer',
            groupId: 'og7',
            name: 'Несъёмный ретейнер',
            descriptionTemplate:
                'несъёмный ретейнер в области фронтальной группы зубов',
            conclusionTemplate: 'несъёмный ретейнер',
            frequency: 3,
            scope: PathologyScope.general,
            significance: 1,
            omitFromConclusion: true,
          ),
        ],
      ),
      PathologyGroup(
        id: 'og8',
        order: 8,
        title: '8. Костные структуры и образования',
        items: [
          const Pathology(
            id: 'opg_osteosclerosis',
            groupId: 'og8',
            name: 'Участок остеосклероза',
            descriptionTemplate: 'участок остеосклероза',
            conclusionTemplate: 'участок остеосклероза в области {teeth}',
            refStyle: ToothRefStyle.area,
            frequency: 3,
            scope: PathologyScope.tooth,
            significance: 2,
          ),
          const Pathology(
            id: 'opg_lesion_lucent',
            groupId: 'og8',
            name: 'Дополнительное образование (участок просветления)',
            descriptionTemplate:
                'дополнительное образование (участок просветления) '
                'размером {size}, не исключается одонтогенное / '
                'неодонтогенное образование',
            conclusionTemplate: 'дополнительное образование в области {teeth}',
            refStyle: ToothRefStyle.area,
            frequency: 3,
            scope: PathologyScope.tooth,
            significance: 5,
            requiresSize: true,
          ),
          const Pathology(
            id: 'opg_lesion_dense',
            groupId: 'og8',
            name: 'Дополнительное образование повышенной плотности',
            descriptionTemplate:
                'дополнительное образование повышенной плотности '
                'размером {size}',
            conclusionTemplate:
                'дополнительное образование повышенной плотности '
                'в области {teeth}',
            refStyle: ToothRefStyle.area,
            frequency: 2,
            scope: PathologyScope.tooth,
            significance: 4,
            requiresSize: true,
          ),
        ],
      ),
      PathologyGroup(
        id: 'og9',
        order: 9,
        title: '9. Окружающие структуры',
        items: [
          const Pathology(
            id: 'opg_mandibular_canal',
            groupId: 'og9',
            name: 'Нижнечелюстной канал: контур нечёткий / диаметр изменён',
            descriptionTemplate:
                'нижнечелюстной канал {side} прослеживается неотчётливо, '
                'диаметр изменён',
            conclusionTemplate: 'изменения нижнечелюстного канала {side}',
            frequency: 3,
            scope: PathologyScope.general,
            significance: 3,
            requiresSide: true,
          ),
          const Pathology(
            id: 'opg_tmj',
            groupId: 'og9',
            name: 'Изменения ВНЧС (уплощение / деформация головок)',
            descriptionTemplate:
                'головки височно-нижнечелюстного сустава уплощены, '
                'контур неровный {side}',
            conclusionTemplate: 'дегенеративные изменения ВНЧС',
            frequency: 3,
            scope: PathologyScope.general,
            significance: 3,
            requiresSide: true,
          ),
          const Pathology(
            id: 'opg_sinus_opacity',
            groupId: 'og9',
            name: 'Снижение пневматизации гайморовой пазухи',
            descriptionTemplate:
                'снижение пневматизации гайморовой пазухи {side}',
            conclusionTemplate:
                'снижение пневматизации гайморовой пазухи {side}',
            frequency: 3,
            scope: PathologyScope.general,
            significance: 3,
            requiresSide: true,
          ),
        ],
      ),
    ];

    return [
      for (final g in raw)
        PathologyGroup(
          id: g.id,
          order: g.order,
          title: g.title,
          items: [...g.items]
            ..sort((a, b) => b.frequency.compareTo(a.frequency)),
        ),
    ];
  }
}
