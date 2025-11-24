class User {
  String? id;
  String? name;
  String? email;
  String? password;
  String? phone;
  String? regDate;

  User({
    this.id,
    this.name,
    this.email,
    this.password,
    this.phone,
    this.regDate,
  });

  User.fromJson(Map<String, dynamic> json) {
    id = json['user_id'];
    name = json['name'];
    email = json['email'];
    password = json['password'];
    phone = json['phone'];
    regDate = json['reg_date'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['user_id'] = id;
    data['name'] = name;
    data['email'] = email;
    data['phone'] = phone;
    data['password'] = password;
    data['reg_date'] = regDate;
    return data;
  }
}
