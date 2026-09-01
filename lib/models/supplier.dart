class Supplier {
  final String id;
  final String name;
  final String contact;
  final String email;
  final String? website;
  final String category;
  final String status; // 'Active' | 'Inactive'

  Supplier({
    required this.id,
    required this.name,
    required this.contact,
    required this.email,
    this.website,
    required this.category,
    required this.status,
  });

  factory Supplier.fromJson(Map<String, dynamic> json) => Supplier(
    id: json['id'] as String,
    name: json['name'] as String? ?? '',
    contact: json['contact'] as String? ?? '',
    email: json['email'] as String? ?? '',
    website: json['website'] as String?,
    category: json['category'] as String? ?? '',
    status: json['status'] as String? ?? 'Active',
  );

  Map<String, dynamic> toJson({bool includeId = true}) => {
    if (includeId) 'id': id,
    'name': name,
    'contact': contact,
    'email': email,
    if (website != null && website!.isNotEmpty) 'website': website,
    'category': category,
    'status': status,
  };
}
