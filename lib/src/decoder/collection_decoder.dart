part of '../reader.dart';

class const ListDecoder<E>() extends Decoder<List<E>> {
  @override
  List<E> read(DartObject dartObject) =>
      switch (dartObject.toListValue()?.map((item) => item.read<E>())) {
        Iterable<E> iterable => iterable.toList(),
        _ => throw readError(dartObject),
      };
}

class const SetDecoder<T>() extends Decoder<Set<T>> {
  @override
  Set<T> read(DartObject dartObject) =>
      switch (dartObject.toSetValue()?.map((item) => item.read<T>())) {
        Iterable<T> iterable => iterable.toSet(),
        _ => throw readError(dartObject),
      };
}

class const IterableDecoder<T>() extends Decoder<Iterable<T>> {
  @override
  Set<T> read(DartObject dartObject) =>
      switch (dartObject.toSetValue()?.map((item) => item.read<T>())) {
        Iterable<T> iterable => iterable.toSet(),
        _ => throw readError(dartObject),
      };
}

class const MapDecoder<K, V>() extends Decoder<Map<K, V>> {
  @override
  Map<K, V> read(DartObject dartObject) {
    final result = <K, V>{};

    final mapObj = dartObject.toMapValue();
    if (mapObj == null) {
      throw readError(dartObject);
    } else {
      mapObj.forEach((keyObj, valueObj) {
        final key = keyObj?.read<K>();
        final value = valueObj?.read<V>();

        if (key is K && value is V) {
          // Will this test ever fail? Should this method throw?
          result[key] = value;
        }
      });
      return result;
    }
  }
}
