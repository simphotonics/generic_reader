part of '../reader.dart';

class ListDecoder<T> extends Decoder<List<T>> {
  const ListDecoder();

  @override
  List<T> read(DartObject obj) =>
      switch (obj.toListValue()?.map((item) => item.read<T>())) {
        Iterable<T> iterable => iterable.toList(),
        _ => throw readError(obj),
      };
}

class SetDecoder<T> extends Decoder<Set<T>> {
  const SetDecoder({this.prototype = const {}});
  final Set<T> prototype;

  @override
  Set<T> read(DartObject obj) =>
      switch (obj.toSetValue()?.map((item) => item.read<T>())) {
        Iterable<T> iterable => iterable.toSet(),
        _ => throw readError(obj),
      };
}

class IterableDecoder<T> extends Decoder<Iterable<T>> {
  const IterableDecoder({this.prototype = const {}});
  final Set<T> prototype;

  @override
  Set<T> read(DartObject obj) =>
      switch (obj.toSetValue()?.map((item) => item.read<T>())) {
        Iterable<T> iterable => iterable.toSet(),
        _ => throw readError(obj),
      };
}
