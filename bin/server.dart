import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:HolySheetWebserver/generated/holysheet_service.pbgrpc.dart';
import 'package:HolySheetWebserver/grpc_client.dart';
import 'package:HolySheetWebserver/serializer.dart';
import 'package:meta/meta.dart';
import 'package:mime/mime.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:http/http.dart' as http;
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:math';

const CLIENT_ID =
    '916425013479-6jdls4crv26mhurj43eakbs72f5e1m8t.apps.googleusercontent.com';
final FULL_SCOPES = [
  'https://www.googleapis.com/auth/userinfo.profile',
  'https://www.googleapis.com/auth/userinfo.email',
  'https://www.googleapis.com/auth/drive'
];
final ACCESS_TOKEN_PATTERN = RegExp(r'^[a-zA-Z0-9-._~+\/]*$');

class Service {
  final uuid = Uuid();
  final router = Router();
  final processingFiles = <FileProcessor>[];
  HolySheetServiceClient client;

  Handler createHandler() {
    bindAuthenticated(
        route: '/list',
        handler: (request, token) async {
          final path = request.url?.queryParameters['path'] ?? '';

          var response = await client.listFiles(ListRequest()
            ..token = token
            ..path = path);

          return ok(serialize(response.items));
        });

    bindAuthenticated(
        route: '/upload',
        verb: 'POST',
        chromeWaitBug: true,
        handler: (request, token) async {
          try {
            var processingId = uuid.v4();
            var header = HeaderValue.parse(request.headers['content-type']);

            // Only accept one file (For now)
            final first = await request.read().transform(
                MimeMultipartTransformer(header.parameters['boundary'])).single;

              if (!first.headers.containsKey('content-disposition')) {
                return getBody(400, 'Header "Content-Disposition" not found');
              }

              header = HeaderValue.parse(first.headers['content-disposition']);
              var filename = header.parameters['filename'];
              print('filename = $filename ($processingId)');
              final file = File('upload\\$processingId');
              var fileSink = file.openWrite();
              await first.pipe(fileSink);
              await fileSink.close();

            final processor = FileProcessor(processingId, filename);
            processingFiles.add(processor);

            var iter = 0.toDouble();
            Timer.periodic(Duration(milliseconds: 750), (t) {
              iter += 0.1;
              processor.handler?.call(iter);

              if ((1 - iter).abs() <= 0.01) {
                t.cancel();
                processor.close?.call();
              }
            });

            return ok({
              'message': 'Received successfully',
              'processingToken': processingId,
            });
          } catch (e, s) {
            return ise(e, '$s');
          }
        });

    router.get('/websocket', authedWebsocket);

    router.all(
        '/<ignored|.*>', (Request request) => notFound('Page not found'));

    return Pipeline().addMiddleware(_fixCORS).addHandler(router.handler);
  }

  FutureOr<Response> authedWebsocket(Request request) async {
    final processingId = request.url.queryParameters['processingToken'];

    if (processingId == null) {
      return forbidden('No processing token found');
    }

    var processor = processingFiles.firstWhere(
        (processor) => processor.id == processingId,
        orElse: () => null);
    if (!(processor?.accepting ?? false)) {
      return forbidden('No open file processor with ID found');
    }

    return webSocketHandler((WebSocketChannel webSocket) {
      final sink = webSocket.sink;
      processor.handler = (percentage) => sink.add('$percentage');
      processor.close = () => webSocket.sink.close();
    })(request);
  }

  void bindAuthenticated(
      {@required String route,
      @required Future<Response> Function(Request, String) handler,
      bool chromeWaitBug = false,
      String verb = 'GET'}) {
    router.add(verb, route, (Request request) async {
      final token = request.headers['Authorization'];

      if (token == null) {
        return forbidden('Invalid token');
      }

      if (!await verifyToken(token)) {
        return forbidden('Invalid token');
      }

      return await handler(request, token);
    });
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

  /// Returns a [Response] with the code 500 Internal Server Error.
  /// To see [body] docs, see [getBody].
  Response ise(String message, String stacktrace) =>
      getBody(500, {'message': message, 'stacktrace': stacktrace});

  /// Gets the body, used for [Request]s.
  /// [body] can be either a Map<String, String> which is encoded into a JSON
  /// map, whereas anything else will be [toString]'d and put with an `error`
  /// key.
  Response getBody(int code, dynamic body, {String defaultKey = 'message'}) {
    if (body is String) {
      body = {defaultKey: body ?? 'Unknown message'};
    }
    return Response(code, body: jsonEncode(body));
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

class FileProcessor {
  String id;
  String name;
  void Function(double) handler;
  void Function() close;

  bool get accepting => handler == null;

  FileProcessor(this.id, this.name);
}

final Map<String, String> _headers = {
  'x-frame-options': 'allow-from http://localhost:8080',
  'Access-Control-Allow-Origin': 'http://localhost:8080',
  'Access-Control-Expose-Headers': 'Authorization, Content-Type',
  'Access-Control-Allow-Headers':
      'Authorization, Origin, X-Requested-With, Content-Type, Accept',
  'Access-Control-Allow-Methods': 'GET, POST',
  'Access-Control-Max-Age': '9999',
//  'Content-Type': 'application/json',
};

// for OPTIONS (preflight) requests just add headers and an empty response
Response _options(Request request) =>
    (request.method == 'OPTIONS') ? Response.ok(null, headers: _headers) : null;

Response _cors(Response response) => response.change(headers: _headers);

Middleware _fixCORS =
    createMiddleware(requestHandler: _options, responseHandler: _cors);

int get millsTime => DateTime.now().millisecondsSinceEpoch;

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
