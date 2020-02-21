import 'dart:async';
import 'dart:io';

import 'package:HolySheetWebserver/generated/holysheet_service.pb.dart';
import 'package:fixnum/fixnum.dart';
import 'package:mime/mime.dart';
import 'package:shelf/src/request.dart';
import 'package:shelf/src/response.dart';

import '../../processor.dart';
import '../../request_utils.dart';
import '../endpoint.dart';

class UploadEndpoint extends Endpoint {
  @override
  String verb = 'POST';

  UploadEndpoint([String route = '/upload']) : super(route: route);

  @override
  Future<Response> handle(
      Request request, String token, Map<String, String> query) async {
//    try {
//      var processingId = uuid.v4();
//      var header = HeaderValue.parse(request.headers['content-type']);
//
//      // Only accept one file (For now)
//      final first = await request
//          .read()
//          .transform(MimeMultipartTransformer(header.parameters['boundary']))
//          .single;
//
//      if (!first.headers.containsKey('content-disposition')) {
//        return getBody(400, 'Header "Content-Disposition" not found');
//      }
//
//      // This is not the exact file size, as it includes standard request
//      // headers. In terms of 10s, 100s, or even 1000s of millions of
//      // bytes, a few thousand won't throw it off too much.
//      final fileLengthString = request.headers['content-length'];
//
//      header = HeaderValue.parse(first.headers['content-disposition']);
//      print(header.parameters);
//      var fileName = header.parameters['filename'];
//
//      final processor = FileProcessor(processingId, fileName);
//      processingFiles.add(processor);
//
//      var uploadResponse = client
//          .uploadFile(UploadRequest()
//            ..token = token
//            ..processingId = processingId
//            ..name = fileName
//            ..upload = UploadRequest_Upload.MULTIPART
//            ..compression = UploadRequest_Compression.NONE
//            ..sheetSize = Int64(10000000)
//            ..fileSize = Int64.parseInt(fileLengthString))
//          .printErrors();
//
//      final streamController = StreamController<FileChunk>.broadcast();
//      final completer = Completer.sync();
//
//      var firstRequest = true;
//      uploadResponse.listen((response) {
//        if (firstRequest) {
//          firstRequest = false;
//          completer.complete(null);
//        }
//
//        switch (response.status) {
//          case UploadResponse_UploadStatus.PENDING:
//            print('Pending...');
//            break;
//          case UploadResponse_UploadStatus.UPLOADING:
//            print('Uploading ${response.percentage * 100}%');
//            processor.handler?.call(response.percentage);
//            break;
//          case UploadResponse_UploadStatus.COMPLETE:
//            print('Upload complete');
//            processor.close?.call(1000, 'Success');
//            streamController.close();
//            break;
//        }
//      }, onError: (e, s) {
//        processor.close?.call(1011, 'An error occurred: $e');
//        return ise('$e', '$s');
//      }, onDone: () => processor.close?.call(1011, 'Incomplete'));
//
//      print('Uploading $fileName ($processingId)');
//
////            final stream = first.transform(FileStreamTransformer(processingId));
//
//      print('here');
//      await completer.future;
//      print('send first');
//
////            final maxBuffer = 10001000; // 10.001MB (decimal to prevent de-syncing between this and core)
//      final maxBuffer = 4000000; // 4MB due to gRPC restrictions
//      final buffer = <int>[];
//      var serverBuffer = 0;
//
//      void sendBuffer() {
//        print('Sending buffer');
//        streamController.add(FileChunk()
//          ..processingId = processingId
//          ..content = [...buffer]
//          ..status = FileChunk_ChunkStatus.Normal);
//        buffer.clear();
//      }
//
//      first.listen((data) {
//        buffer.addAll(data);
//
//        // Send a little more than one sheet over at a time
//        if (buffer.length + serverBuffer >= maxBuffer) {
//          sendBuffer();
//        }
//      }, onError: (e, s) {
//        print(e);
//        print(s);
//        streamController.add(FileChunk()
//          ..processingId = processingId
//          ..content = []
//          ..status = FileChunk_ChunkStatus.Terminated);
//      }, onDone: () {
//        if (buffer.isNotEmpty) {
//          sendBuffer();
//        }
//
//        streamController.add(FileChunk()
//          ..processingId = processingId
//          ..content = []
//          ..status = FileChunk_ChunkStatus.Complete);
//      });
//
//      client.sendFile(streamController.stream).printErrors().listen((response) {
//        serverBuffer = response.currentBuffer.toInt();
//        print('Updating server buffer to $serverBuffer');
//      });
//
//      return ok({
//        'message': 'Received successfully',
//        'processingToken': processingId,
//      });
//    } catch (e, s) {
//      return ise('$e', '$s');
//    }

    return ok({'message': 'bruh'});
  }
}
