sealed class LinkedValue<T> {
  const LinkedValue._();

  int get length;

  factory LinkedValue.empty() => _EmptyLinkedThing<T>();

  LinkedValue<T> followedBy(T value);

  List<T> toList();
}

final class _EmptyLinkedThing<T> extends LinkedValue<T> {
  const _EmptyLinkedThing() : super._();

  @override
  int get length => 0;

  @override
  LinkedValue<T> followedBy(T value) => _LinkedThing<T>(null, value);

  @override
  List<T> toList() => const [];
}

final class _LinkedThing<T> extends LinkedValue<T> {
  final _LinkedThing<T>? _previous;
  final T _value;

  @override
  final int length;

  _LinkedThing(this._previous, this._value)
    : length = 1 + (_previous?.length ?? 0),
      super._();

  @override
  LinkedValue<T> followedBy(T value) => _LinkedThing<T>(this, value);

  @override
  List<T> toList() {
    final list = <T>[];
    for (
      _LinkedThing<T>? previous = this;
      previous != null;
      previous = previous._previous
    ) {
      list.add(previous._value);
    }

    return list.reversed.toList(growable: false);
  }

  @override
  String toString() => '${super.toString()} ($length)';
}
