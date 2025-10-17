class SickLeaveModel {
  final int? id;
  final String userId;
  final String reason;
  final DateTime startDate;
  final DateTime endDate;
  final String? attachmentUrl;
  final String status;
  final String? adminNotes;
  final DateTime submittedAt;
  final DateTime? reviewedAt;
  final String? reviewedBy;

  SickLeaveModel({
    this.id,
    required this.userId,
    required this.reason,
    required this.startDate,
    required this.endDate,
    this.attachmentUrl,
    this.status = 'Menunggu',
    this.adminNotes,
    required this.submittedAt,
    this.reviewedAt,
    this.reviewedBy,
  });

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'reason': reason,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'attachment_url': attachmentUrl,
      'status': status,
      'admin_notes': adminNotes,
      'submitted_at': submittedAt.toIso8601String(),
      'reviewed_at': reviewedAt?.toIso8601String(),
      'reviewed_by': reviewedBy,
    };
  }

  factory SickLeaveModel.fromMap(Map<String, dynamic> map) {
    return SickLeaveModel(
      id: map['id'],
      userId: map['user_id'],
      reason: map['reason'],
      startDate: DateTime.parse(map['start_date']),
      endDate: DateTime.parse(map['end_date']),
      attachmentUrl: map['attachment_url'],
      status: map['status'],
      adminNotes: map['admin_notes'],
      submittedAt: DateTime.parse(map['submitted_at']),
      reviewedAt: map['reviewed_at'] != null ? DateTime.parse(map['reviewed_at']) : null,
      reviewedBy: map['reviewed_by'],
    );
  }
}