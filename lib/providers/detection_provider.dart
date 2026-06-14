import 'dart:typed_data';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../core/database/detection_dao.dart';
import '../models/detection_model.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------
class DetectionState {
  final List<DetectionRecord> records;
  final DetectionRecord? lastResult;
  final Uint8List? lastCapturedImage; // foto hasil capture
  final bool isScanning;
  final int nonSafetyCount;
  final int totalPersonCount;
  final List<double> trend;
  final bool isLoading;

  const DetectionState({
    this.records        = const [],
    this.lastResult,
    this.lastCapturedImage,
    this.isScanning     = false,
    this.nonSafetyCount = 0,
    this.totalPersonCount = 0,
    this.trend          = const [],
    this.isLoading      = true,
  });

  DetectionState copyWith({
    List<DetectionRecord>? records,
    DetectionRecord? lastResult,
    Uint8List? lastCapturedImage,
    bool? isScanning,
    int? nonSafetyCount,
    int? totalPersonCount,
    List<double>? trend,
    bool? isLoading,
  }) =>
      DetectionState(
        records:           records           ?? this.records,
        lastResult:        lastResult        ?? this.lastResult,
        lastCapturedImage: lastCapturedImage ?? this.lastCapturedImage,
        isScanning:        isScanning        ?? this.isScanning,
        nonSafetyCount:    nonSafetyCount    ?? this.nonSafetyCount,
        totalPersonCount:  totalPersonCount  ?? this.totalPersonCount,
        trend:             trend             ?? this.trend,
        isLoading:         isLoading         ?? this.isLoading,
      );
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------
class DetectionNotifier extends StateNotifier<DetectionState> {
  DetectionNotifier(this._dao) : super(const DetectionState()) {
    _load();
  }

  final DetectionDao _dao;

  Future<void> _load() async {
    state = state.copyWith(isLoading: true);
    try {
      final records     = await _dao.fetchAll();
      final nonSafety   = await _dao.countNonSafetyToday();
      final trendRaw    = await _dao.trendByDay(10);
      final trend       = _buildTrend(trendRaw);

      state = state.copyWith(
        records:          records,
        nonSafetyCount:   nonSafety,
        totalPersonCount: records.length,
        trend:            trend,
        isLoading:        false,
      );
    } catch (_) {
      state = state.copyWith(
        records:       const [],
        nonSafetyCount: 0,
        trend:          const [],
        isLoading:      false,
      );
    }
  }

  List<double> _buildTrend(List<Map<String, dynamic>> raw) =>
      raw.map((r) => (r['total'] as int).toDouble()).toList();

  Future<void> reload() => _load();

  Future<void> deleteRecord(String id) async {
    await _dao.delete(id);
    final records   = state.records.where((r) => r.id != id).toList();
    final nonSafety = await _dao.countNonSafetyToday();
    state = state.copyWith(records: records, nonSafetyCount: nonSafety);
  }

  Future<void> clearAll() async {
    await _dao.deleteAll();
    state = state.copyWith(records: [], nonSafetyCount: 0, totalPersonCount: 0, trend: []);
  }

  void startScan() => state = state.copyWith(isScanning: true);

  /// Preview hasil scan — tampilkan dulu tanpa simpan ke DB
  void previewScan(DetectionRecord result, {Uint8List? imageBytes}) {
    state = state.copyWith(
      isScanning:        false,
      lastResult:        result,
      lastCapturedImage: imageBytes,
    );
  }

  /// Simpan hasil preview ke DB (dipanggil dari result screen)
  Future<void> confirmSave() async {
    final result = state.lastResult;
    if (result == null) return;
    await _dao.insert(result);
    final nonSafety = await _dao.countNonSafetyToday();
    state = state.copyWith(
      records:        [result, ...state.records],
      nonSafetyCount: nonSafety,
    );
  }

  Future<void> finishScan(DetectionRecord result, {Uint8List? imageBytes}) async {
    await _dao.insert(result);
    final nonSafety = await _dao.countNonSafetyToday();
    state = state.copyWith(
      isScanning:        false,
      lastResult:        result,
      lastCapturedImage: imageBytes,
      records:           [result, ...state.records],
      nonSafetyCount:    nonSafety,
    );
  }

  void cancelScan() => state = state.copyWith(isScanning: false);

  Future<List<Map<String, dynamic>>> getRankData(
      String ppeFilter, int limit) async {
    return _dao.rankByMissingPpe(ppeFilter, limit);
  }

  Future<List<DetectionRecord>> getByEmployee(String empId) async {
    return _dao.fetchByEmployee(empId);
  }
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------
final detectionDaoProvider = Provider<DetectionDao>((_) => DetectionDao());

final detectionProvider =
    StateNotifierProvider<DetectionNotifier, DetectionState>((ref) {
  return DetectionNotifier(ref.read(detectionDaoProvider));
});

final lastResultProvider = Provider<DetectionRecord?>((ref) {
  return ref.watch(detectionProvider).lastResult;
});

final lastCapturedImageProvider = Provider<Uint8List?>((ref) {
  return ref.watch(detectionProvider).lastCapturedImage;
});

final trendDataProvider = Provider<List<double>>((ref) {
  return ref.watch(detectionProvider).trend;
});

// Async rank data filtered by PPE type
final rankDataProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>(
        (ref, filter) async {
  final notifier = ref.read(detectionProvider.notifier);
  return notifier.getRankData(filter, 20);
});

// Pie chart: berapa kali tiap APD hilang
final missingPpeStatsProvider =
    FutureProvider<Map<String, int>>((ref) async {
  // Refresh saat records berubah
  ref.watch(detectionProvider).records;
  return DetectionDao().missingPpeStats();
});

// Completion stats: complete vs incomplete
final completionStatsProvider =
    FutureProvider<Map<String, int>>((ref) async {
  ref.watch(detectionProvider).records;
  return DetectionDao().completionStats();
});
