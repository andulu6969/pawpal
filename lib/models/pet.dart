class Pet {
  String? petId;
  String? userId;
  String? ownerName;
  String? petName;
  String? petType;
  String? petAge;
  String? petGender;
  String? petHealth;
  String? category;
  String? description;
  String? imagePaths;
  String? createdAt;

  Pet({
    this.petId,
    this.userId,
    this.ownerName,
    this.petName,
    this.petType,
    this.petAge,
    this.petGender,
    this.petHealth,
    this.category,
    this.description,
    this.imagePaths,
    this.createdAt,
  });

  Pet.fromJson(Map<String, dynamic> json) {
    petId = json['pet_id'];
    userId = json['user_id'];
    ownerName = json['owner_name'];
    petName = json['pet_name'];
    petType = json['pet_type'];
    petAge = json['pet_age'];
    petGender = json['pet_gender'];
    petHealth = json['pet_health'];
    category = json['category'];
    description = json['description'];
    imagePaths = json['image_paths'];
    createdAt = json['created_at'];
  }
}
