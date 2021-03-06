// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:flutter_tools/src/base/os.dart';
import 'package:flutter_tools/src/commands/analyze_continuously.dart';
import 'package:flutter_tools/src/dart/pub.dart';
import 'package:flutter_tools/src/dart/sdk.dart';
import 'package:flutter_tools/src/runner/flutter_command_runner.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import 'src/context.dart';

void main() {
  AnalysisServer server;
  Directory tempDir;

  setUp(() {
    FlutterCommandRunner.initFlutterRoot();
    tempDir = Directory.systemTemp.createTempSync('analysis_test');
  });

  tearDown(() {
    tempDir?.deleteSync(recursive: true);
    return server?.dispose();
  });

  group('analyze --watch', () {
    testUsingContext('AnalysisServer success', () async {
      _createSampleProject(tempDir);

      await pubGet(directory: tempDir.path);

      server = new AnalysisServer(dartSdkPath, <String>[tempDir.path]);

      int errorCount = 0;
      Future<bool> onDone = server.onAnalyzing.where((bool analyzing) => analyzing == false).first;
      server.onErrors.listen((FileAnalysisErrors errors) => errorCount += errors.errors.length);

      await server.start();
      await onDone;

      expect(errorCount, 0);
    }, overrides: <Type, Generator>{
      OperatingSystemUtils: () => os
    });
  });

  testUsingContext('AnalysisServer errors', () async {
    _createSampleProject(tempDir, brokenCode: true);

    await pubGet(directory: tempDir.path);

    server = new AnalysisServer(dartSdkPath, <String>[tempDir.path]);

    int errorCount = 0;
    Future<bool> onDone = server.onAnalyzing.where((bool analyzing) => analyzing == false).first;
    server.onErrors.listen((FileAnalysisErrors errors) => errorCount += errors.errors.length);

    await server.start();
    await onDone;

    expect(errorCount, 2);
  }, overrides: <Type, Generator>{
    OperatingSystemUtils: () => os
  });
}

void _createSampleProject(Directory directory, { bool brokenCode: false }) {
  File pubspecFile = new File(path.join(directory.path, 'pubspec.yaml'));
  pubspecFile.writeAsStringSync('''
name: foo_project
''');

  File dartFile = new File(path.join(directory.path, 'lib', 'main.dart'));
  dartFile.parent.createSync();
  dartFile.writeAsStringSync('''
void main() {
  print('hello world');
  ${brokenCode ? 'prints("hello world");' : ''}
}
''');
}
