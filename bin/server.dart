import 'package:HolySheetWebserver/generated/holysheet_service.pbgrpc.dart';
import 'package:HolySheetWebserver/grpc_client.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:uuid/uuid.dart';

import 'endpoints/delete.dart';
import 'endpoints/download.dart';
import 'endpoints/endpoint_manager.dart';
import 'endpoints/list.dart';
import 'endpoints/move.dart';
import 'endpoints/restore.dart';
import 'endpoints/shit.dart';
import 'endpoints/star.dart';
import 'endpoints/upload.dart';
import 'endpoints/websocket.dart';

class Service {

  Handler createHandler(HolySheetServiceClient client) {
    final manager = EndpointManager(client);

    manager.addEndpoints([
      UploadEndpoint(),
      ShitEndpoint(),
      DownloadEndpoint(),
      ListEndpoint(),
      DeleteEndpoint(),
      RestoreEndpoint(),
      StarEndpoint(),
      MoveEndpoint(),
    ]);

    manager.addRaw('/websocket', authedWebsocket);

    return manager.createHandler();
  }
}

// Run shelf server and host a [Service] instance on port 8080.
void main() async {
  final service = Service();
  final grpcClient = GRPCClient();
  await grpcClient.start(int.tryParse('${env['GRPC']}') ?? 8888);

  print('Initialized gRPC client');

  final server = await io.serve(
      service.createHandler(grpcClient.client), '0.0.0.0', int.tryParse('${env['PORT']}') ?? 80);

  print('Server running on localhost:${server.port}');
}
