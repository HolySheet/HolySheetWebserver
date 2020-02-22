import 'package:HolySheetWebserver/generated/holysheet_service.pbgrpc.dart';
import 'package:HolySheetWebserver/grpc_client.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;

import 'web/endpoint_manager.dart';
import 'web/endpoints/create_folder.dart';
import 'web/endpoints/delete.dart';
import 'web/endpoints/download.dart';
import 'web/endpoints/list.dart';
import 'web/endpoints/move.dart';
import 'web/endpoints/restore.dart';
import 'web/endpoints/star.dart';
import 'web/endpoints/upload.dart';

class Backend {
  Handler createHandler(HolySheetServiceClient client) {
    final manager = EndpointManager(client);

    manager.addServices([
      DownloadEndpoint(),
      ListEndpoint(),
      DeleteEndpoint(),
      RestoreEndpoint(),
      StarEndpoint(),
      MoveEndpoint(),
      UploadWebsocket(),
      CreateFolderEndpoint(),
    ]);

    return manager.createHandler();
  }
}

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
