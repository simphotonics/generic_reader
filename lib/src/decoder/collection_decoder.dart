part of '../reader.dart';

class ListDecoder<E> extends Decoder<List<E>> {
  const ListDecoder();

  @override
  List<E> read(DartObject obj) =>
      switch (obj.toListValue()?.map((item) => item.read<E>())) {
        Iterable<E> iterable => iterable.toList(),
        _ => throw readError(obj),
      };
}

class SetDecoder<T> extends Decoder<Set<T>> {
  const SetDecoder();

  @override
  Set<T> read(DartObject obj) =>
      switch (obj.toSetValue()?.map((item) => item.read<T>())) {
        Iterable<T> iterable => iterable.toSet(),
        _ => throw readError(obj),
      };
}

class IterableDecoder<T> extends Decoder<Iterable<T>> {
  const IterableDecoder();

  @override
  Set<T> read(DartObject obj) =>
      switch (obj.toSetValue()?.map((item) => item.read<T>())) {
        Iterable<T> iterable => iterable.toSet(),
        _ => throw readError(obj),
      };
}

class MapDecoder<K, V> extends Decoder<Map<K, V>> {
  const MapDecoder();
  @override
  Map<K, V> read(DartObject obj) {
    final result = <K, V>{};

    final mapObj = obj.toMapValue();
    if (mapObj == null) {
      throw readError(obj);
    } else {
      mapObj.forEach((keyObj, valueObj) {
        final key = keyObj?.read<K>();
        final value = valueObj?.read<V>();

        if (key is K && value is V) {
          //TODO will this test ever fail? Should this method throw?
          result[key] = value;
        }
      });
      return result;
    }
  }
}
