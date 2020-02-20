import 'dart:async';

import 'package:HolySheetWebserver/generated/holysheet_service.pbgrpc.dart';
import 'package:meta/meta.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../request_utils.dart';

class Endpoint {
  HolySheetServiceClient client;

  String route;
  String verb = 'GET';
  AuthMethod authMethod = AuthMethod.Header;

  Endpoint({@required String route}) : route = route;

  void register(Router router, HolySheetServiceClient client) {
    this.client = client;

    router.add(verb, route, (Request request) async {
      final token = ({
        AuthMethod.Header: () => request.headers['Authorization'],
        AuthMethod.Query: () => request.url.queryParameters['Authorization'],
      })[authMethod]();

      if (token == null) {
        return forbidden('No token found');
      }

      if (!await verifyToken(token)) {
        return forbidden('Invalid checked token');
      }

      return await handle(request, token, request.url?.queryParameters ?? {});
    });
  }

  Future<Response> handle(
      Request request, String token, Map<String, String> query) async {}
}
