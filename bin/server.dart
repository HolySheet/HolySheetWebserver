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

    router.all('/<ignored|.*>', (Request request) {
      return Response.notFound('Page not found bruh');
    });

    return router.handler;
  }
}

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
