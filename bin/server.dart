import 'dart:convert';
import 'dart:io';

import 'package:HolySheetWebserver/generated/holysheet_service.pbgrpc.dart';
import 'package:HolySheetWebserver/grpc_client.dart';
import 'package:HolySheetWebserver/serializer.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:http/http.dart' as http;

const CLIENT_ID =
    '916425013479-6jdls4crv26mhurj43eakbs72f5e1m8t.apps.googleusercontent.com';
final FULL_SCOPES = ['https://www.googleapis.com/auth/userinfo.profile', 'https://www.googleapis.com/auth/userinfo.email', 'https://www.googleapis.com/auth/drive'];
final ACCESS_TOKEN_PATTERN = RegExp(r'^[a-zA-Z0-9-._~+\/]*$');

class Service {
  HolySheetServiceClient client;

  Handler createHandler() {
    final router = Router();

    // After the google sign-in, store the auth code via the Java program
    router.get('/list', (Request request) async {
      final token = request.url?.queryParameters['Authorization'];
      final path = request.url?.queryParameters['path'] ?? '';

      if (!await verifyToken(token)) {
        return forbidden('Invalid token');
      }

      var response = await client.listFiles(ListRequest()
        ..token = token
        ..path = path);

      return ok(serialize(response.items));
    });

    router.all('/<ignored|.*>', (Request request) => notFound('Page not found bruh'));

    return Pipeline().addMiddleware(_fixCORS).addHandler(router.handler);
  }

  /// Returns a [Response] with the code 200 Okay.
  /// To see [body] docs, see [getBody].
  Response ok(dynamic body) => getBody(200, body);

  /// Returns a [Response] with the code 403 Forbidden.
  /// To see [body] docs, see [getBody].
  Response forbidden(dynamic body) => getBody(403, body);

  /// Returns a [Response] with the code 403 Forbidden.
  /// To see [body] docs, see [getBody].
  Response notFound(dynamic body) => getBody(404, body);

  /// Gets the body, used for [Request]s.
  /// [body] can be either a Map<String, String> which is encoded into a JSON
  /// map, whereas anything else will be [toString]'d and put with an `error`
  /// key.
  Response getBody(int code, dynamic body, {String defaultKey = 'message'}) {
    if (body is String) {
      body = {defaultKey: body ?? 'Unknown message'};
    }
    print('body = ');
    print(body);
    return Response(code, body: jsonEncode(body), headers: {
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': 'http://localhost:8080',
      'x-frame-options': 'allow-from http://localhost:8080',
    });
  }

  /// Decodes post values
  Future<Map<String, String>> decodeRequest(Request request) async =>
      Map.fromEntries((await request.readAsString()).split('&').map((kv) {
        var split =
            kv.split('=').map((str) => Uri.decodeComponent(str)).toList();
        return MapEntry(split[0], split[1]);
      }).toList());

  Future<bool> verifyToken(String accessToken) async {
    try {
      if (accessToken == null || !ACCESS_TOKEN_PATTERN.hasMatch(accessToken)) {
        return Future.value(false);
      }

      var response = await http.get(
          'https://www.googleapis.com/oauth2/v1/tokeninfo?access_token=$accessToken');
      var json = jsonDecode(response.body);

      if (json['audience'] != CLIENT_ID) {
        print('Audience do not match');
        return false;
      }

      var split = json['scope']?.split(' ')?.toSet();
      if (!(split?.containsAll(FULL_SCOPES) ?? true)) {
        print('User missing scope(s)');
        return false;
      }

      return true;
    } catch (ignored) {
      return false;
    }
  }
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
