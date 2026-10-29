/// Статические фразы шаблонного протокола ОПГ (каркас всегда включён).
library;

/// Первая строка описания.
const String opgHeader = 'На ортопантомограмме определяется:';

/// Постоянная оговорка о проекционном искажении ОПГ.
const String opgProjectionNote =
    '- проекционное снижение информативности в области корней '
    'фронтальной группы верхней челюсти.';

/// Раздел «Адентия».
const String adentiaPrefix = 'Адентия: ';
const String adentiaNone = 'нет';
const String adentiaFull = 'полная';

/// Раздел «Тесное положение зубов».
const String crowdingPrefix = 'Тесное положение зубов: ';
const String crowdingNone = 'нет';

/// Раздел «Ретенция и дистопия».
const String retentionPrefix = 'Ретенция и дистопия: ';
const String retentionNone = 'нет';

/// Нормы разделов — когда находок в разделе нет.
const String cariesNorm = 'Признаки кариеса: не визуализируются.';
const String periapicalNorm = 'Периапикальные изменения: не визуализируются.';
const String perioNorm = 'Пародонт: без изменений.';
const String mandibularCanalNorm =
    'Нижнечелюстные каналы с обеих сторон прослеживаются, диаметр не изменен.';
const String tmjNorm =
    'Височно-нижнечелюстной сустав: головки в суставных ямках, шаровидные, '
    'контур четкий, ровный.';

/// Автострока заключения по отсутствующим зубам.
const String conclusionPartialAdentia = 'Частичная вторичная адентия.';
const String conclusionFullAdentia = 'Полная вторичная адентия.';

/// Заключение при норме: нет находок и нет удалённых зубов.
const String conclusionNoPathology = 'Без видимой патологии.';
