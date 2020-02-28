import 'package:HolySheetWebserver/generated/holysheet_service.pb.dart';
import 'package:logging/logging.dart';
import 'package:shelf/src/request.dart';
import 'package:shelf/src/response.dart';

import '../../request_utils.dart';
import '../endpoint.dart';

class RestoreEndpoint extends Endpoint {
  @override
  final log = Logger('RestoreEndpoint');

  RestoreEndpoint([String route = '/restore']) : super(route: route);

  @override
  Future<Response> handle(
      Request request, String token, Map<String, String> query) async {
    final idString = query['id'] ?? '';

    if (idString == null || idString.isEmpty || idString == 'null') {
      return bad('Invalid ID');
    }

    for (var id in idString.split(',')) {
      await client
          .restoreFile(RestoreRequest()
            ..token = token
            ..id = id)
          .printErrors();
    }

    return ok('Restored successfully');
  }
}
