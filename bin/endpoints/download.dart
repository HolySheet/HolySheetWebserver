import 'dart:io';

import 'package:HolySheetWebserver/generated/holysheet_service.pb.dart';
import 'package:shelf/src/request.dart';
import 'package:shelf/src/response.dart';

import '../request_utils.dart';
import 'endpoint.dart';
import 'endpoint_manager.dart';

class DownloadEndpoint extends Endpoint {
  DownloadEndpoint([String route = '/download']) : super(route: route);

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
    print('downloading with ID: $file');

    final downloaded = await processStream<ListItem, DownloadResponse>(
        await client
            .downloadFile(DownloadRequest()
              ..token = token
              ..id = id
              ..path = file.absolute.path)
            .printErrors(), (data) {
      print('Downloading ${data.percentage * 100}%');
      return data.status == DownloadResponse_DownloadStatus.COMPLETE;
    }, (data) => data.item);

    print('serving $file');

    return serveFile(request, downloaded.name, file);
  }
}
