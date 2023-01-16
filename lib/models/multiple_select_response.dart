class MultipleSelectResponse<T> {
  const MultipleSelectResponse(this.added, this.removed);

  final List<T> added;
  final List<T> removed;
}
