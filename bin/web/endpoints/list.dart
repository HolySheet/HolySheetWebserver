import 'package:HolySheetWebserver/generated/holysheet_service.pb.dart';
import 'package:HolySheetWebserver/serializer.dart';
import 'package:logging/logging.dart';
import 'package:shelf/src/request.dart';
import 'package:shelf/src/response.dart';

import '../../request_utils.dart';
import '../endpoint.dart';
import '../endpoint_manager.dart';

class ListEndpoint extends Endpoint {
  @override
  final log = Logger('ListEndpoint');

  ListEndpoint([String route = '/list']) : super(route: route);

  @override
  Future<Response> handle(
      Request request, String token, Map<String, String> query) async {
    final path = query['path'] ?? '';
    final starred = query['starred']?.toLowerCase() == 'true';
    final trashed = query['trashed']?.toLowerCase() == 'true';

    var response = await client.listFiles(ListRequest()
      ..token = token
      ..path = path.correctPath()
      ..starred = starred
      ..trashed = trashed);

    return ok({'files': serialize(response.items), 'folders': response.folders});
  }
}
