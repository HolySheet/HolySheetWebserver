import 'package:HolySheetWebserver/generated/holysheet_service.pb.dart';
import 'package:shelf/src/request.dart';
import 'package:shelf/src/response.dart';

import '../../request_utils.dart';
import '../endpoint.dart';

class MoveEndpoint extends Endpoint {
  MoveEndpoint([String route = '/rename']) : super(route: route);

  @override
  Future<Response> handle(
      Request request, String token, Map<String, String> query) async {
    final id = query['id'] ?? '';
    final name = query['name'] ?? '';

    if (!isValidParam(id) || !isValidParam(name)) {
      return bad('Invalid parameters');
    }

    await client
        .renameFile(RenameRequest()
          ..token = token
          ..id = id
          ..name = name)
        .printErrors();

    return ok('Moved successfully');
  }
}
