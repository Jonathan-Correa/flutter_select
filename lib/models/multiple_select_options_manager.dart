class MultipleSelectOptionManager<T> {
  Set<T> _added = {};
  Set<T> _removed = {};

  void clear() {
    _added = {};
    _removed = {};
  }

  void add(T item) {}

  Set<T> get added => _added;
  Set<T> get removed => _removed;
}
