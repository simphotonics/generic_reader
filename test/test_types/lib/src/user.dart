import 'title.dart';

class Age {
  const Age(this.age);
  final int age;
  bool get isAdult => age > 21;

  @override
  String toString() {
    return 'age: $age';
  }
}

class Name {
  const Name({
    required this.firstName,
    required this.lastName,
    this.middleName = '',
  });
  final String firstName;
  final String lastName;
  final String middleName;

  @override
  String toString() {
    return '$firstName ${middleName == '' ? '' : middleName + ' ' }$lastName';
  }
}

class User {
  const User({
    required this.name,
    required this.id,
    required this.age,
    required this.title,
  });
  final Name name;
  final Age age;
  final int id;
  final Title title;

  @override
  String toString() {
    return 'user: $name\n'
        '  title: ${title}\n'
        '  id: $id\n'
        '  $age\n';
  }
}
