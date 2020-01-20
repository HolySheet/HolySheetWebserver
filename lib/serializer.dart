import 'dart:convert';

import 'package:HolySheetWebserver/generated/holysheet_service.pb.dart';

dynamic serialize(dynamic object) {
  if (object is List<ListItem>) {
    return object.map((item) => item.toProto3Json()).toList();
  }

  return {};
}
