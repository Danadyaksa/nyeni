class Event {
  final int id;
  final String name;
  final String description;
  final String date;
  final String location;
  final double? latitude;
  final double? longitude;
  final int price;
  final String? imageUrl;
  final String createdAt;
  final String? category;
  final String? organizer;
  final String? openTime;
  final String? closeTime;
  final int? earlyBirdPrice;
  final String? earlyBirdStart;
  final String? earlyBirdEnd;
  final String? regularStart;
  final String? regularEnd;
  final List<dynamic>? ticketOptions;

  Event({
    required this.id,
    required this.name,
    required this.description,
    required this.date,
    required this.location,
    this.latitude,
    this.longitude,
    required this.price,
    this.imageUrl,
    required this.createdAt,
    this.category,
    this.organizer,
    this.openTime,
    this.closeTime,
    this.earlyBirdPrice,
    this.earlyBirdStart,
    this.earlyBirdEnd,
    this.regularStart,
    this.regularEnd,
    this.ticketOptions,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'] ?? 0,
      name: json['name']?.toString() ?? json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      date: json['date']?.toString() ?? json['event_date']?.toString() ?? '',
      location: json['location']?.toString() ?? '',
      latitude: json['latitude'] != null ? double.tryParse(json['latitude'].toString()) : null,
      longitude: json['longitude'] != null ? double.tryParse(json['longitude'].toString()) : null,
      price: json['price'] is int ? json['price'] : int.tryParse(json['price']?.toString() ?? '0') ?? 0,
      imageUrl: json['image_url']?.toString(),
      createdAt: json['created_at']?.toString() ?? '',
      category: json['category']?.toString(),
      organizer: json['organizer']?.toString(),
      openTime: json['open_time']?.toString(),
      closeTime: json['close_time']?.toString(),
      earlyBirdPrice: json['early_bird_price'] is int ? json['early_bird_price'] : int.tryParse(json['early_bird_price']?.toString() ?? '0'),
      earlyBirdStart: json['early_bird_start']?.toString(),
      earlyBirdEnd: json['early_bird_end']?.toString(),
      regularStart: json['regular_start']?.toString(),
      regularEnd: json['regular_end']?.toString(),
      ticketOptions: json['ticket_options'] as List<dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'title': name, // Alias for compatibility
      'description': description,
      'date': date,
      'event_date': date, // Alias for compatibility
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'price': price,
      'image_url': imageUrl,
      'created_at': createdAt,
      'category': category,
      'organizer': organizer,
      'open_time': openTime,
      'close_time': closeTime,
      'early_bird_price': earlyBirdPrice,
      'early_bird_start': earlyBirdStart,
      'early_bird_end': earlyBirdEnd,
      'regular_start': regularStart,
      'regular_end': regularEnd,
      'ticket_options': ticketOptions,
    };
  }

  // Getters for compatibility with old code
  String get title => name;
  String get image => imageUrl ?? '';

  // Helper method untuk format harga
  String get formattedPrice {
    if (price == 0) return 'Gratis';
    return 'Rp ${price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
  }

  // Helper method untuk cek apakah ada koordinat
  bool get hasCoordinates => latitude != null && longitude != null;
}
