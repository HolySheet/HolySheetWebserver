import 'dart:io';

import 'package:HolySheetWebserver/generated/holysheet_service.pb.dart';
import 'package:logging/logging.dart';
import 'package:shelf/src/request.dart';
import 'package:shelf/src/response.dart';

import '../../request_utils.dart';
import '../endpoint.dart';
import '../endpoint_manager.dart';

class DownloadEndpoint extends Endpoint {
  @override
  final log = Logger('DownloadEndpoint');

  DownloadEndpoint([String route = '/download']) : super(route: route, authMethod: AuthMethod.Query);

  @override
  Future<Response> handle(
      Request request, String token, Map<String, String> query) async {
    final id = query['id'] ?? '';

    if (id == null || id.isEmpty || id == 'null' || id.contains(',')) {
      return bad('Invalid ID');
    }

    final downloadId = uuid.v4();
    final file =
        File('${env['PROCESSING_PATH']}${Platform.pathSeparator}$downloadId');

    final downloaded = await processStream<ListItem, DownloadResponse>(
        await client
            .downloadFile(DownloadRequest()
              ..token = token
              ..id = id
              ..path = file.absolute.path)
            .printErrors(), (data) {
      log.fine('Downloading ${data.percentage * 100}%');
      return data.status == DownloadResponse_DownloadStatus.COMPLETE;
    }, (data) => data.item);

    return serveFile(request, downloaded.name, file);
  }
}
