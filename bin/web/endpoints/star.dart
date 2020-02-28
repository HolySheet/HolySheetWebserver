import 'package:HolySheetWebserver/generated/holysheet_service.pb.dart';
import 'package:logging/logging.dart';
import 'package:shelf/src/request.dart';
import 'package:shelf/src/response.dart';

import '../../request_utils.dart';
import '../endpoint.dart';

class StarEndpoint extends Endpoint {
  @override
  final log = Logger('StarEndpoint');

  StarEndpoint([String route = '/star']) : super(route: route);

  @override
  Future<Response> handle(
      Request request, String token, Map<String, String> query) async {
    final idString = query['id'] ?? '';
    final starred = query['starred']?.toLowerCase() ?? '';

    if ((starred != 'true' && starred != 'false') || !isValidParam(idString)) {
      return bad('Invalid parameters');
    }

    for (var id in idString.split(',')) {
      await client
          .starRequest(StarRequest()
            ..token = token
            ..id = id
            ..starred = starred == 'true')
          .printErrors();
    }

    return ok('Starred successfully');
  }
}
