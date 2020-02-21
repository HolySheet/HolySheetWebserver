import 'package:HolySheetWebserver/generated/holysheet_service.pb.dart';
import 'package:shelf/src/request.dart';
import 'package:shelf/src/response.dart';

import '../../request_utils.dart';
import '../endpoint.dart';

class DeleteEndpoint extends Endpoint {
  DeleteEndpoint([String route = '/delete']) : super(route: route);

  @override
  Future<Response> handle(
      Request request, String token, Map<String, String> query) async {
    final idString = query['id'] ?? '';
    final permanent = (query['permanent'] ?? 'false') == 'true';

    if (idString == null || idString.isEmpty || idString == 'null') {
      return bad('Invalid ID');
    }

    for (var id in idString.split(',')) {
      await client
          .removeFile(RemoveRequest()
            ..token = token
            ..id = id
            ..permanent = permanent)
          .printErrors();
    }

    return ok('Deleted successfully');
  }
}
