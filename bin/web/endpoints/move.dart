import 'package:HolySheetWebserver/generated/holysheet_service.pb.dart';
import 'package:shelf/src/request.dart';
import 'package:shelf/src/response.dart';

import '../../request_utils.dart';
import '../endpoint.dart';

class MoveEndpoint extends Endpoint {
  MoveEndpoint([String route = '/']) : super(route: route);

  @override
  Future<Response> handle(
      Request request, String token, Map<String, String> query) async {
    final idString = query['id'] ?? '';
    final path = query['path'] ?? '';

    if (!isValidParam(idString) || !isValidParam(path)) {
      return bad('Invalid parameters');
    }

    for (var id in idString.split(',')) {
      await client
          .moveFile(MoveFileRequest()
            ..token = token
            ..id = id
            ..path = path)
          .printErrors();
    }

    return ok('Moved successfully');
  }
}
