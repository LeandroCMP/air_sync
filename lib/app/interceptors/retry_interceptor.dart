import 'package:dio_smart_retry/dio_smart_retry.dart';

class RetryInterceptor extends DioRetryInterceptor {
  RetryInterceptor({required super.dio}) : super(retryOptions: const RetryOptions(retries: 3, retryInterval: Duration(seconds: 2)));
}
