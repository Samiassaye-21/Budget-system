import 'file_exporter_stub.dart'
  if (dart.library.html) 'file_exporter_web.dart'
  if (dart.library.io) 'file_exporter_io.dart';

Future<void> exportCsv(String csv, String filename) async {
  await exportCsvImpl(csv, filename);
}
