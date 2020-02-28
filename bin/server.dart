import 'dart:io';

import 'package:HolySheetWebserver/generated/holysheet_service.pbgrpc.dart';
import 'package:HolySheetWebserver/grpc_client.dart';
import 'package:logging/logging.dart';
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
import 'request_utils.dart';

final log = Logger('Server');

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
  Logger.root.level = Level.ALL; // defaults to Level.INFO
  Logger.root.onRecord.listen((record) {
    var logString = '[${record.time.hour.timePadded}:${record.time.minute.timePadded}:${record.time.second.timePadded}] [${record.loggerName}/${record.level.name}]: ${record.message}';
    (record.level == Level.SEVERE ? stderr.writeln : print)(logString);
    if (record.error != null) {
      stderr.writeln(record.error);
      if (record.stackTrace != null) {
        stderr.writeln(record.stackTrace);
      }
    }
  });

  final service = Backend();
  final grpcClient = GRPCClient();
  await grpcClient.start(int.tryParse('${env['GRPC']}') ?? 8888);

  log.fine('Initialized gRPC client');

  final server = await io.serve(service.createHandler(grpcClient.client),
      '0.0.0.0', int.tryParse('${env['PORT']}') ?? 80);

  log.fine('Server running on localhost:${server.port}');
}
