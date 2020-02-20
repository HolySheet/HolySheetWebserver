import 'dart:async';

import 'package:shelf/shelf.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../processor.dart';
import '../request_utils.dart';

FutureOr<Response> authedWebsocket(Request request) async {
  final processingId = request.url.queryParameters['processingToken'];

  if (processingId == null) {
    return forbidden('No processing token found');
  }

  var processor = processingFiles.firstWhere(
      (processor) => processor.id == processingId,
      orElse: () => null);
  if (!(processor?.accepting ?? false)) {
    return forbidden('No open file processor with ID found');
  }

  return webSocketHandler((WebSocketChannel webSocket) {
    final sink = webSocket.sink;
    processor.handler = (percentage) => sink.add('$percentage');
    processor.close = (code, reason) => webSocket.sink.close(code, reason);
  })(request);
}
