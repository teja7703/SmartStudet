class AcademicConstants {
  AcademicConstants._();

  static const String langEnglish = 'English';
  static const String langTelugu = 'Telugu';

  static const List<String> academicLevels = [
    '8',
    '9',
    '10',
    'Inter 1st Year',
    'Inter 2nd Year',
  ];

  static const List<String> subjects = [
    'Mathematics',
    'Science',
    'Social',
    'English',
    'Telugu',
    'Hindi',
  ];

  static const Map<String, String> _subjectTelugu = {
    'Mathematics': 'గణిత శాస్త్రం',
    'Science': 'విజ్ఞాన శాస్త్రం',
    'Social': 'సాంఘిక శాస్త్రం',
    'English': 'ఆంగ్లం',
    'Telugu': 'తెలుగు',
    'Hindi': 'హిందీ',
  };

  static bool isTelugu(String language) => language == langTelugu;

  static String formatLevel(String level, [String language = langEnglish]) {
    if (isTelugu(language)) {
      if (level.contains('Inter')) {
        if (level.contains('1')) return 'ఇంటర్ మొదటి సంవత్సరం';
        if (level.contains('2')) return 'ఇంటర్ రెండవ సంవత్సరం';
        return 'ఇంటర్';
      }
      return '$level వ తరగతి';
    }
    return level.contains('Inter') ? level : 'Class $level';
  }

  static String formatSubject(String subject, [String language = langEnglish]) {
    if (isTelugu(language)) return _subjectTelugu[subject] ?? subject;
    return subject;
  }

  // ---- Localized UI strings ---------------------------------------------

  static String studyMaterialsTitle(String language) =>
      isTelugu(language) ? 'విద్యా సామగ్రి' : 'Study Materials';

  static String selectLanguageTitle(String language) =>
      'Select Language / భాషను ఎంచుకోండి';

  static String selectLevelTitle(String language) =>
      isTelugu(language) ? 'తరగతిని ఎంచుకోండి' : 'Select Academic Level';

  static String viewSubjects(String language) =>
      isTelugu(language) ? 'విషయాలను చూడటానికి నొక్కండి' : 'Tap to view subjects';

  static String browseMaterials(String language) =>
      isTelugu(language) ? 'విద్యా సామగ్రిని చూడండి' : 'Browse study materials';

  static String searchHint(String language) =>
      isTelugu(language) ? 'అధ్యాయం ద్వారా వెతకండి...' : 'Search by chapter...';

  static String noMaterialsTitle(String language) =>
      isTelugu(language) ? 'సామగ్రి కనుగొనబడలేదు' : 'No materials found';

  static String noMaterialsMessage(String language) => isTelugu(language)
      ? 'వేరే అధ్యాయం కోసం వెతకండి లేదా తరువాత తనిఖీ చేయండి.'
      : 'Try a different search or check back later.';

  static String chapterLabel(String language) =>
      isTelugu(language) ? 'అధ్యాయం' : 'Chapter';

  static String downloadPdf(String language) =>
      isTelugu(language) ? 'PDF డౌన్‌లోడ్' : 'Download PDF';

  static String preparing(String language) =>
      isTelugu(language) ? 'సిద్ధమవుతోంది...' : 'Preparing...';

  static String watchVideo(String language) =>
      isTelugu(language) ? 'వీడియో చూడండి' : 'Watch Video';

  static String pdfDownloaded(String language) =>
      isTelugu(language) ? 'PDF డౌన్‌లోడ్ అయింది' : 'PDF downloaded';

  static String openLabel(String language) =>
      isTelugu(language) ? 'తెరువు' : 'Open';
}
