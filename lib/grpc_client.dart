import 'package:HolySheetWebserver/generated/holysheet_service.pbgrpc.dart';
import 'package:grpc/grpc.dart';

class GRPCClient {

  ClientChannel channel;
  HolySheetServiceClient client;

  /// Starts the gRPC server with the given port.
  Future<void> start([int port = 8080]) async {
    channel = ClientChannel('localhost',
        port: port,
        options:
        const ChannelOptions(credentials: ChannelCredentials.insecure()));
    client = HolySheetServiceClient(channel,
        options: CallOptions(timeout: Duration(seconds: 10)));
  }
}
