import '../../domain/entities/pathology.dart';

/// Статический справочник патологий: 10 групп, внутри — сортировка
/// по убыванию частоты (★).
///
/// [Pathology.conclusionTemplate] — нозологическая формулировка для
/// заключения (именительный падеж, находка впереди, {teeth} — место
/// номеров зубов, {fdi} — только номера, без «зуба»).
/// [Pathology.significance] — клиническая значимость 1–5,
/// задаёт порядок строк заключения по убыванию.
class PathologyCatalog {
  PathologyCatalog._();

  static final List<PathologyGroup> groups = _buildGroups();

  static final Map<String, Pathology> byId = {
    for (final g in groups)
      for (final p in g.items) p.id: p,
  };

  static List<PathologyGroup> _buildGroups() {
    final raw = <PathologyGroup>[
      PathologyGroup(
        id: 'g1',
        order: 1,
        title: '1. Изменения твёрдых тканей зуба',
        items: [
          const Pathology(
            id: 'g1_secondary_filling',
            groupId: 'g1',
            name: 'Вторичный процесс под пломбой',
            descriptionTemplate: 'вторичный процесс под пломбой',
            conclusionTemplate: 'вторичный процесс под пломбой {teeth}',
            frequency: 5,
            scope: PathologyScope.tooth,
            significance: 3,
          ),
          const Pathology(
            id: 'g1_secondary_crown',
            groupId: 'g1',
            name: 'Вторичный процесс под коронкой',
            descriptionTemplate: 'вторичный процесс под коронкой',
            conclusionTemplate: 'вторичный процесс под коронкой {teeth}',
            frequency: 4,
            scope: PathologyScope.tooth,
            significance: 3,
          ),
          const Pathology(
            id: 'g1_cavity_occlusal',
            groupId: 'g1',
            name: 'Полость на жевательной поверхности',
            descriptionTemplate: 'полость на жевательной поверхности',
            conclusionTemplate: 'полость на жевательной поверхности {teeth}',
            frequency: 4,
            scope: PathologyScope.tooth,
            significance: 3,
          ),
          const Pathology(
            id: 'g1_cavity_contact',
            groupId: 'g1',
            name: 'Полость на контакте с … зубом',
            descriptionTemplate: 'полость на контакте с {adjacent} зубом',
            conclusionTemplate:
                'полость {teeth} на контакте с {adjacent} зубом',
            frequency: 4,
            scope: PathologyScope.tooth,
            significance: 3,
            requiresAdjacentTooth: true,
          ),
          const Pathology(
            id: 'g1_hidden_cavity',
            groupId: 'g1',
            name: 'Скрытая полость на контакте / жевательной поверхности',
            descriptionTemplate:
                'скрытая полость на контакте / жевательной поверхности',
            conclusionTemplate:
                'скрытая полость {teeth} на контакте / жевательной поверхности',
            frequency: 3,
            scope: PathologyScope.tooth,
            significance: 3,
          ),
          const Pathology(
            id: 'g1_fissure',
            groupId: 'g1',
            name: 'Фиссурные изменения / фиссурная полость',
            descriptionTemplate: 'фиссурные изменения / фиссурная полость',
            conclusionTemplate:
                'фиссурные изменения / фиссурная полость {teeth}',
            frequency: 3,
            scope: PathologyScope.tooth,
            significance: 3,
          ),
          const Pathology(
            id: 'g1_cavity_near_pulp',
            groupId: 'g1',
            name:
                'Полость коронковой части, вплотную прилегающая к пульпарной камере',
            descriptionTemplate:
                'полость коронковой части, вплотную прилегающая к пульпарной камере',
            conclusionTemplate:
                'полость коронковой части {teeth}, вплотную прилегающая к пульпарной камере',
            frequency: 3,
            scope: PathologyScope.tooth,
            significance: 4,
          ),
          const Pathology(
            id: 'g1_crown_destruction',
            groupId: 'g1',
            name: 'Деструкция коронковой части',
            descriptionTemplate: 'деструкция коронковой части',
            conclusionTemplate: 'деструкция коронковой части {teeth}',
            frequency: 3,
            scope: PathologyScope.tooth,
            significance: 3,
          ),
          const Pathology(
            id: 'g1_density_reduction',
            groupId: 'g1',
            name:
                'Снижение плотности тканей зуба (на контакте / жевательной поверхности)',
            descriptionTemplate:
                'снижение плотности тканей зуба (на контакте / жевательной поверхности)',
            conclusionTemplate: 'снижение плотности твёрдых тканей {teeth}',
            frequency: 3,
            scope: PathologyScope.tooth,
            significance: 3,
          ),
          const Pathology(
            id: 'g1_wedge_defect',
            groupId: 'g1',
            name: 'Клиновидный дефект с вестибулярной стороны в области шейки',
            descriptionTemplate:
                'клиновидный дефект с вестибулярной стороны в области шейки',
            conclusionTemplate: 'клиновидный дефект {teeth} в области шейки',
            frequency: 2,
            scope: PathologyScope.tooth,
            significance: 3,
          ),
          const Pathology(
            id: 'g1_cervical_root_cavity',
            groupId: 'g1',
            name: 'Полость в области шейки зуба с распространением на корень',
            descriptionTemplate:
                'полость в области шейки зуба с распространением на корень',
            conclusionTemplate:
                'полость в области шейки {teeth} с распространением на корень',
            frequency: 2,
            scope: PathologyScope.tooth,
            significance: 3,
          ),
        ],
      ),
      PathologyGroup(
        id: 'g2',
        order: 2,
        title: '2. Периапикальные изменения (деструкции)',
        items: [
          const Pathology(
            id: 'g2_apical_destruction',
            groupId: 'g2',
            name: 'Деструкция в апикальной области до … мм',
            descriptionTemplate:
                'деструкция в апикальной области размером {size}',
            conclusionTemplate:
                'очаговая деструкция в апикальной области {teeth}',
            frequency: 5,
            scope: PathologyScope.tooth,
            significance: 5,
            requiresSize: true,
            defaultSizeCount: 2,
          ),
          const Pathology(
            id: 'g2_apical_destruction_clear',
            groupId: 'g2',
            name:
                'Деструкция в апикальной области с ровными/чёткими контурами, размером …',
            descriptionTemplate:
                'деструкция в апикальной области с ровными/чёткими контурами, размером {size}',
            conclusionTemplate:
                'очаговая деструкция в апикальной области {teeth} с ровными/чёткими контурами',
            frequency: 4,
            scope: PathologyScope.tooth,
            significance: 5,
            requiresSize: true,
          ),
          const Pathology(
            id: 'g2_prolapse_sinus',
            groupId: 'g2',
            name: 'Деструкция пролабирует в полость гайморовой пазухи',
            descriptionTemplate:
                'деструкция пролабирует в полость гайморовой пазухи',
            conclusionTemplate:
                'деструкция {teeth}, пролабирующая в полость гайморовой пазухи',
            frequency: 4,
            scope: PathologyScope.tooth,
            significance: 5,
          ),
          const Pathology(
            id: 'g2_pdl_widening',
            groupId: 'g2',
            name:
                'Расширение периодонтального пространства в апикальной области',
            descriptionTemplate:
                'расширение периодонтального пространства в апикальной области',
            conclusionTemplate:
                'расширение периодонтальной щели в апикальной области {teeth}',
            frequency: 4,
            scope: PathologyScope.tooth,
            significance: 4,
          ),
          const Pathology(
            id: 'g2_sinus_wall',
            groupId: 'g2',
            name:
                'Деструкция с нарушением целостности нижней стенки гайморовой пазухи',
            descriptionTemplate:
                'деструкция с нарушением целостности нижней стенки гайморовой пазухи',
            conclusionTemplate:
                'деструкция {teeth} с нарушением целостности нижней стенки гайморовой пазухи',
            frequency: 3,
            scope: PathologyScope.tooth,
            significance: 5,
          ),
          const Pathology(
            id: 'g2_to_furcation',
            groupId: 'g2',
            name:
                'Периапикальная деструкция с распространением в область фуркации',
            descriptionTemplate:
                'периапикальная деструкция с распространением в область фуркации',
            conclusionTemplate:
                'периапикальная деструкция {fdi} с распространением в область фуркации',
            frequency: 3,
            scope: PathologyScope.tooth,
            significance: 5,
          ),
          const Pathology(
            id: 'g2_cortical_defect',
            groupId: 'g2',
            name: 'Деструкция с дефектом кортикальной пластины вестибулярно',
            descriptionTemplate:
                'деструкция с дефектом кортикальной пластины вестибулярно',
            conclusionTemplate:
                'деструкция с дефектом вестибулярной кортикальной пластины в области {teeth}',
            frequency: 3,
            scope: PathologyScope.tooth,
            significance: 5,
          ),
          const Pathology(
            id: 'g2_adjacent_apex',
            groupId: 'g2',
            name: 'Деструкция с распространением на апекс соседнего зуба',
            descriptionTemplate:
                'деструкция с распространением на апекс соседнего зуба',
            conclusionTemplate:
                'деструкция {teeth} с распространением на апекс соседнего зуба',
            frequency: 2,
            scope: PathologyScope.tooth,
            significance: 5,
          ),
          const Pathology(
            id: 'g2_osteosclerosis',
            groupId: 'g2',
            name:
                'Деструкция в апикальной области с перифокальным остеосклерозом',
            descriptionTemplate:
                'деструкция в апикальной области с перифокальным остеосклерозом',
            conclusionTemplate:
                'очаговая деструкция в апикальной области {teeth} с перифокальным остеосклерозом',
            frequency: 2,
            scope: PathologyScope.tooth,
            significance: 5,
          ),
          const Pathology(
            id: 'g2_mandibular_canal',
            groupId: 'g2',
            name: 'Деструкция с вовлечением нижнечелюстного канала',
            descriptionTemplate:
                'деструкция с вовлечением нижнечелюстного канала',
            conclusionTemplate:
                'деструкция {teeth} с вовлечением нижнечелюстного канала',
            frequency: 2,
            scope: PathologyScope.tooth,
            significance: 5,
          ),
        ],
      ),
      PathologyGroup(
        id: 'g3',
        order: 3,
        title: '3. Изменения в области фуркации',
        items: [
          const Pathology(
            id: 'g3_furcation',
            groupId: 'g3',
            name: 'Деструкция в области фуркации',
            descriptionTemplate: 'деструкция в области фуркации',
            conclusionTemplate:
                'признаки деструкции костной ткани в области фуркации {teeth}',
            frequency: 5,
            scope: PathologyScope.tooth,
            significance: 5,
          ),
          const Pathology(
            id: 'g3_furcation_apices',
            groupId: 'g3',
            name: 'Деструкция в области фуркации с распространением на апексы',
            descriptionTemplate:
                'деструкция в области фуркации с распространением на апексы',
            conclusionTemplate:
                'признаки деструкции костной ткани в области фуркации с распространением на апексы {teeth}',
            frequency: 3,
            scope: PathologyScope.tooth,
            significance: 5,
          ),
          const Pathology(
            id: 'g3_furcation_crack',
            groupId: 'g3',
            name: 'Трещина в области фуркации (перфорация-?)',
            descriptionTemplate: 'трещина в области фуркации (перфорация-?)',
            conclusionTemplate:
                'трещина в области фуркации {teeth} (перфорация-?)',
            frequency: 3,
            scope: PathologyScope.tooth,
            significance: 5,
          ),
          const Pathology(
            id: 'g3_roots_separated',
            groupId: 'g3',
            name: 'Деструкция в области фуркации, корни разобщены',
            descriptionTemplate:
                'деструкция в области фуркации, корни разобщены',
            conclusionTemplate:
                'деструкция в области фуркации {teeth} с разобщением корней',
            frequency: 2,
            scope: PathologyScope.tooth,
            significance: 5,
          ),
          const Pathology(
            id: 'g3_lingual_plate',
            groupId: 'g3',
            name:
                'Корковая пластина с язычной стороны на уровне фуркации не прослеживается',
            descriptionTemplate:
                'корковая пластина с язычной стороны на уровне фуркации не прослеживается',
            conclusionTemplate:
                'отсутствие корковой пластины с язычной стороны на уровне фуркации {teeth}',
            frequency: 2,
            scope: PathologyScope.tooth,
            significance: 5,
          ),
        ],
      ),
      PathologyGroup(
        id: 'g4',
        order: 4,
        title: '4. Корневые каналы и пломбирование',
        items: [
          const Pathology(
            id: 'g4_endo_homogeneous',
            groupId: 'g4',
            name:
                'Признаки эндодонтического лечения, каналы заполнены гомогенно',
            descriptionTemplate:
                'признаки эндодонтического лечения, каналы заполнены гомогенно',
            conclusionTemplate:
                'состояние после эндодонтического лечения {teeth} (каналы обтурированы гомогенно)',
            frequency: 5,
            scope: PathologyScope.tooth,
            significance: 2,
          ),
          const Pathology(
            id: 'g4_partial_obturation',
            groupId: 'g4',
            name: 'Корневые каналы обтурированы частично',
            descriptionTemplate: 'корневые каналы обтурированы частично',
            conclusionTemplate: 'корневые каналы {teeth} обтурированы частично',
            frequency: 5,
            scope: PathologyScope.tooth,
            significance: 4,
          ),
          const Pathology(
            id: 'g4_no_filling',
            groupId: 'g4',
            name: 'Корневые каналы без следов пломбировки',
            descriptionTemplate: 'корневые каналы без следов пломбировки',
            conclusionTemplate: 'корневые каналы {teeth} не обтурированы',
            frequency: 4,
            scope: PathologyScope.tooth,
            significance: 4,
          ),
          const Pathology(
            id: 'g4_material_beyond_apex',
            groupId: 'g4',
            name:
                'Выведение пломбировочного материала за апекс в костную ткань',
            descriptionTemplate:
                'выведение пломбировочного материала за апекс в костную ткань',
            conclusionTemplate:
                'выведение пломбировочного материала {teeth} за апекс в костную ткань',
            frequency: 4,
            scope: PathologyScope.tooth,
            significance: 4,
          ),
          const Pathology(
            id: 'g4_overhanging',
            groupId: 'g4',
            name: 'Нависающие края пломбы / коронки',
            descriptionTemplate: 'нависающие края пломбы / коронки',
            conclusionTemplate: 'нависающие края пломбы / коронки {teeth}',
            frequency: 4,
            scope: PathologyScope.tooth,
            significance: 3,
          ),
          const Pathology(
            id: 'g4_mb2',
            groupId: 'g4',
            name: 'МБ2 без следов пломбировки',
            descriptionTemplate: 'МБ2 без следов пломбировки',
            conclusionTemplate: 'необтурированный канал МБ2 {teeth}',
            frequency: 3,
            scope: PathologyScope.tooth,
            significance: 4,
          ),
          const Pathology(
            id: 'g4_underfilling',
            groupId: 'g4',
            name: 'Недопломбировка … мм',
            descriptionTemplate: 'недопломбировка {size}',
            conclusionTemplate: 'недопломбировка корневого канала {teeth}',
            frequency: 3,
            scope: PathologyScope.tooth,
            significance: 4,
            requiresSize: true,
          ),
          const Pathology(
            id: 'g4_material_in_sinus',
            groupId: 'g4',
            name:
                'Выведение пломбировочного материала в полость гайморовой пазухи',
            descriptionTemplate:
                'выведение пломбировочного материала в полость гайморовой пазухи',
            conclusionTemplate:
                'выведение пломбировочного материала {teeth} в полость гайморовой пазухи',
            frequency: 3,
            scope: PathologyScope.tooth,
            significance: 4,
          ),
          const Pathology(
            id: 'g4_restoration_fit',
            groupId: 'g4',
            name: 'Нарушение прилегания реставрации / пломбы',
            descriptionTemplate: 'нарушение прилегания реставрации / пломбы',
            conclusionTemplate:
                'нарушение прилегания реставрации / пломбы {teeth}',
            frequency: 3,
            scope: PathologyScope.tooth,
            significance: 3,
          ),
          const Pathology(
            id: 'g4_post_off_axis',
            groupId: 'g4',
            name: 'Штифт установлен не по оси корневого канала',
            descriptionTemplate: 'штифт установлен не по оси корневого канала',
            conclusionTemplate:
                'штифт {teeth} установлен не по оси корневого канала',
            frequency: 2,
            scope: PathologyScope.tooth,
            significance: 3,
          ),
          const Pathology(
            id: 'g4_material_in_pulp',
            groupId: 'g4',
            name: 'Пломбировочный материал в пульпарной камере',
            descriptionTemplate: 'пломбировочный материал в пульпарной камере',
            conclusionTemplate:
                'пломбировочный материал в пульпарной камере {teeth}',
            frequency: 2,
            scope: PathologyScope.tooth,
            significance: 3,
          ),
        ],
      ),
      PathologyGroup(
        id: 'g5',
        order: 5,
        title: '5. Пародонтит / потеря костной ткани',
        items: [
          const Pathology(
            id: 'g5_bone_height',
            groupId: 'g5',
            name: 'Снижение высоты альвеолярного гребня / костной ткани',
            descriptionTemplate:
                'снижение высоты альвеолярного гребня / костной ткани',
            conclusionTemplate:
                'снижение высоты альвеолярного гребня в области {teeth}',
            frequency: 5,
            scope: PathologyScope.tooth,
            significance: 4,
          ),
          const Pathology(
            id: 'g5_ridge_reduction',
            groupId: 'g5',
            name: 'Снижение альвеолярных гребней',
            descriptionTemplate: 'снижение альвеолярных гребней',
            conclusionTemplate: 'снижение альвеолярных гребней',
            frequency: 4,
            scope: PathologyScope.general,
            significance: 4,
          ),
          const Pathology(
            id: 'g5_bone_pocket',
            groupId: 'g5',
            name: 'Костный карман (мезиально / дистально) до … длины корня',
            descriptionTemplate:
                'костный карман (мезиально / дистально) {size}',
            conclusionTemplate: 'костный карман в области {teeth}',
            frequency: 5,
            scope: PathologyScope.tooth,
            significance: 4,
            requiresSize: true,
          ),
          const Pathology(
            id: 'g5_calculus',
            groupId: 'g5',
            name: 'Зубные камни / поддесневые отложения',
            descriptionTemplate: 'зубные камни / поддесневые отложения',
            conclusionTemplate:
                'зубные камни / поддесневые отложения в области {teeth}',
            frequency: 4,
            scope: PathologyScope.tooth,
            significance: 3,
          ),
          const Pathology(
            id: 'g5_deep_pockets',
            groupId: 'g5',
            name: 'Глубокие костные карманы',
            descriptionTemplate: 'глубокие костные карманы',
            conclusionTemplate: 'глубокие костные карманы в области {teeth}',
            frequency: 4,
            scope: PathologyScope.tooth,
            significance: 5,
          ),
          const Pathology(
            id: 'g5_circular_destruction',
            groupId: 'g5',
            name: 'Циркулярная деструкция вокруг корней до апексов',
            descriptionTemplate:
                'циркулярная деструкция вокруг корней до апексов',
            conclusionTemplate:
                'циркулярная деструкция вокруг корней {teeth} до апексов',
            frequency: 3,
            scope: PathologyScope.tooth,
            significance: 5,
          ),
          const Pathology(
            id: 'g5_generalized',
            groupId: 'g5',
            name: 'Генерализованный пародонтит / пародонтоз',
            descriptionTemplate:
                'генерализованное снижение высоты костной ткани альвеолярных гребней',
            conclusionTemplate:
                'признаки генерализованного пародонтита / пародонтоза',
            frequency: 3,
            scope: PathologyScope.general,
            significance: 4,
          ),
          const Pathology(
            id: 'g5_apex_resorption',
            groupId: 'g5',
            name: 'Резорбция апексов / корня',
            descriptionTemplate: 'резорбция апексов / корня',
            conclusionTemplate: 'резорбция апексов / корня {teeth}',
            frequency: 3,
            scope: PathologyScope.tooth,
            significance: 4,
          ),
          const Pathology(
            id: 'g5_apex_lysis',
            groupId: 'g5',
            name: 'Частичный лизис апексов',
            descriptionTemplate: 'частичный лизис апексов',
            conclusionTemplate: 'частичный лизис апексов {teeth}',
            frequency: 2,
            scope: PathologyScope.tooth,
            significance: 4,
          ),
        ],
      ),
      PathologyGroup(
        id: 'g6',
        order: 6,
        title: '6. Ретенция, дистопия, адентия',
        items: [
          const Pathology(
            id: 'g6_retention',
            groupId: 'g6',
            name: 'Ретинирован, дистопирован',
            descriptionTemplate: 'ретинирован, дистопирован',
            conclusionTemplate: 'ретенция и дистопия {teeth}',
            frequency: 5,
            scope: PathologyScope.tooth,
            significance: 3,
          ),
          const Pathology(
            id: 'g6_popov_godon',
            groupId: 'g6',
            name: 'Феномен Попова-Годона',
            descriptionTemplate: 'феномен Попова-Годона',
            conclusionTemplate: 'феномен Попова-Годона {teeth}',
            frequency: 4,
            scope: PathologyScope.tooth,
            significance: 3,
          ),
          const Pathology(
            id: 'g6_partial_adentia',
            groupId: 'g6',
            name: 'Частичная вторичная адентия',
            descriptionTemplate: 'частичная вторичная адентия',
            conclusionTemplate: 'частичная вторичная адентия',
            frequency: 4,
            scope: PathologyScope.general,
            significance: 2,
          ),
          const Pathology(
            id: 'g6_retention_roots',
            groupId: 'g6',
            name: 'Ретинирован, дистопирован, упирается в корни соседнего зуба',
            descriptionTemplate:
                'ретинирован, дистопирован, упирается в корни соседнего зуба',
            conclusionTemplate:
                'ретенция и дистопия {teeth} с упором в корни соседнего зуба',
            frequency: 3,
            scope: PathologyScope.tooth,
            significance: 3,
          ),
          const Pathology(
            id: 'g6_radix',
            groupId: 'g6',
            name: 'Radix (остаток корня)',
            descriptionTemplate: 'Radix (остаток корня)',
            extractedTemplate: 'Radix (остаток корня)',
            conclusionTemplate: 'Radix (остаток корня) в области {teeth}',
            frequency: 3,
            scope: PathologyScope.tooth,
            significance: 3,
            refStyle: ToothRefStyle.area,
          ),
          const Pathology(
            id: 'g6_root_fragment',
            groupId: 'g6',
            name: 'Фрагмент корня в костной ткани / мягких тканях',
            descriptionTemplate:
                'фрагмент корня в костной ткани / мягких тканях',
            conclusionTemplate:
                'фрагмент корня в костной ткани / мягких тканях в области {teeth}',
            frequency: 3,
            scope: PathologyScope.tooth,
            significance: 3,
            refStyle: ToothRefStyle.area,
          ),
          const Pathology(
            id: 'g6_full_adentia',
            groupId: 'g6',
            name: 'Полная адентия',
            descriptionTemplate: 'полная адентия',
            conclusionTemplate: 'полная адентия',
            frequency: 2,
            scope: PathologyScope.general,
            significance: 2,
          ),
          const Pathology(
            id: 'g6_supernumerary',
            groupId: 'g6',
            name: 'Сверхкомплектный зуб',
            descriptionTemplate: 'сверхкомплектный зуб',
            conclusionTemplate: 'сверхкомплектный зуб в области {teeth}',
            frequency: 2,
            scope: PathologyScope.tooth,
            significance: 3,
            refStyle: ToothRefStyle.area,
          ),
        ],
      ),
      PathologyGroup(
        id: 'g7',
        order: 7,
        title: '7. ЛОР-патология: гайморовы пазухи',
        items: [
          const Pathology(
            id: 'g7_soft_tissue_wall',
            groupId: 'g7',
            name: 'Мягкотканый компонент по нижней стенке до … мм',
            descriptionTemplate:
                'мягкотканый компонент по нижней стенке гайморовой пазухи {size}',
            conclusionTemplate:
                'мягкотканый компонент по нижней стенке гайморовой пазухи',
            frequency: 5,
            scope: PathologyScope.general,
            significance: 3,
            requiresSize: true,
            requiresSide: true,
          ),
          const Pathology(
            id: 'g7_mucosa_hypertrophy',
            groupId: 'g7',
            name:
                'Гипертрофия слизистой нижней стенки гайморовой пазухи до … мм',
            descriptionTemplate:
                'гипертрофия слизистой нижней стенки гайморовой пазухи {size}',
            conclusionTemplate:
                'гипертрофия слизистой нижней стенки гайморовой пазухи',
            frequency: 4,
            scope: PathologyScope.general,
            significance: 3,
            requiresSize: true,
            requiresSide: true,
          ),
          const Pathology(
            id: 'g7_total_filling',
            groupId: 'g7',
            name: 'Тотальное заполнение мягкотканым компонентом',
            descriptionTemplate:
                'тотальное заполнение гайморовой пазухи мягкотканым компонентом',
            conclusionTemplate:
                'тотальное заполнение гайморовой пазухи мягкотканым компонентом',
            frequency: 3,
            scope: PathologyScope.general,
            significance: 5,
            requiresSide: true,
            chipGroup: 'g7_sinus_filling',
          ),
          const Pathology(
            id: 'g7_subtotal_filling',
            groupId: 'g7',
            name: 'Субтотальное заполнение мягкотканым компонентом',
            descriptionTemplate:
                'субтотальное заполнение гайморовой пазухи мягкотканым компонентом',
            conclusionTemplate:
                'субтотальное заполнение гайморовой пазухи мягкотканым компонентом',
            frequency: 3,
            scope: PathologyScope.general,
            significance: 5,
            requiresSide: true,
            chipGroup: 'g7_sinus_filling',
          ),
          const Pathology(
            id: 'g7_gas_bubbles',
            groupId: 'g7',
            name: 'Мягкотканый компонент с пузырьками газа на поверхности',
            descriptionTemplate:
                'мягкотканый компонент гайморовой пазухи с пузырьками газа на поверхности',
            conclusionTemplate:
                'мягкотканый компонент гайморовой пазухи с пузырьками газа на поверхности',
            frequency: 3,
            scope: PathologyScope.general,
            significance: 3,
            requiresSide: true,
          ),
          const Pathology(
            id: 'g7_fluid_level',
            groupId: 'g7',
            name: 'Мягкотканый компонент с горизонтальным уровнем жидкости',
            descriptionTemplate:
                'мягкотканый компонент гайморовой пазухи с горизонтальным уровнем жидкости',
            conclusionTemplate:
                'мягкотканый компонент гайморовой пазухи с горизонтальным уровнем жидкости',
            frequency: 3,
            scope: PathologyScope.general,
            significance: 5,
            requiresSide: true,
          ),
          const Pathology(
            id: 'g7_cyst',
            groupId: 'g7',
            name: 'Кистовидное утолщение слизистой гайморовой пазухи',
            descriptionTemplate:
                'кистовидное утолщение слизистой гайморовой пазухи',
            conclusionTemplate:
                'кистовидное утолщение слизистой гайморовой пазухи',
            frequency: 3,
            scope: PathologyScope.general,
            significance: 3,
            requiresSide: true,
          ),
          const Pathology(
            id: 'g7_ostium',
            groupId: 'g7',
            name:
                'Естественное соустье не прослеживается / прослеживается частично',
            descriptionTemplate:
                'естественное соустье гайморовой пазухи не прослеживается / прослеживается частично',
            conclusionTemplate:
                'нарушение проходимости естественного соустья гайморовой пазухи',
            frequency: 3,
            scope: PathologyScope.general,
            significance: 3,
            requiresSide: true,
          ),
          const Pathology(
            id: 'g7_odontogenic',
            groupId: 'g7',
            name: 'Одонтогенные изменения гайморовой пазухи',
            descriptionTemplate: 'одонтогенные изменения гайморовой пазухи',
            conclusionTemplate: 'одонтогенные изменения гайморовой пазухи',
            frequency: 3,
            scope: PathologyScope.general,
            significance: 3,
            requiresSide: true,
          ),
        ],
      ),
      PathologyGroup(
        id: 'g8',
        order: 8,
        title: '8. ЛОР-патология: другие пазухи и структуры',
        items: [
          const Pathology(
            id: 'g8_septum_spike',
            groupId: 'g8',
            name: 'Шип перегородки полости носа в … сторону',
            descriptionTemplate: 'шип перегородки полости носа {direction}',
            conclusionTemplate: 'шип перегородки полости носа {direction}',
            frequency: 5,
            scope: PathologyScope.general,
            significance: 3,
            requiresDirection: true,
          ),
          const Pathology(
            id: 'g8_ethmoid',
            groupId: 'g8',
            name: 'Снижение воздушности ячеек решётчатого лабиринта',
            descriptionTemplate:
                'снижение воздушности ячеек решётчатого лабиринта',
            conclusionTemplate:
                'снижение воздушности ячеек решётчатого лабиринта',
            frequency: 4,
            scope: PathologyScope.general,
            significance: 3,
          ),
          const Pathology(
            id: 'g8_septum_deviation',
            groupId: 'g8',
            name: 'Искривление носовой перегородки',
            descriptionTemplate: 'искривление носовой перегородки',
            conclusionTemplate: 'искривление носовой перегородки',
            frequency: 4,
            scope: PathologyScope.general,
            significance: 3,
          ),
          const Pathology(
            id: 'g8_pansinusitis',
            groupId: 'g8',
            name: 'Пансинусит',
            descriptionTemplate:
                'снижение воздушности всех околоносовых пазух (пансинусит)',
            conclusionTemplate: 'пансинусит',
            frequency: 3,
            scope: PathologyScope.general,
            significance: 4,
          ),
          const Pathology(
            id: 'g8_sphenoid',
            groupId: 'g8',
            name: 'Мягкотканый компонент в клиновидной пазухе',
            descriptionTemplate: 'мягкотканый компонент в клиновидной пазухе',
            conclusionTemplate: 'мягкотканый компонент в клиновидной пазухе',
            frequency: 3,
            scope: PathologyScope.general,
            significance: 3,
          ),
          const Pathology(
            id: 'g8_lymphoid',
            groupId: 'g8',
            name: 'Гиперплазия лимфоидного кольца свода носоглотки',
            descriptionTemplate:
                'гиперплазия лимфоидного кольца свода носоглотки',
            conclusionTemplate:
                'гиперплазия лимфоидного кольца свода носоглотки',
            frequency: 3,
            scope: PathologyScope.general,
            significance: 3,
          ),
          const Pathology(
            id: 'g8_tonsilloliths',
            groupId: 'g8',
            name: 'Тонзиллолиты / конкременты в миндалинах',
            descriptionTemplate: 'тонзиллолиты / конкременты в миндалинах',
            conclusionTemplate: 'тонзиллолиты / конкременты в миндалинах',
            frequency: 3,
            scope: PathologyScope.general,
            significance: 3,
          ),
          const Pathology(
            id: 'g8_frontal_mucosa',
            groupId: 'g8',
            name: 'Утолщение слизистой лобного синуса',
            descriptionTemplate: 'утолщение слизистой лобного синуса',
            conclusionTemplate: 'утолщение слизистой лобного синуса',
            frequency: 2,
            scope: PathologyScope.general,
            significance: 3,
            requiresSide: true,
          ),
          const Pathology(
            id: 'g8_hypoplasia',
            groupId: 'g8',
            name: 'Гипоплазия гайморовой пазухи / лобного синуса',
            descriptionTemplate:
                'гипоплазия гайморовой пазухи / лобного синуса',
            conclusionTemplate: 'гипоплазия гайморовой пазухи / лобного синуса',
            frequency: 2,
            scope: PathologyScope.general,
            significance: 2,
            requiresSide: true,
          ),
        ],
      ),
      PathologyGroup(
        id: 'g9',
        order: 9,
        title: '9. Имплантаты и постоперационные изменения',
        items: [
          const Pathology(
            id: 'g9_implants_ok',
            groupId: 'g9',
            name:
                'Дентальные имплантаты, положение их внутрикостное, признаков периимплантита не определяется',
            descriptionTemplate:
                'дентальные имплантаты, положение их внутрикостное, признаков периимплантита не определяется',
            conclusionTemplate:
                'дентальные имплантаты в области {teeth} без признаков периимплантита',
            frequency: 3,
            scope: PathologyScope.tooth,
            significance: 1,
            refStyle: ToothRefStyle.area,
          ),
          const Pathology(
            id: 'g9_implant_bone_loss',
            groupId: 'g9',
            name: 'Деструкция / снижение костной ткани вокруг имплантата',
            descriptionTemplate:
                'деструкция / снижение костной ткани вокруг имплантата',
            conclusionTemplate:
                'деструкция / снижение костной ткани вокруг имплантата в области {teeth}',
            frequency: 2,
            scope: PathologyScope.tooth,
            significance: 5,
            refStyle: ToothRefStyle.area,
          ),
          const Pathology(
            id: 'g9_sinus_lift',
            groupId: 'g9',
            name: 'Состояние после синуслифтинга',
            descriptionTemplate: 'состояние после синуслифтинга',
            conclusionTemplate: 'состояние после синуслифтинга',
            frequency: 2,
            scope: PathologyScope.general,
            significance: 2,
            requiresSide: true,
          ),
          const Pathology(
            id: 'g9_socket',
            groupId: 'g9',
            name: 'Лунка после удаления без следов оссификации',
            descriptionTemplate: 'лунка после удаления без следов оссификации',
            extractedTemplate: 'лунка после удаления без следов оссификации',
            conclusionTemplate:
                'лунка после удаления без следов оссификации в области {teeth}',
            frequency: 2,
            scope: PathologyScope.tooth,
            significance: 2,
            refStyle: ToothRefStyle.area,
          ),
          const Pathology(
            id: 'g9_oroantral',
            groupId: 'g9',
            name: 'Ороантральное соустье / сообщение',
            descriptionTemplate: 'ороантральное соустье / сообщение',
            conclusionTemplate: 'ороантральное соустье / сообщение',
            frequency: 2,
            scope: PathologyScope.general,
            significance: 4,
            requiresSide: true,
          ),
        ],
      ),
      PathologyGroup(
        id: 'g10',
        order: 10,
        title: '10. Прочее',
        items: [
          const Pathology(
            id: 'g10_enostosis',
            groupId: 'g10',
            name: 'Эностоз / участок остеосклероза',
            descriptionTemplate: 'эностоз / участок остеосклероза',
            conclusionTemplate:
                'эностоз / участок остеосклероза в области {teeth}',
            frequency: 2,
            scope: PathologyScope.tooth,
            significance: 2,
          ),
          const Pathology(
            id: 'g10_tmj',
            groupId: 'g10',
            name: 'Дегенеративные изменения ВНЧС',
            descriptionTemplate: 'дегенеративные изменения ВНЧС',
            conclusionTemplate: 'дегенеративные изменения ВНЧС',
            frequency: 2,
            scope: PathologyScope.general,
            significance: 3,
            requiresSide: true,
          ),
          const Pathology(
            id: 'g10_cod',
            groupId: 'g10',
            name: 'Цементно-костная дисплазия',
            descriptionTemplate: 'цементно-костная дисплазия',
            conclusionTemplate: 'цементно-костная дисплазия',
            frequency: 1,
            scope: PathologyScope.general,
            significance: 3,
          ),
          const Pathology(
            id: 'g10_adamantoma',
            groupId: 'g10',
            name: 'Адамантома (эмалевый бугорок)',
            descriptionTemplate: 'адамантома (эмалевый бугорок)',
            conclusionTemplate: 'адамантома (эмалевый бугорок) {teeth}',
            frequency: 1,
            scope: PathologyScope.tooth,
            significance: 2,
          ),
          const Pathology(
            id: 'g10_odontoma',
            groupId: 'g10',
            name: 'Одонтома',
            descriptionTemplate: 'одонтома',
            conclusionTemplate: 'одонтома',
            frequency: 1,
            scope: PathologyScope.general,
            significance: 3,
          ),
          const Pathology(
            id: 'g10_phleboliths',
            groupId: 'g10',
            name: 'Флеболиты',
            descriptionTemplate: 'флеболиты',
            conclusionTemplate: 'флеболиты',
            frequency: 1,
            scope: PathologyScope.general,
            significance: 2,
          ),
        ],
      ),
    ];

    return raw
        .map(
          (g) => PathologyGroup(
            id: g.id,
            title: g.title,
            order: g.order,
            items: [...g.items]
              ..sort((a, b) => b.frequency.compareTo(a.frequency)),
          ),
        )
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));
  }
}
