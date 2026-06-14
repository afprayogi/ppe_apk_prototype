enum DetectionStatus { progress, complete }

class DetectionRecord {
  final String id;
  final String employeeId;
  final String employeeName;
  final String nia;
  final DateTime detectedAt;
  final List<String> detectedPpe;
  final List<String> missingPpe;
  final DetectionStatus status;
  final double overallConfidence;
  final String? imageUrl;

  const DetectionRecord({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.nia,
    required this.detectedAt,
    required this.detectedPpe,
    required this.missingPpe,
    required this.status,
    required this.overallConfidence,
    this.imageUrl,
  });

  bool get isComplete => missingPpe.isEmpty;

  String get nextScanFormatted {
    final next = detectedAt.add(const Duration(hours: 13));
    return '${next.day.toString().padLeft(2, '0')}-'
        '${next.month.toString().padLeft(2, '0')}-'
        '${next.year} ${next.hour}.${next.minute.toString().padLeft(2, '0')} WIB';
  }
}
