import 'dart:io';
import 'dart:math';

import 'package:ffmpeg_kit_flutter_full/log.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:fvp/fvp.dart' as fvp;
import 'package:open_file/open_file.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'ffmpeg.dart';

void main() {
  fvp.registerWith();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const MyHomePage(title: 'Flutter FFMPEG Sample'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  File? file;
  bool loading = false;
  List<String> videoExtns = [
    'mp4',
    'mov',
    'mkv',
    'wmv',
    'mxf',
    // 'avchd',
    'mts',
    // 'r3d',
    // 'ari',
    // 'cine',
    // 'dpxx',
    // 'braw',
    // 'arw',
    // 'dng',
  ];
  late String value;

  @override
  void initState() {
    super.initState();
    value = videoExtns.firstOrNull ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            onPressed: () {
              openffmpegLog();
            },
            icon: Icon(
              Icons.folder,
            ),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(file?.path ?? ''),
            SizedBox(
              height: 10,
            ),
            ElevatedButton(
              onPressed: () async {
                final PlatformFile? f =
                    (await FilePicker.platform.pickFiles())?.files.firstOrNull;
                if (f?.path == null || f!.path!.isEmpty) {
                  return;
                }
                file = File(f.path!);
                setState(() {});
              },
              child: Text('Pick A File'),
            ),

            SizedBox(
              height: 10,
            ),
            SizedBox(
              width: 100,
              child: DropdownButtonFormField<String>(
                items: videoExtns.map((dropdown) {
                  return DropdownMenuItem<String>(
                    value: dropdown,
                    child: Text(dropdown),
                  );
                }).toList(),
                value: value,
                onChanged: (v) {
                  if (v == null) {
                    return;
                  }
                  value = v;
                  setState(() {});
                },
              ),
            ),
            SizedBox(
              height: 10,
            ),
            if (file != null)
              loading
                  ? CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: () async {
                        setState(() {
                          loading = true;
                        });
                        try {
                          await conversion(exten: value);
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(e.toString()),
                            ),
                          );
                        }
                        setState(() {
                          loading = false;
                        });
                      },
                      child: Text('Convert'),
                    ),
            // if (file != null)
            //   Container(
            //     width: 500,
            //     height: 500,
            //     color: Colors.green,
            //     child: AppVideoPlayer(file!),
            //   ),
          ],
        ),
      ),
      // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  Future<void> conversion({required String exten}) async {
    var start = DateTime.now();
    final oldPath = file?.path ?? '';
    final newFileName = '${DateTime.now().millisecondsSinceEpoch}.$exten';
    final base = oldPath.split('/');
    base.removeLast();
    final newPath = '${base.join('/')}/$newFileName';
    final String command =
        '-i "$oldPath" -s 720x480 -preset ultrafast "$newPath" ';

    await FFmpegKit.execute(command).then((session) async {
      final returnCode = await session.getReturnCode();

      if (ReturnCode.isSuccess(returnCode)) {
        print("SUCCESS");
      } else if (ReturnCode.isCancel(returnCode)) {
        print("CANCELED");
      } else {
        print("ERROR");
        final String? v = await session.getFailStackTrace();
        final List<Log> logs = await session.getLogs();
        final error = logs.map((e) => e.getMessage()).join('\n\n');
        await ffmpegLog(error);
        throw (Exception(error ?? 'ERROR'));
      }
    });
    var end = DateTime.now();
    var oldFileSize = await File(oldPath).length();
    var newFileSize = await File(newPath).length();
    var newLine =
        '\n______________________________________________________________________________\n';

    ffmpegLog(
      '*Start \n\n Command: $command \n\n file Path: $oldPath \n\n fileSize: ${oldFileSize.getFileSize()} \n\n  new path: $newPath \n\n newFileSize: ${newFileSize.getFileSize()} \n\n Time Taken: ${end.difference(start).inSeconds}s\n\n *Completed\n$newLine',
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Successfully Converted'),
      ),
    );
  }

  Future<void> ffmpegLog(String error) async {
    print(error);

    final dbFolder = await getApplicationDocumentsDirectory();
    final File file = File(p.join(dbFolder.path, 'ffmpeg.log'));
    if (!file.existsSync()) {
      await file.create(recursive: true);
    }
    await file.writeAsString(error, mode: FileMode.append);
  }

  Future<void> openffmpegLog() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final File file = File(p.join(dbFolder.path, 'ffmpeg.log'));
    if (!file.existsSync()) {
      await file.create(recursive: true);
    }
    await OpenFile.open(file.path);
  }
}

extension BytesUtils on int {
  String getFileSize() {
    if (this <= 0) {
      return "0 B";
    }
    const suffixes = ["B", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"];
    var i = (log(this) / log(1024)).floor();
    return '${(this / pow(1024, i)).toStringAsFixed(2)} ${suffixes[i]}';
  }
}
