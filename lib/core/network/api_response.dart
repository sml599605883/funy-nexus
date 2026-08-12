class ApiResponse<T> {
  const ApiResponse({
    required this.code,
    required this.message,
    required this.data,
  });

  final String code;
  final String message;
  final T data;
}
