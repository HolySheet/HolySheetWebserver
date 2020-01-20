import 'package:HolySheetWebserver/generated/holysheet_service.pbgrpc.dart';
import 'package:HolySheetWebserver/grpc_client.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';

class Service {
  HolySheetServiceClient client;

  Handler createHandler() {
    final router = Router();

    // After the google sign-in, store the auth code via the Java program
    router.get('/callback', (Request request) async {
      var query = request.url.queryParameters;
      var code = query['code'];

      print('Storing "$code"');

      var response = await client.storeCode(StoreCodeRequest()..code = code);
      print('Response = $response');

      return Response.ok('ok');
    });

    // After the google sign-in, store the auth code via the Java program
    router.post('/check', (Request request) async {
      final post = await decodeRequest(request);
      print('post = $post');

      var response =
          await client.check(CheckRequest()..token = post['Authorization']);
      print('Response = $response');

      return Response.ok('ok');
    });

    router.all('/<ignored|.*>', (Request request) {
      return Response.notFound('Page not found bruh');
    });

    return Pipeline().addMiddleware(_fixCORS).addHandler(router.handler);
  }

  Future<Map<String, String>> decodeRequest(Request request) async =>
      Map.fromEntries((await request.readAsString()).split('&').map((kv) {
        var split =
            kv.split('=').map((str) => Uri.decodeComponent(str)).toList();
        return MapEntry(split[0], split[1]);
      }).toList());
}

final Map<String, String> _headers = {
  'Access-Control-Allow-Origin': 'http://localhost:8080',
  'x-frame-options': 'allow-from http://localhost:8080',
  'Content-Type': 'application/json'
};

// for OPTIONS (preflight) requests just add headers and an empty response
Response _options(Request request) =>
    (request.method == 'OPTIONS') ? Response.ok(null, headers: _headers) : null;

Response _cors(Response response) => response.change(headers: _headers);

Middleware _fixCORS =
    createMiddleware(requestHandler: _options, responseHandler: _cors);

// Run shelf server and host a [Service] instance on port 8080.
void main() async {
  final service = Service();
  final grpcClient = GRPCClient();
  await grpcClient.start(8888);
  service.client = grpcClient.client;

  print('Initialized gRPC client');

  final server = await io.serve(service.createHandler(), 'localhost', 8090);

  print('Server running on localhost:${server.port}');
}
