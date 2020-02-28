import 'dart:async';

import 'package:HolySheetWebserver/generated/holysheet_service.pbgrpc.dart';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../request_utils.dart';
import '../server.dart';
import 'service.dart';

abstract class Websocket implements Service {

  final log = Logger('Websocket');

  HolySheetServiceClient client;

  String route;
  String verb = 'GET';
  AuthMethod authMethod;

  Websocket({@required String route, AuthMethod authMethod = AuthMethod.Header}) : route = route, authMethod = authMethod;

  @override
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

      return handle(request, token, request.url?.queryParameters ?? {},
          (onConnection) => webSocketHandler(onConnection)(request));
    });
  }

  /// Creates a handler for the websocket. Allows for either a standard
  /// [Response] return such as `forbidden('Invalid token')`
  /// or the parameter [activateWebsocket], such as:
  ///
  /// ```dart
  /// return activateWebsocket((webSocket) {
  ///   print('Starting websocket on protocol: ${webSocket.protocol}');
  /// });
  /// ```
  FutureOr<Response> handle(
      Request request,
      String token,
      Map<String, String> query,
      FutureOr<Response> Function(Function(WebSocketChannel) onConnection)
          activateWebsocket);
}
