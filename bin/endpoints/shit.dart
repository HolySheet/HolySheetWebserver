import 'dart:io';
import 'dart:math';

import 'package:mime/mime.dart';
import 'package:shelf/src/request.dart';
import 'package:shelf/src/response.dart';

import '../request_utils.dart';
import 'endpoint.dart';

class ShitEndpoint extends Endpoint {
  ShitEndpoint([String route = '/shit']) : super(route: route);

  @override
  String verb = 'POST';

  @override
  Future<Response> handle(
      Request request, String token, Map<String, String> query) async {
    print(
        'hereeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee: ${request.hashCode}');
    try {
      var processingId = uuid.v4();
      var header = HeaderValue.parse(request.headers['content-type']);

      // Only accept one file (For now)
//            final first = await request
//                .read()
//                .transform(
//                    MimeMultipartTransformer(header.parameters['boundary']))
//                .first;

      var requestStreams = await request
          .read()
          .transform(MimeMultipartTransformer(header.parameters['boundary']));

      // First is beginning byte index
      // Second is end byte index
      // Third is actual data (<=10kb)

      var streams = await requestStreams.toList();

      var firstStream = await streams[0];
      var secondStream = await streams[1];

      print('first head: ${firstStream.headers}');
      print('second head: ${secondStream.headers}');
      var beginNumber = fromArr(await firstStream.first);
      var endNumber = fromArr(await secondStream.first);

      print('[$beginNumber - $endNumber]');

      return null;

      var first = null;

      if (!first.headers.containsKey('content-disposition')) {
        return getBody(400, 'Header "Content-Disposition" not found');
      }

      final fileLengthString = request.headers['content-length'];

      header = HeaderValue.parse(first.headers['content-disposition']);
      print(header.parameters);
      var fileName = header.parameters['filename'];

//            final maxBuffer = 10001000; // 10.001MB (decimal to prevent de-syncing between this and core)
//            final maxBuffer = 4000000; // 4MB due to gRPC restrictions
//            final buffer = <int>[];
//            var serverBuffer = 0;

      first.listen((data) {
        print('got data: $data');
      }, onError: (e, s) {
        print(e);
        print(s);
      }, onDone: () {
        print('done');
      });

//            client.sendFile(streamController.stream).printErrors().listen((response) {
//              serverBuffer = response.currentBuffer.toInt();
//              print('Updating server buffer to $serverBuffer');
//            });

      return ok({
        'message': 'Received successfully',
        'processingToken': processingId,
      });
    } catch (e, s) {
      return ise('$e', '$s');
    }
  }

  int fromArr(List<int> input) {
    var num = 0;
    var index = input.length - 1;
    for (var value in input) {
      num += (value * pow(10, index--));
      print('num = $num');
    }
    return num;
  }
}
