import 'package:HolySheetWebserver/generated/holysheet_service.pb.dart';
import 'package:shelf/src/request.dart';
import 'package:shelf/src/response.dart';

import '../../request_utils.dart';
import '../endpoint.dart';

class CreateFolderEndpoint extends Endpoint {
  CreateFolderEndpoint([String route = '/createfolder']) : super(route: route);

  @override
  Future<Response> handle(
      Request request, String token, Map<String, String> query) async {
    final path = query['path'] ?? '';

    if (!isValidParam(path)) {
      return bad('Invalid parameters');
    }

      await client
          .createFolder(CreateFolderRequest()
            ..token = token
            ..path = path.correctPath())
          .printErrors();

    return ok('Creates successfully');
  }
}
