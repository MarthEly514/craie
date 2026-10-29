import 'dart:convert';
import 'dart:typed_data';

import 'package:craie/network/api_client.dart';
import 'package:craie/network/api_exception.dart';
import 'package:craie/shared/services/session_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide Response;

/// fausse HTTP Layer.
class FakeAdapter implements HttpClientAdapter {
  final Future<ResponseBody> Function(RequestOptions) handler;
  final List<RequestOptions> requests = [];

  FakeAdapter(this.handler);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    requests.add(options);
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody jsonBody(Object data, int status) => ResponseBody.fromString(
      jsonEncode(data),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );

void main() {
  late SessionService session;

  setUp(() {
    session = Get.put(SessionService());
  });

  tearDown(Get.reset);

  test('adds the bearer token to requests', () async {
    session.accessToken = 'abc';
    final adapter = FakeAdapter((_) async => jsonBody([], 200));

    await ApiClient(adapter: adapter).get('/resources');
    expect(adapter.requests.single.headers['Authorization'], 'Bearer abc');
  });
  
  test('turns an API error into an ApiException with the French message', () async {
    final adapter = FakeAdapter((_) async => jsonBody(
          {'code': 'SLOT_CONFLICT', 'message': 'Ce créneau est déjà réservé'},
          409,
        ));

    expect(
      () => ApiClient(adapter: adapter).post('/reservations', data: {}),
      throwsA(
        isA<ApiException>()
            .having((e) => e.code, 'code', 'SLOT_CONFLICT')
            .having((e) => e.message, 'message', 'Ce créneau est déjà réservé'),
      ),
    );
  });
  
  test('refreshes once for several simultaneous 401s, then retries them', () async {
    session.accessToken = 'old';
    session.refreshToken = 'r1';
    var refreshCalls = 0;
    final adapter = FakeAdapter((options) async {
      if (options.path == '/auth/refresh') {
        refreshCalls++;
        await Future<void>.delayed(const Duration(milliseconds: 50));
        return jsonBody({'accessToken': 'new', 'refreshToken': 'r2'}, 200);
      }
      final ok = options.headers['Authorization'] == 'Bearer new';
      return ok ? jsonBody([], 200) : jsonBody({'code': 'UNAUTHORIZED', 'message': 'x'}, 401);
    });
    final client = ApiClient(adapter: adapter);

    await Future.wait([
      client.get('/resources'),
      client.get('/resources'),
      client.get('/resources'),
    ]);

    expect(refreshCalls, 1);
    expect(session.accessToken, 'new');
    expect(session.refreshToken, 'r2');
  });
}
