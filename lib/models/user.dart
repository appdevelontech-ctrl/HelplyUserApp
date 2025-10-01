class AppUser {
  final String id;
  final String? username;
  final String phone;
  final String? email;
  final int? type;
  final int? empType;
  final String? state;
  final String? statename;
  final String? city;
  final String? address;
  final int? verified;
  final String? pincode;
  final String? about;
  final List<String>? department;
  final String? doc1;
  final String? doc2;
  final String? doc3;
  final String? profile; // <-- profile image URL
  final String? pHealthHistory;
  final String? cHealthStatus;
  final List<String>? coverage;
  final int? wallet;
  final int? online;
  final String? country;
  final String? dob;
  final String? gender;

  AppUser({
    required this.id,
    required this.phone,
    this.username,
    this.email,
    this.type,
    this.empType,
    this.state,
    this.statename,
    this.city,
    this.address,
    this.verified,
    this.pincode,
    this.about,
    this.department,
    this.doc1,
    this.doc2,
    this.doc3,
    this.profile,
    this.pHealthHistory,
    this.cHealthStatus,
    this.coverage,
    this.wallet,
    this.online,
    this.country,
    this.dob,
    this.gender,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['_id'] ?? '',
      phone: json['phone'] ?? '',
      username: json['username'],
      email: json['email'],
      type: json['type'] as int?,
      empType: json['empType'] as int?,
      state: json['state'],
      statename: json['statename'],
      city: json['city'],
      address: json['address'],
      verified: json['verified'] as int?,
      pincode: json['pincode'],
      about: json['about'],
      department: (json['department'] as List<dynamic>?)?.cast<String>(),
      doc1: json['Doc1'],
      doc2: json['Doc2'],
      doc3: json['Doc3'],
      profile: json['profile'], // <-- profile image
      pHealthHistory: json['pHealthHistory'],
      cHealthStatus: json['cHealthStatus'],
      coverage: (json['coverage'] as List<dynamic>?)?.cast<String>(),
      wallet: json['wallet'] as int?,
      online: json['online'] as int?,
      country: json['country'],
      dob: json['DOB'],       // Match payload key
      gender: json['Gender'], // Match payload key
    );
  }

  // ✅ copyWith method for easy update including profile
  AppUser copyWith({
    String? username,
    String? email,
    String? phone,
    int? type,
    int? empType,
    String? state,
    String? statename,
    String? city,
    String? address,
    int? verified,
    String? pincode,
    String? about,
    List<String>? department,
    String? doc1,
    String? doc2,
    String? doc3,
    String? profile, // <-- new profile URL
    String? pHealthHistory,
    String? cHealthStatus,
    List<String>? coverage,
    int? wallet,
    int? online,
    String? country,
    String? dob,
    String? gender,
  }) {
    return AppUser(
      id: id,
      username: username ?? this.username,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      type: type ?? this.type,
      empType: empType ?? this.empType,
      state: state ?? this.state,
      statename: statename ?? this.statename,
      city: city ?? this.city,
      address: address ?? this.address,
      verified: verified ?? this.verified,
      pincode: pincode ?? this.pincode,
      about: about ?? this.about,
      department: department ?? this.department,
      doc1: doc1 ?? this.doc1,
      doc2: doc2 ?? this.doc2,
      doc3: doc3 ?? this.doc3,
      profile: profile ?? this.profile, // <-- update profile if passed
      pHealthHistory: pHealthHistory ?? this.pHealthHistory,
      cHealthStatus: cHealthStatus ?? this.cHealthStatus,
      coverage: coverage ?? this.coverage,
      wallet: wallet ?? this.wallet,
      online: online ?? this.online,
      country: country ?? this.country,
      dob: dob ?? this.dob,
      gender: gender ?? this.gender,
    );
  }
}
