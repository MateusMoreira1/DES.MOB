import 'dart:convert';
import 'dart:math';

import 'package:logger/logger.dart';

final logger = Logger(printer: NoShenanigansPrinter());

class NoShenanigansPrinter extends LogPrinter {
  /// Matches a stacktrace line as generated on Android/iOS devices.
  ///
  /// For example:
  /// * #1      Logger.log (package:logger/src/logger.dart:115:29)
  static final _deviceStackTraceRegex = RegExp(r'#[0-9]+\s+(.+) \((\S+)\)');

  /// Matches a stacktrace line as generated by Flutter web.
  ///
  /// For example:
  /// * packages/logger/src/printers/pretty_printer.dart 91:37
  static final _webStackTraceRegex = RegExp(r'^((packages|dart-sdk)/\S+/)');

  /// Matches a stacktrace line as generated by browser Dart.
  ///
  /// For example:
  /// * dart:sdk_internal
  /// * package:logger/src/logger.dart
  static final _browserStackTraceRegex = RegExp(
    r'^(?:package:)?(dart:\S+|\S+)',
  );

  final List<String> excludePaths = [];
  final int stackTraceBeginIndex;

  NoShenanigansPrinter({this.stackTraceBeginIndex = 0});

  @override
  List<String> log(LogEvent event) {
    final logLevel = switch (event.level) {
      Level.all => "ALL",
      Level.trace => "TRACE",
      Level.debug => "DEBUG",
      Level.info => "INFO",
      Level.warning => "WARNING",
      Level.error => "ERROR",
      Level.fatal => "FATAL",
      Level.off => "OFF",
      _ =>
        throw UnimplementedError(
          "Using deprecated log level: `nothing`, `wtf` or `verbose`",
        ),
    };
    final time =
        '${event.time.year.toString()}-${event.time.month.toString().padLeft(2, "0")}'
        '-${event.time.day.toString().padLeft(2, "0")} ${event.time.hour.toString().padLeft(2, "0")}'
        ':${event.time.minute.toString().padLeft(2, "0")}:${event.time.second.toString().toString().padLeft(2, "0")}';
    String output = "$time [$logLevel] ${stringifyMessage(event.message)} ";
    if (event.error != null) {
      final stackTraceStr = formatStackTrace(event.stackTrace, null);
      output += '\nERROR MESSAGE: ';
      output += event.error!.toString();
      if (stackTraceStr != null) {
        output += '\nSTACKTRACE:';
        output += '\n$stackTraceStr';
      }
    }

    return [output];
  }

  String? formatStackTrace(StackTrace? stackTrace, int? methodCount) {
    List<String> lines =
        stackTrace
            .toString()
            .split('\n')
            .where(
              (line) =>
                  !_discardDeviceStacktraceLine(line) &&
                  !_discardWebStacktraceLine(line) &&
                  !_discardBrowserStacktraceLine(line) &&
                  line.isNotEmpty,
            )
            .toList();
    List<String> formatted = [];

    int stackTraceLength =
        (methodCount != null ? min(lines.length, methodCount) : lines.length);
    for (int count = 0; count < stackTraceLength; count++) {
      var line = lines[count];
      if (count < stackTraceBeginIndex) {
        continue;
      }
      formatted.add('#$count   ${line.replaceFirst(RegExp(r'#\d+\s+'), '')}');
    }

    if (formatted.isEmpty) {
      return null;
    } else {
      return formatted.join('\n');
    }
  }

  bool _discardDeviceStacktraceLine(String line) {
    var match = _deviceStackTraceRegex.matchAsPrefix(line);
    if (match == null) {
      return false;
    }
    final segment = match.group(2)!;
    if (segment.startsWith('package:logger')) {
      return true;
    }
    return _isInExcludePaths(segment);
  }

  bool _discardWebStacktraceLine(String line) {
    var match = _webStackTraceRegex.matchAsPrefix(line);
    if (match == null) {
      return false;
    }
    final segment = match.group(1)!;
    if (segment.startsWith('packages/logger') ||
        segment.startsWith('dart-sdk/lib')) {
      return true;
    }
    return _isInExcludePaths(segment);
  }

  bool _discardBrowserStacktraceLine(String line) {
    var match = _browserStackTraceRegex.matchAsPrefix(line);
    if (match == null) {
      return false;
    }
    final segment = match.group(1)!;
    if (segment.startsWith('package:logger') || segment.startsWith('dart:')) {
      return true;
    }
    return _isInExcludePaths(segment);
  }

  bool _isInExcludePaths(String segment) {
    for (var element in excludePaths) {
      if (segment.startsWith(element)) {
        return true;
      }
    }
    return false;
  }

  Object toEncodableFallback(dynamic object) {
    return object.toString();
  }

  String stringifyMessage(dynamic message) {
    final finalMessage = message is Function ? message() : message;
    if (finalMessage is Map || finalMessage is Iterable) {
      var encoder = JsonEncoder.withIndent('  ', toEncodableFallback);
      return encoder.convert(finalMessage);
    } else {
      return finalMessage.toString();
    }
  }
}
