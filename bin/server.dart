import 'dart:async';
import 'dart:convert';

import 'package:HolySheetWebserver/generated/holysheet_service.pbgrpc.dart';
import 'package:HolySheetWebserver/grpc_client.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'web/endpoint_manager.dart';
import 'web/endpoints/delete.dart';
import 'web/endpoints/download.dart';
import 'web/endpoints/list.dart';
import 'web/endpoints/move.dart';
import 'web/endpoints/processing.dart';
import 'web/endpoints/restore.dart';
import 'web/endpoints/shit.dart';
import 'web/endpoints/star.dart';
import 'web/endpoints/upload.dart';

class Backend {
  Handler createHandler(HolySheetServiceClient client) {
    final manager = EndpointManager(client);

    manager.addServices([
      UploadEndpoint(),
//      ShitEndpoint(),
      DownloadEndpoint(),
      ListEndpoint(),
      DeleteEndpoint(),
      RestoreEndpoint(),
      StarEndpoint(),
      MoveEndpoint(),
      ProcessingWebsocket(),
      ShitWebsocket(),
    ]);

    return manager.createHandler();
  }
}

//FutureOr<Response> shitWebsocket(Request request) async {
//  print('Uploading "${request.requestedUri.queryParameters['name']}"');
//  return webSocketHandler((WebSocketChannel webSocket) {
//    final sink = webSocket.sink;
//
//    webSocket.stream.listen((data) {
//      print('data: ${utf8.decode(data)}');
//      sink.add('ok');
//    });
//  })(request);
//}

// Run shelf server and host a [Service] instance on port 8080.
void main() async {
  final service = Backend();
  final grpcClient = GRPCClient();
  await grpcClient.start(int.tryParse('${env['GRPC']}') ?? 8888);

  print('Initialized gRPC client');

  final server = await io.serve(service.createHandler(grpcClient.client),
      '0.0.0.0', int.tryParse('${env['PORT']}') ?? 80);

  print('Server running on localhost:${server.port}');
}
