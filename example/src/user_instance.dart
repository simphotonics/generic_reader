import 'package:test_types/test_types.dart';

/// Defining a constant of type `User`.
const user = User(
    name: Name(firstName: 'Thomas', lastName: 'Smith', middleName: 'W'),
    id: 1,
    age: Age(32),
    title: Title.Mr);

const list = {0, 1, 2};

const Iterable<int> iterable = list;
