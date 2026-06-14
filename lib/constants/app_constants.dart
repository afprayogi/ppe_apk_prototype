class AppConstants {
  AppConstants._();

  static const String appName    = 'VivatPass';
  static const String appSlogan  = 'Scan. Detect. Protect.';

  // Routes
  static const String routeSplash    = '/';
  static const String routeHome      = '/home';
  static const String routeRegister  = '/register';
  static const String routeAbsensi   = '/absensi';
  static const String routeScanner   = '/scanner';
  static const String routeResult    = '/result';
  static const String routeRank      = '/rank';
  static const String routeArchive   = '/archive';
  static const String routeTrain     = '/train';
  static const String routeInfo      = '/info';
  static const String routeDetail          = '/detail';
  static const String routeSettings        = '/settings';
  static const String routeEmployeeHistory = '/employee-history';

  // PPE Items
  static const List<String> ppeItems = [
    'Gloves',
    'Vest',
    'Glass',
    'Helmet',
    'Mask',
    'Boots',
  ];

  // Shift options
  static const List<String> shifts = [
    'Shift 1',
    'Shift 2',
    'Shift 3',
  ];

  // Marquee messages
  static const List<String> safetyMessages = [
    'Safety First. Production Second.',
    'Lindungi Dirimu. Gunakan APD Lengkap.',
    'Zero Accident adalah Tanggung Jawab Kita.',
    'APD Bukan Pilihan, APD adalah Kewajiban.',
  ];
}
