import 'dart:io';

import 'package:HolySheetWebserver/generated/holysheet_service.pbgrpc.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../request_utils.dart';
import 'endpoint.dart';

final env = Platform.environment;

int get millsTime => DateTime.now().millisecondsSinceEpoch;

class EndpointManager {
  final HolySheetServiceClient client;
  final endpoints = <Endpoint>[];
  final raw = <RawHandler>[];

  EndpointManager(this.client);

  void addEndpoints(List<Endpoint> endpoint) => endpoints.addAll(endpoint);

  void addEndpoint(Endpoint endpoint) => endpoints.add(endpoint);

  void addRaw(String path, Function handler, [String verb = 'GET']) =>
      raw.add(RawHandler(verb, path, handler));

  Handler createHandler() {
    final router = Router();
    for (var endpoint in endpoints) {
      endpoint.register(router, client);
    }

    for (var handler in raw) {
      router.add(handler.verb, handler.path, handler.handler);
    }

    router.all(
        '/<ignored|.*>', (Request request) => notFound('Page not found'));

    return Pipeline()
        .addMiddleware(createMiddleware(
            requestHandler: (Request request) => (request.method == 'OPTIONS')
                ? Response.ok(null, headers: _headers)
                : null,
            responseHandler: (Response response) =>
                response.change(headers: _headers)))
        .addHandler(router.handler);
  }
}

Map<String, String> _headers = {
  'x-frame-options': 'allow-from ${env['ALLOW_ORIGIN']}',
  'Access-Control-Allow-Origin': env['ALLOW_ORIGIN'],
  'Access-Control-Expose-Headers': 'Authorization, Content-Type',
  'Access-Control-Allow-Headers':
      'Authorization, Origin, X-Requested-With, Content-Type, Accept',
  'Access-Control-Allow-Methods': 'GET, POST',
  'Access-Control-Max-Age': '9999',
//  'Content-Type': 'application/json',
};

class RawHandler {
  String verb;
  String path;
  Function handler;

  RawHandler(this.verb, this.path, this.handler);
}
