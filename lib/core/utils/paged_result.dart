class PagedResult<T> {
  const PagedResult({
    required this.items,
    required this.hasMore,
    this.nextCursor,
  });

  final List<T> items;
  final bool hasMore;
  final Object? nextCursor;
}
