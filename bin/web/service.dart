import 'package:HolySheetWebserver/generated/holysheet_service.pbgrpc.dart';
import 'package:shelf_router/shelf_router.dart';

abstract class Service {
  void register(Router router, HolySheetServiceClient client);
}
