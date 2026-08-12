sealed class AsyncState<T> {
  const AsyncState();
}

final class AsyncInitial<T> extends AsyncState<T> {
  const AsyncInitial();
}

final class AsyncLoading<T> extends AsyncState<T> {
  const AsyncLoading({this.previousData});

  final T? previousData;
}

final class AsyncEmpty<T> extends AsyncState<T> {
  const AsyncEmpty();
}

final class AsyncData<T> extends AsyncState<T> {
  const AsyncData(this.data);

  final T data;
}

final class AsyncFailure<T> extends AsyncState<T> {
  const AsyncFailure({required this.error, this.stackTrace, this.previousData});

  final Object error;
  final StackTrace? stackTrace;
  final T? previousData;
}
