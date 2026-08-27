import '../../domain/entities/pathology.dart';

/// Статический справочник патологий: 10 групп, внутри — сортировка
/// по убыванию частоты (★).
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
            conclusionText: 'вторичному процессу под пломбой',
            frequency: 5,
            scope: PathologyScope.tooth,
          ),
          const Pathology(
            id: 'g1_secondary_crown',
            groupId: 'g1',
            name: 'Вторичный процесс под коронкой',
            descriptionTemplate: 'вторичный процесс под коронкой',
            conclusionText: 'вторичному процессу под коронкой',
            frequency: 4,
            scope: PathologyScope.tooth,
          ),
          const Pathology(
            id: 'g1_cavity_occlusal',
            groupId: 'g1',
            name: 'Полость на жевательной поверхности',
            descriptionTemplate: 'полость на жевательной поверхности',
            conclusionText: 'полости на жевательной поверхности',
            frequency: 4,
            scope: PathologyScope.tooth,
          ),
          const Pathology(
            id: 'g1_cavity_contact',
            groupId: 'g1',
            name: 'Полость на контакте с … зубом',
            descriptionTemplate: 'полость на контакте с {adjacent} зубом',
            conclusionText: 'полости на контакте с {adjacent} зубом',
            frequency: 4,
            scope: PathologyScope.tooth,
            requiresAdjacentTooth: true,
          ),
          const Pathology(
            id: 'g1_hidden_cavity',
            groupId: 'g1',
            name: 'Скрытая полость на контакте / жевательной поверхности',
            descriptionTemplate:
                'скрытая полость на контакте / жевательной поверхности',
            conclusionText:
                'скрытой полости на контакте / жевательной поверхности',
            frequency: 3,
            scope: PathologyScope.tooth,
          ),
          const Pathology(
            id: 'g1_fissure',
            groupId: 'g1',
            name: 'Фиссурные изменения / фиссурная полость',
            descriptionTemplate: 'фиссурные изменения / фиссурная полость',
            conclusionText: 'фиссурным изменениям / фиссурной полости',
            frequency: 3,
            scope: PathologyScope.tooth,
          ),
          const Pathology(
            id: 'g1_cavity_near_pulp',
            groupId: 'g1',
            name:
                'Полость коронковой части, вплотную прилегающая к пульпарной камере',
            descriptionTemplate:
                'полость коронковой части, вплотную прилегающая к пульпарной камере',
            conclusionText:
                'полости коронковой части, прилегающей к пульпарной камере',
            frequency: 3,
            scope: PathologyScope.tooth,
          ),
          const Pathology(
            id: 'g1_density_reduction',
            groupId: 'g1',
            name: 'Снижение плотности тканей зуба (на контакте / жевательной поверхности)',
            descriptionTemplate:
                'снижение плотности тканей зуба (на контакте / жевательной поверхности)',
            conclusionText: 'снижению плотности тканей зуба',
            frequency: 3,
            scope: PathologyScope.tooth,
          ),
          const Pathology(
            id: 'g1_wedge_defect',
            groupId: 'g1',
            name: 'Клиновидный дефект с вестибулярной стороны в области шейки',
            descriptionTemplate:
                'клиновидный дефект с вестибулярной стороны в области шейки',
            conclusionText: 'клиновидному дефекту в области шейки',
            frequency: 2,
            scope: PathologyScope.tooth,
          ),
          const Pathology(
            id: 'g1_cervical_root_cavity',
            groupId: 'g1',
            name: 'Полость в области шейки зуба с распространением на корень',
            descriptionTemplate:
                'полость в области шейки зуба с распространением на корень',
            conclusionText:
                'полости в области шейки зуба с распространением на корень',
            frequency: 2,
            scope: PathologyScope.tooth,
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
            descriptionTemplate: 'деструкция в апикальной области {size}',
            conclusionText: 'деструкции в апикальной области',
            frequency: 5,
            scope: PathologyScope.tooth,
            requiresSize: true,
          ),
          const Pathology(
            id: 'g2_apical_destruction_clear',
            groupId: 'g2',
            name:
                'Деструкция в апикальной области с ровными/чёткими контурами, размером …',
            descriptionTemplate:
                'деструкция в апикальной области с ровными/чёткими контурами, размером {size}',
            conclusionText:
                'деструкции в апикальной области с ровными/чёткими контурами',
            frequency: 4,
            scope: PathologyScope.tooth,
            requiresSize: true,
          ),
          const Pathology(
            id: 'g2_prolapse_sinus',
            groupId: 'g2',
            name: 'Деструкция пролабирует в полость верхнечелюстного синуса',
            descriptionTemplate:
                'деструкция пролабирует в полость верхнечелюстного синуса',
            conclusionText:
                'деструкции, пролабирующей в полость верхнечелюстного синуса',
            frequency: 4,
            scope: PathologyScope.tooth,
          ),
          const Pathology(
            id: 'g2_pdl_widening',
            groupId: 'g2',
            name: 'Расширение периодонтального пространства в апикальной области',
            descriptionTemplate:
                'расширение периодонтального пространства в апикальной области',
            conclusionText:
                'расширению периодонтального пространства в апикальной области',
            frequency: 4,
            scope: PathologyScope.tooth,
          ),
          const Pathology(
            id: 'g2_sinus_wall',
            groupId: 'g2',
            name: 'Деструкция с нарушением целостности нижней стенки ВЧС',
            descriptionTemplate:
                'деструкция с нарушением целостности нижней стенки ВЧС',
            conclusionText:
                'деструкции с нарушением целостности нижней стенки ВЧС',
            frequency: 3,
            scope: PathologyScope.tooth,
          ),
          const Pathology(
            id: 'g2_to_furcation',
            groupId: 'g2',
            name: 'Деструкция с распространением в область фуркации',
            descriptionTemplate:
                'деструкция с распространением в область фуркации',
            conclusionText: 'деструкции с распространением в область фуркации',
            frequency: 3,
            scope: PathologyScope.tooth,
          ),
          const Pathology(
            id: 'g2_cortical_defect',
            groupId: 'g2',
            name: 'Деструкция с дефектом кортикальной пластины вестибулярно',
            descriptionTemplate:
                'деструкция с дефектом кортикальной пластины вестибулярно',
            conclusionText:
                'деструкции с дефектом кортикальной пластины вестибулярно',
            frequency: 3,
            scope: PathologyScope.tooth,
          ),
          const Pathology(
            id: 'g2_adjacent_apex',
            groupId: 'g2',
            name: 'Деструкция с распространением на апекс соседнего зуба',
            descriptionTemplate:
                'деструкция с распространением на апекс соседнего зуба',
            conclusionText:
                'деструкции с распространением на апекс соседнего зуба',
            frequency: 2,
            scope: PathologyScope.tooth,
          ),
          const Pathology(
            id: 'g2_osteosclerosis',
            groupId: 'g2',
            name: 'Деструкция в апикальной области с перифокальным остеосклерозом',
            descriptionTemplate:
                'деструкция в апикальной области с перифокальным остеосклерозом',
            conclusionText:
                'деструкции в апикальной области с перифокальным остеосклерозом',
            frequency: 2,
            scope: PathologyScope.tooth,
          ),
          const Pathology(
            id: 'g2_mandibular_canal',
            groupId: 'g2',
            name: 'Деструкция с вовлечением нижнечелюстного канала',
            descriptionTemplate:
                'деструкция с вовлечением нижнечелюстного канала',
            conclusionText: 'деструкции с вовлечением нижнечелюстного канала',
            frequency: 2,
            scope: PathologyScope.tooth,
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
            conclusionText: 'деструкции в области фуркации',
            frequency: 5,
            scope: PathologyScope.tooth,
          ),
          const Pathology(
            id: 'g3_furcation_apices',
            groupId: 'g3',
            name: 'Деструкция в области фуркации с распространением на апексы',
            descriptionTemplate:
                'деструкция в области фуркации с распространением на апексы',
            conclusionText:
                'деструкции в области фуркации с распространением на апексы',
            frequency: 3,
            scope: PathologyScope.tooth,
          ),
          const Pathology(
            id: 'g3_furcation_crack',
            groupId: 'g3',
            name: 'Трещина в области фуркации (перфорация-?)',
            descriptionTemplate: 'трещина в области фуркации (перфорация-?)',
            conclusionText: 'трещине в области фуркации (перфорации-?)',
            frequency: 3,
            scope: PathologyScope.tooth,
          ),
          const Pathology(
            id: 'g3_roots_separated',
            groupId: 'g3',
            name: 'Деструкция в области фуркации, корни разобщены',
            descriptionTemplate:
                'деструкция в области фуркации, корни разобщены',
            conclusionText:
                'деструкции в области фуркации с разобщением корней',
            frequency: 2,
            scope: PathologyScope.tooth,
          ),
          const Pathology(
            id: 'g3_lingual_plate',
            groupId: 'g3',
            name:
                'Корковая пластина с язычной стороны на уровне фуркации не прослеживается',
            descriptionTemplate:
                'корковая пластина с язычной стороны на уровне фуркации не прослеживается',
            conclusionText:
                'отсутствию корковой пластины с язычной стороны на уровне фуркации',
            frequency: 2,
            scope: PathologyScope.tooth,
          ),
        ],
      ),
      PathologyGroup(
        id: 'g4',
        order: 4,
        title: '4. Корневые каналы и пломбирование',
        items: [
          const Pathology(
            id: 'g4_partial_obturation',
            groupId: 'g4',
            name: 'Корневые каналы обтурированы частично',
            descriptionTemplate: 'корневые каналы обтурированы частично',
            conclusionText: 'частичной обтурации корневых каналов',
            frequency: 5,
            scope: PathologyScope.tooth,
          ),
          const Pathology(
            id: 'g4_no_filling',
            groupId: 'g4',
            name: 'Корневые каналы без следов пломбировки',
            descriptionTemplate: 'корневые каналы без следов пломбировки',
            conclusionText: 'отсутствию пломбировки корневых каналов',
            frequency: 4,
            scope: PathologyScope.tooth,
          ),
          const Pathology(
            id: 'g4_material_beyond_apex',
            groupId: 'g4',
            name: 'Выведение пломбировочного материала за апекс в костную ткань',
            descriptionTemplate:
                'выведение пломбировочного материала за апекс в костную ткань',
            conclusionText:
                'выведению пломбировочного материала за апекс в костную ткань',
            frequency: 4,
            scope: PathologyScope.tooth,
          ),
          const Pathology(
            id: 'g4_overhanging',
            groupId: 'g4',
            name: 'Нависающие края пломбы / коронки',
            descriptionTemplate: 'нависающие края пломбы / коронки',
            conclusionText: 'нависающим краям пломбы / коронки',
            frequency: 4,
            scope: PathologyScope.tooth,
          ),
          const Pathology(
            id: 'g4_mb2',
            groupId: 'g4',
            name: 'МБ2 без следов пломбировки',
            descriptionTemplate: 'МБ2 без следов пломбировки',
            conclusionText: 'необтурированному каналу МБ2',
            frequency: 3,
            scope: PathologyScope.tooth,
          ),
          const Pathology(
            id: 'g4_underfilling',
            groupId: 'g4',
            name: 'Недопломбировка … мм',
            descriptionTemplate: 'недопломбировка {size}',
            conclusionText: 'недопломбировке корневого канала',
            frequency: 3,
            scope: PathologyScope.tooth,
            requiresSize: true,
          ),
          const Pathology(
            id: 'g4_material_in_sinus',
            groupId: 'g4',
            name: 'Выведение пломбировочного материала в полость ВЧС',
            descriptionTemplate:
                'выведение пломбировочного материала в полость ВЧС',
            conclusionText:
                'выведению пломбировочного материала в полость ВЧС',
            frequency: 3,
            scope: PathologyScope.tooth,
          ),
          const Pathology(
            id: 'g4_restoration_fit',
            groupId: 'g4',
            name: 'Нарушение прилегания реставрации / пломбы',
            descriptionTemplate: 'нарушение прилегания реставрации / пломбы',
            conclusionText: 'нарушению прилегания реставрации / пломбы',
            frequency: 3,
            scope: PathologyScope.tooth,
          ),
          const Pathology(
            id: 'g4_post_off_axis',
            groupId: 'g4',
            name: 'Штифт установлен не по оси корневого канала',
            descriptionTemplate: 'штифт установлен не по оси корневого канала',
            conclusionText: 'установке штифта не по оси корневого канала',
            frequency: 2,
            scope: PathologyScope.tooth,
          ),
          const Pathology(
            id: 'g4_material_in_pulp',
            groupId: 'g4',
            name: 'Пломбировочный материал в пульпарной камере',
            descriptionTemplate: 'пломбировочный материал в пульпарной камере',
            conclusionText: 'пломбировочному материалу в пульпарной камере',
            frequency: 2,
            scope: PathologyScope.tooth,
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
            conclusionText:
                'снижению высоты альвеолярного гребня / костной ткани',
            frequency: 5,
            scope: PathologyScope.tooth,
          ),
          const Pathology(
            id: 'g5_bone_pocket',
            groupId: 'g5',
            name: 'Костный карман (мезиально / дистально) до … длины корня',
            descriptionTemplate: 'костный карман (мезиально / дистально) {size}',
            conclusionText: 'костному карману',
            frequency: 5,
            scope: PathologyScope.tooth,
            requiresSize: true,
          ),
          const Pathology(
            id: 'g5_calculus',
            groupId: 'g5',
            name: 'Зубные камни / поддесневые отложения',
            descriptionTemplate: 'зубные камни / поддесневые отложения',
            conclusionText: 'зубным камням / поддесневым отложениям',
            frequency: 4,
            scope: PathologyScope.tooth,
          ),
          const Pathology(
            id: 'g5_deep_pockets',
            groupId: 'g5',
            name: 'Глубокие костные карманы',
            descriptionTemplate: 'глубокие костные карманы',
            conclusionText: 'глубоким костным карманам',
            frequency: 4,
            scope: PathologyScope.tooth,
          ),
          const Pathology(
            id: 'g5_circular_destruction',
            groupId: 'g5',
            name: 'Циркулярная деструкция вокруг корней до апексов',
            descriptionTemplate:
                'циркулярная деструкция вокруг корней до апексов',
            conclusionText: 'циркулярной деструкции вокруг корней до апексов',
            frequency: 3,
            scope: PathologyScope.tooth,
          ),
          const Pathology(
            id: 'g5_generalized',
            groupId: 'g5',
            name: 'Генерализованный пародонтит / пародонтоз',
            descriptionTemplate:
                'генерализованное снижение высоты костной ткани альвеолярных гребней',
            conclusionText: 'генерализованному пародонтиту / пародонтозу',
            frequency: 3,
            scope: PathologyScope.general,
          ),
          const Pathology(
            id: 'g5_apex_resorption',
            groupId: 'g5',
            name: 'Резорбция апексов / корня',
            descriptionTemplate: 'резорбция апексов / корня',
            conclusionText: 'резорбции апексов / корня',
            frequency: 3,
            scope: PathologyScope.tooth,
          ),
          const Pathology(
            id: 'g5_apex_lysis',
            groupId: 'g5',
            name: 'Частичный лизис апексов',
            descriptionTemplate: 'частичный лизис апексов',
            conclusionText: 'частичному лизису апексов',
            frequency: 2,
            scope: PathologyScope.tooth,
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
            conclusionText: 'ретенции и дистопии',
            frequency: 5,
            scope: PathologyScope.tooth,
          ),
          const Pathology(
            id: 'g6_popov_godon',
            groupId: 'g6',
            name: 'Феномен Попова-Годона',
            descriptionTemplate: 'феномен Попова-Годона',
            conclusionText: 'феномену Попова-Годона',
            frequency: 4,
            scope: PathologyScope.tooth,
          ),
          const Pathology(
            id: 'g6_partial_adentia',
            groupId: 'g6',
            name: 'Частичная вторичная адентия',
            descriptionTemplate: 'частичная вторичная адентия',
            conclusionText: 'частичной вторичной адентии',
            frequency: 4,
            scope: PathologyScope.general,
          ),
          const Pathology(
            id: 'g6_retention_roots',
            groupId: 'g6',
            name: 'Ретинирован, дистопирован, упирается в корни соседнего зуба',
            descriptionTemplate:
                'ретинирован, дистопирован, упирается в корни соседнего зуба',
            conclusionText:
                'ретенции и дистопии с упором в корни соседнего зуба',
            frequency: 3,
            scope: PathologyScope.tooth,
          ),
          const Pathology(
            id: 'g6_radix',
            groupId: 'g6',
            name: 'Radix (остаток корня)',
            descriptionTemplate: 'Radix (остаток корня)',
            extractedTemplate: 'Radix (остаток корня)',
            conclusionText: 'Radix (остатку корня)',
            frequency: 3,
            scope: PathologyScope.tooth,
          ),
          const Pathology(
            id: 'g6_root_fragment',
            groupId: 'g6',
            name: 'Фрагмент корня в костной ткани / мягких тканях',
            descriptionTemplate:
                'фрагмент корня в костной ткани / мягких тканях',
            conclusionText: 'фрагменту корня в костной ткани / мягких тканях',
            frequency: 3,
            scope: PathologyScope.tooth,
          ),
          const Pathology(
            id: 'g6_full_adentia',
            groupId: 'g6',
            name: 'Полная адентия',
            descriptionTemplate: 'полная адентия',
            conclusionText: 'полной адентии',
            frequency: 2,
            scope: PathologyScope.general,
          ),
          const Pathology(
            id: 'g6_supernumerary',
            groupId: 'g6',
            name: 'Сверхкомплектный зуб',
            descriptionTemplate: 'сверхкомплектный зуб',
            conclusionText: 'сверхкомплектному зубу',
            frequency: 2,
            scope: PathologyScope.tooth,
          ),
        ],
      ),
      PathologyGroup(
        id: 'g7',
        order: 7,
        title: '7. ЛОР-патология: верхнечелюстные синусы',
        items: [
          const Pathology(
            id: 'g7_soft_tissue_wall',
            groupId: 'g7',
            name: 'Мягкотканый компонент по нижней стенке до … мм',
            descriptionTemplate:
                'мягкотканый компонент по нижней стенке ВЧС {size}',
            conclusionText: 'мягкотканому компоненту по нижней стенке ВЧС',
            frequency: 5,
            scope: PathologyScope.general,
            requiresSize: true,
            requiresSide: true,
          ),
          const Pathology(
            id: 'g7_mucosa_hypertrophy',
            groupId: 'g7',
            name: 'Гипертрофия слизистой нижней стенки ВЧС до … мм',
            descriptionTemplate:
                'гипертрофия слизистой нижней стенки ВЧС {size}',
            conclusionText: 'гипертрофии слизистой нижней стенки ВЧС',
            frequency: 4,
            scope: PathologyScope.general,
            requiresSize: true,
            requiresSide: true,
          ),
          const Pathology(
            id: 'g7_total_filling',
            groupId: 'g7',
            name: 'Тотальное / субтотальное заполнение мягкотканым компонентом',
            descriptionTemplate:
                'тотальное / субтотальное заполнение ВЧС мягкотканым компонентом',
            conclusionText:
                'тотальному / субтотальному заполнению ВЧС мягкотканым компонентом',
            frequency: 3,
            scope: PathologyScope.general,
            requiresSide: true,
          ),
          const Pathology(
            id: 'g7_gas_bubbles',
            groupId: 'g7',
            name: 'Мягкотканый компонент с пузырьками газа на поверхности',
            descriptionTemplate:
                'мягкотканый компонент ВЧС с пузырьками газа на поверхности',
            conclusionText:
                'мягкотканому компоненту ВЧС с пузырьками газа на поверхности',
            frequency: 3,
            scope: PathologyScope.general,
            requiresSide: true,
          ),
          const Pathology(
            id: 'g7_fluid_level',
            groupId: 'g7',
            name: 'Мягкотканый компонент с горизонтальным уровнем жидкости',
            descriptionTemplate:
                'мягкотканый компонент ВЧС с горизонтальным уровнем жидкости',
            conclusionText:
                'мягкотканому компоненту ВЧС с горизонтальным уровнем жидкости',
            frequency: 3,
            scope: PathologyScope.general,
            requiresSide: true,
          ),
          const Pathology(
            id: 'g7_cyst',
            groupId: 'g7',
            name: 'Кистозное образование / ретенционная киста',
            descriptionTemplate:
                'кистозное образование / ретенционная киста ВЧС',
            conclusionText: 'кистозному образованию / ретенционной кисте ВЧС',
            frequency: 3,
            scope: PathologyScope.general,
            requiresSide: true,
          ),
          const Pathology(
            id: 'g7_ostium',
            groupId: 'g7',
            name: 'Естественное соустье не прослеживается / прослеживается частично',
            descriptionTemplate:
                'естественное соустье ВЧС не прослеживается / прослеживается частично',
            conclusionText:
                'нарушению проходимости естественного соустья ВЧС',
            frequency: 3,
            scope: PathologyScope.general,
            requiresSide: true,
          ),
          const Pathology(
            id: 'g7_odontogenic',
            groupId: 'g7',
            name: 'Одонтогенные изменения ВЧС',
            descriptionTemplate: 'одонтогенные изменения ВЧС',
            conclusionText: 'одонтогенным изменениям ВЧС',
            frequency: 3,
            scope: PathologyScope.general,
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
            conclusionText: 'шипу перегородки полости носа {direction}',
            frequency: 5,
            scope: PathologyScope.general,
            requiresDirection: true,
          ),
          const Pathology(
            id: 'g8_ethmoid',
            groupId: 'g8',
            name: 'Снижение воздушности ячеек решётчатого лабиринта',
            descriptionTemplate:
                'снижение воздушности ячеек решётчатого лабиринта',
            conclusionText:
                'снижению воздушности ячеек решётчатого лабиринта',
            frequency: 4,
            scope: PathologyScope.general,
          ),
          const Pathology(
            id: 'g8_septum_deviation',
            groupId: 'g8',
            name: 'Искривление носовой перегородки',
            descriptionTemplate: 'искривление носовой перегородки',
            conclusionText: 'искривлению носовой перегородки',
            frequency: 4,
            scope: PathologyScope.general,
          ),
          const Pathology(
            id: 'g8_pansinusitis',
            groupId: 'g8',
            name: 'Пансинусит',
            descriptionTemplate:
                'снижение воздушности всех околоносовых пазух (пансинусит)',
            conclusionText: 'пансинуситу',
            frequency: 3,
            scope: PathologyScope.general,
          ),
          const Pathology(
            id: 'g8_sphenoid',
            groupId: 'g8',
            name: 'Мягкотканый компонент в клиновидной пазухе',
            descriptionTemplate: 'мягкотканый компонент в клиновидной пазухе',
            conclusionText: 'мягкотканому компоненту в клиновидной пазухе',
            frequency: 3,
            scope: PathologyScope.general,
          ),
          const Pathology(
            id: 'g8_lymphoid',
            groupId: 'g8',
            name: 'Гиперплазия лимфоидного кольца свода носоглотки',
            descriptionTemplate:
                'гиперплазия лимфоидного кольца свода носоглотки',
            conclusionText:
                'гиперплазии лимфоидного кольца свода носоглотки',
            frequency: 3,
            scope: PathologyScope.general,
          ),
          const Pathology(
            id: 'g8_tonsilloliths',
            groupId: 'g8',
            name: 'Тонзиллолиты / конкременты в миндалинах',
            descriptionTemplate: 'тонзиллолиты / конкременты в миндалинах',
            conclusionText: 'тонзиллолитам / конкрементам в миндалинах',
            frequency: 3,
            scope: PathologyScope.general,
          ),
          const Pathology(
            id: 'g8_frontal_mucosa',
            groupId: 'g8',
            name: 'Утолщение слизистой лобного синуса',
            descriptionTemplate: 'утолщение слизистой лобного синуса',
            conclusionText: 'утолщению слизистой лобного синуса',
            frequency: 2,
            scope: PathologyScope.general,
            requiresSide: true,
          ),
          const Pathology(
            id: 'g8_hypoplasia',
            groupId: 'g8',
            name: 'Гипоплазия ВЧС / лобного синуса',
            descriptionTemplate: 'гипоплазия ВЧС / лобного синуса',
            conclusionText: 'гипоплазии ВЧС / лобного синуса',
            frequency: 2,
            scope: PathologyScope.general,
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
            name: 'Костная ткань вокруг имплантатов без патологических изменений',
            descriptionTemplate:
                'костная ткань вокруг имплантатов без патологических изменений',
            conclusionText:
                'состоянию после имплантации без патологических изменений костной ткани',
            frequency: 3,
            scope: PathologyScope.general,
          ),
          const Pathology(
            id: 'g9_implant_bone_loss',
            groupId: 'g9',
            name: 'Деструкция / снижение костной ткани вокруг имплантата',
            descriptionTemplate:
                'деструкция / снижение костной ткани вокруг имплантата',
            conclusionText:
                'деструкции / снижению костной ткани вокруг имплантата',
            frequency: 2,
            scope: PathologyScope.tooth,
          ),
          const Pathology(
            id: 'g9_sinus_lift',
            groupId: 'g9',
            name: 'Состояние после синуслифтинга',
            descriptionTemplate: 'состояние после синуслифтинга',
            conclusionText: 'состоянию после синуслифтинга',
            frequency: 2,
            scope: PathologyScope.general,
            requiresSide: true,
          ),
          const Pathology(
            id: 'g9_socket',
            groupId: 'g9',
            name: 'Лунка после удаления без следов оссификации',
            descriptionTemplate: 'лунка после удаления без следов оссификации',
            extractedTemplate: 'лунка после удаления без следов оссификации',
            conclusionText: 'лунке после удаления без следов оссификации',
            frequency: 2,
            scope: PathologyScope.tooth,
          ),
          const Pathology(
            id: 'g9_oroantral',
            groupId: 'g9',
            name: 'Ороантральное соустье / сообщение',
            descriptionTemplate: 'ороантральное соустье / сообщение',
            conclusionText: 'ороантральному соустью / сообщению',
            frequency: 2,
            scope: PathologyScope.general,
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
            conclusionText: 'эностозу / участку остеосклероза',
            frequency: 2,
            scope: PathologyScope.tooth,
          ),
          const Pathology(
            id: 'g10_tmj',
            groupId: 'g10',
            name: 'Дегенеративные изменения ВНЧС',
            descriptionTemplate: 'дегенеративные изменения ВНЧС',
            conclusionText: 'дегенеративным изменениям ВНЧС',
            frequency: 2,
            scope: PathologyScope.general,
            requiresSide: true,
          ),
          const Pathology(
            id: 'g10_cod',
            groupId: 'g10',
            name: 'Цементно-костная дисплазия',
            descriptionTemplate: 'цементно-костная дисплазия',
            conclusionText: 'цементно-костной дисплазии',
            frequency: 1,
            scope: PathologyScope.general,
          ),
          const Pathology(
            id: 'g10_adamantoma',
            groupId: 'g10',
            name: 'Адамантома (эмалевый бугорок)',
            descriptionTemplate: 'адамантома (эмалевый бугорок)',
            conclusionText: 'адамантоме (эмалевому бугорку)',
            frequency: 1,
            scope: PathologyScope.tooth,
          ),
          const Pathology(
            id: 'g10_odontoma',
            groupId: 'g10',
            name: 'Одонтома',
            descriptionTemplate: 'одонтома',
            conclusionText: 'одонтоме',
            frequency: 1,
            scope: PathologyScope.general,
          ),
          const Pathology(
            id: 'g10_phleboliths',
            groupId: 'g10',
            name: 'Флеболиты',
            descriptionTemplate: 'флеболиты',
            conclusionText: 'флеболитам',
            frequency: 1,
            scope: PathologyScope.general,
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
