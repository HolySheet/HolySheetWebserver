import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:convert/convert.dart';
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import 'package:shelf/shelf.dart';

final _defaultMimeTypeResolver = MimeTypeResolver();

Handler createStaticHandler(String fileSystemPath,
    {String defaultDocument,
    bool useHeaderBytesForContentType = false,
    List<String> ignoredExtensions = const [],
    MimeTypeResolver contentTypeResolver}) {
  var rootDir = Directory(fileSystemPath);
  if (!rootDir.existsSync()) {
    throw ArgumentError('A directory corresponding to fileSystemPath '
        '"$fileSystemPath" could not be found');
  }

  fileSystemPath = rootDir.resolveSymbolicLinksSync();

  if (defaultDocument != null) {
    if (defaultDocument != p.basename(defaultDocument)) {
      throw ArgumentError('defaultDocument must be a file name.');
    }
  }

  contentTypeResolver ??= _defaultMimeTypeResolver;

  return (Request request) {
    var fsPath = p.joinAll([fileSystemPath, ...request.url.pathSegments]);

    final file = tryWithExtensions(File(fsPath), ignoredExtensions)
        ?? _tryDefaultFile(fsPath, defaultDocument, ignoredExtensions);

    if (file == null) {
      return Response.notFound('Not Found');
    }

    var resolvedPath = file.resolveSymbolicLinksSync();

    if (!p.isWithin(fileSystemPath, resolvedPath)) {
      return Response.notFound('Not Found');
    }

    return _handleFile(request, file, () async {
      if (useHeaderBytesForContentType) {
        var length = math.min(
            contentTypeResolver.magicNumbersMaxLength, file.lengthSync());

        var byteSink = ByteAccumulatorSink();

        await file.openRead(0, length).listen(byteSink.add).asFuture();

        return contentTypeResolver.lookup(file.path,
            headerBytes: byteSink.bytes);
      } else {
        return contentTypeResolver.lookup(file.path);
      }
    });
  };
}

Response _redirectToAddTrailingSlash(Uri uri) {
  var location = Uri(
      scheme: uri.scheme,
      userInfo: uri.userInfo,
      host: uri.host,
      port: uri.port,
      path: uri.path + '/',
      query: uri.query);

  return Response.movedPermanently(location.toString());
}

File _tryDefaultFile(
    String dirPath, String defaultFile, List<String> ignoredExtensions) {
  if (defaultFile == null) return null;

  var filePath = p.join(dirPath, defaultFile);

  return tryWithExtensions(File(filePath), ignoredExtensions);
}

File tryWithExtensions(File base, List<String> ignoredExtensions) {
  if (base.existsSync()) {
    return base;
  }

  return ignoredExtensions
        .map((extension) => copyWithExtension(base, extension))
        .firstWhere((file) => file.existsSync(), orElse: () => null);
}

File copyWithExtension(File base, String extension) {
  final path = [...base.uri.pathSegments];
  path.add(path.removeLast() + '.html');
  return File.fromUri(base.uri.replace(pathSegments: path));
}

/// Serves the contents of [file] in response to [request].
///
/// This handles caching, and sends a 304 Not Modified response if the request
/// indicates that it has the latest version of a file. Otherwise, it calls
/// [getContentType] and uses it to populate the Content-Type header.
Future<Response> _handleFile(
    Request request, File file, FutureOr<String> getContentType()) async {
  var stat = file.statSync();
  var ifModifiedSince = request.ifModifiedSince;

  if (ifModifiedSince != null) {
    var fileChangeAtSecResolution = toSecondResolution(stat.changed);
    if (!fileChangeAtSecResolution.isAfter(ifModifiedSince)) {
      return Response.notModified();
    }
  }

  var headers = {
    HttpHeaders.contentLengthHeader: stat.size.toString(),
    HttpHeaders.lastModifiedHeader: formatHttpDate(stat.changed)
  };

  var contentType = await getContentType();
  if (contentType != null) headers[HttpHeaders.contentTypeHeader] = contentType;

  return Response.ok(file.openRead(), headers: headers);
}

DateTime toSecondResolution(DateTime time) {
  if (time.millisecond == 0) return time;
  return time.subtract(Duration(milliseconds: time.millisecond));
}
