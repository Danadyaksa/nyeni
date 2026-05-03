class Ticket {
  final String id;
  final String userId;
  final String eventName;
  final String eventDate;
  final String status; // PENDING, ACTIVE, USED, EXPIRED, DECLINED
  final String? transactionId;
  final int uniqueCode;
  final int serviceFee;
  final int ticketPrice;
  final int totalAmount;
  final String createdAt;
  final String? imageUrl; // From JOIN with events table

  Ticket({
    required this.id,
    required this.userId,
    required this.eventName,
    required this.eventDate,
    required this.status,
    this.transactionId,
    required this.uniqueCode,
    required this.serviceFee,
    required this.ticketPrice,
    required this.totalAmount,
    required this.createdAt,
    this.imageUrl,
  });

  factory Ticket.fromJson(Map<String, dynamic> json) {
    return Ticket(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      eventName: json['event_name']?.toString() ?? '',
      eventDate: json['event_date']?.toString() ?? '',
      status: json['status']?.toString() ?? 'PENDING',
      transactionId: json['transaction_id']?.toString(),
      uniqueCode: json['unique_code'] ?? 0,
      serviceFee: json['service_fee'] ?? 0,
      ticketPrice: json['ticket_price'] ?? 0,
      totalAmount: json['total_amount'] ?? 0,
      createdAt: json['created_at']?.toString() ?? '',
      imageUrl: json['image_url']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'event_name': eventName,
      'event_date': eventDate,
      'status': status,
      'transaction_id': transactionId,
      'unique_code': uniqueCode,
      'service_fee': serviceFee,
      'ticket_price': ticketPrice,
      'total_amount': totalAmount,
      'created_at': createdAt,
      'image_url': imageUrl,
    };
  }

  // Helper methods untuk status
  bool get isPending => status == 'PENDING';
  bool get isActive => status == 'ACTIVE';
  bool get isUsed => status == 'USED';
  bool get isExpired => status == 'EXPIRED';
  bool get isDeclined => status == 'DECLINED';

  // Helper untuk badge color
  String get statusLabel {
    switch (status) {
      case 'PENDING':
        return 'Menunggu Verifikasi';
      case 'ACTIVE':
        return 'Tiket Aktif';
      case 'USED':
        return 'Sudah Digunakan';
      case 'EXPIRED':
        return 'Kadaluarsa';
      case 'DECLINED':
        return 'Ditolak';
      default:
        return status;
    }
  }
}
