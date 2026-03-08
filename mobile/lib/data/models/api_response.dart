class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? message;

  ApiResponse({required this.success, this.data, this.message});

  factory ApiResponse.fromJson(Map<String, dynamic> json, T? data) {
    return ApiResponse(
      success: json['success'] ?? true,
      data: data,
      message: json['message'],
    );
  }
}
