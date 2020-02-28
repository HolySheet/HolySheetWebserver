import 'dart:io';

import 'package:HolySheetWebserver/generated/holysheet_service.pbgrpc.dart';
import 'package:logging/logging.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../request_utils.dart';
import 'service.dart';

final env = Platform.environment;

int get millsTime => DateTime.now().millisecondsSinceEpoch;

class EndpointManager {
  final log = Logger('EndpointManager');
  final HolySheetServiceClient client;
  final services = <Service>[];

  EndpointManager(this.client);

  void addService(Service registrable) => services.add(registrable);

  void addServices(List<Service> registrable) => services.addAll(registrable);

  Handler createHandler() {
    final router = Router();
    for (var service in services) {
      service.register(router, client);
    }

    log.fine('Registered ${services.length} services');

    router.all(
        '/<ignored|.*>', (Request request) => notFound('Resource not found'));

    return Pipeline()
        .addMiddleware(createMiddleware(
            requestHandler: (Request request) => (request.method == 'OPTIONS')
                ? Response.ok(null, headers: _headers)
                : null,
            responseHandler: (Response response) =>
                response.change(headers: {...response.headers, ..._headers})))
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
  'X-Backend-Server': Platform.localHostname,
};

class RawHandler {
  String verb;
  String path;
  Function handler;

  RawHandler(this.verb, this.path, this.handler);
}
