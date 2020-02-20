final processingFiles = <FileProcessor>[];

class FileProcessor {
  String id;
  String name;
  void Function(double) handler;
  void Function(int, String) close;

  bool get accepting => handler == null;

  FileProcessor(this.id, this.name);
}
