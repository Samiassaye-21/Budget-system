import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

Future<void> exportCsvImpl(String csv, String filename) async {
  final dir = await getApplicationDocumentsDirectory();
  final file = File('${dir.path}/$filename.csv');
  await file.writeAsString(csv);
  await OpenFilex.open(file.path);
}
