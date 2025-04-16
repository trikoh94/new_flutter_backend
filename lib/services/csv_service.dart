import 'dart:convert';
import 'package:csv/csv.dart';

class CsvService {
  String convertListToCsv(List<List<dynamic>> rows) {
    return const ListToCsvConverter().convert(rows);
  }

  List<List<dynamic>> convertCsvToList(String csv) {
    return const CsvToListConverter().convert(csv);
  }

  String encodeCsv(List<List<dynamic>> rows) {
    return base64Encode(utf8.encode(convertListToCsv(rows)));
  }

  List<List<dynamic>> decodeCsv(String encodedCsv) {
    return convertCsvToList(utf8.decode(base64Decode(encodedCsv)));
  }

  Future<String> readCsvFile(String path) async {
    // TODO: Implement file reading
    throw UnimplementedError('File reading not implemented yet');
  }

  Future<void> writeCsvFile(String path, String csv) async {
    // TODO: Implement file writing
    throw UnimplementedError('File writing not implemented yet');
  }
}
