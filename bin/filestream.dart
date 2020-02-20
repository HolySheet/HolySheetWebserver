import 'dart:convert';

import 'package:HolySheetWebserver/generated/holysheet_service.pb.dart';

class FileStreamTransformer extends Converter<List<int>, FileChunk> {
  final String processingId;

  const FileStreamTransformer(String processingId)
      : processingId = processingId;

  @override
  FileChunk convert(List<int> input) => FileChunk()
    ..processingId = processingId
    ..content = input
    ..status = FileChunk_ChunkStatus.Normal;
}
