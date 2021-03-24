import 'package:source_gen/source_gen.dart' show ConstantReader;

/// Typedef of a function with return type [T]
/// and an input argument of type [ConstantReader].
///
/// Functions of this type may be registered as decoders with
/// the (singleton) instance of [GenericReader].
///
/// Example:
/// ```
/// class CustomType{
///  const CustomType({this.id, this.name});
///  final int id;
///  final String name;
/// }
///
/// final reader = GenericReader();
/// reader.addDecoder<CustomType>((constantReader) {
///   // Read constructor arguments.
///   final id = constantReader.peek('id').intValue;
///   final name = constantReader.peek('name').stringValue;
///   // Return an instance of CustomType
///   return CustomType(id: id, name: name);
/// });
/// ```
typedef Decoder<T> = T Function(ConstantReader constantReader);
