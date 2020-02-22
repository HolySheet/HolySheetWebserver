import 'dart:async';
import 'dart:convert';

import 'package:HolySheetWebserver/generated/holysheet_service.pb.dart';
import 'package:fixnum/fixnum.dart';
import 'package:shelf/shelf.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../processor.dart';
import '../../request_utils.dart';
import '../websocket.dart';

class UploadWebsocket extends Websocket {
  UploadWebsocket([String route = '/upload'])
      : super(route: route, authMethod: AuthMethod.Query);

  @override
  FutureOr<Response> handle(
      Request request,
      String token,
      Map<String, String> query,
      FutureOr<Response> Function(Function(WebSocketChannel) onConnection)
          activateWebsocket) async {
    var fileName = query['name'];
    var path = query['path'].correctPath();
    final fileSize = Int64.parseInt(query['length']);

    var processingId = uuid.v4();
    final processor = FileProcessor(processingId, fileName);
    processingFiles.add(processor);

    final uploadRequest = client
        .uploadFile(UploadRequest()
          ..token = token
          ..processingId = processingId
          ..name = fileName
          ..upload = UploadRequest_Upload.MULTIPART
          ..compression = UploadRequest_Compression.NONE
          ..sheetSize = Int64(10000000)
          ..fileSize = fileSize
          ..path = path)
        .printErrors();

    final streamController = StreamController<FileChunk>.broadcast();
    final completer = Completer.sync();
    final buffer = <int>[];
//    final maxBuffer = 10001000; // 10.001MB (decimal to prevent de-syncing between this and core)
    final maxBuffer = 4000000; // 4MB due to gRPC restrictions

    Function() sendResponse;
    Function() completeFunction;

    var serverBuffer = 0;
    var sentBytes = 0;

    client.sendFile(streamController.stream).printErrors().listen((response) {
      serverBuffer = response.currentBuffer.toInt();
      sendResponse?.call();
    });

    void sendBuffer() {
      streamController.add(FileChunk()
        ..processingId = processingId
        ..content = [...buffer]
        ..status = FileChunk_ChunkStatus.Normal);
      sentBytes += buffer.length;
      buffer.clear();
    }

    uploadRequest.listen((response) {
      if (response.uploadStatus == UploadResponse_UploadStatus.READY) {
        completer.complete();
      } else if (response.uploadStatus ==
          UploadResponse_UploadStatus.COMPLETE) {
        completeFunction?.call();
      }
    });

    await completer.future;

    return activateWebsocket((webSocket) {
      final sink = webSocket.sink;

      completeFunction = () {
        print('Upload request complete');
        sink.close(1000, json({'status': 'done'}));
      };

      sendResponse = () {
        var progress = sentBytes / fileSize.toDouble();
        sink.add(json({'status': 'ok', 'progress': progress}));
      };

      webSocket.stream.map(((s) => s as List<int>)).listen((data) {
        try {
          // Give 10kb of wiggle room between max buffer
          if (data.length > maxBuffer + 10000) {
            sink.close(
                1009,
                json({
                  'status': 'Maximum payload size is $maxBuffer bytes',
                  'progress': 0
                }));
            streamController.close();
            return;
          }

          buffer.addAll(data);

          if (buffer.length + serverBuffer >= maxBuffer) {
            sendBuffer();
          }

          if (fileSize.toInt() == sentBytes + buffer.length) {
            streamController.add(FileChunk()
              ..processingId = processingId
              ..content = [...buffer]
              ..status = FileChunk_ChunkStatus.Complete);
            return;
          }
        } catch (e, s) {
          print(e);
          print(s);
          sink.close(
              1011,
              json({
                'status': 'An internal error occurred',
                'error': e,
                'stacktrace': s,
              }));
          streamController.close();
        }
        // before I did sendResponse() code directly
      }, onDone: () => print('Websocket closed'));

      // Get first request
      sink.add(json({'status': 'ok', 'progress': 0}));
    });
  }
}
