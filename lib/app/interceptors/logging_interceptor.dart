import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

class LoggingInterceptor extends PrettyDioLogger {
  LoggingInterceptor()
      : super(
          request: true,
          requestBody: true,
          responseBody: true,
          responseHeader: false,
          requestHeader: true,
          error: true,
          compact: true,
        );
}
