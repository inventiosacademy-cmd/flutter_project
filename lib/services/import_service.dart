import 'dart:convert';
import 'dart:io';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';
import 'package:open_file/open_file.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart' show kIsWeb, Uint8List;
import '../models/karyawan.dart';

class ImportService {
  static const List<String> _headers = [
    'Nama',
    'Posisi',
    'Departemen',
    'Atasan Langsung',
    'Tanggal Masuk (YYYY-MM-DD)',
    'Tanggal Berakhir PKWT (YYYY-MM-DD)',
    'PKWT Ke'
  ];

  /// Pick a file (CSV or Excel) and return parsed Employees
  Future<List<Employee>> pickAndParseFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'xlsx', 'xls'],
        withData: true, // Important for Web and ensuring bytes are available
      );

      if (result != null) {
        PlatformFile pFile = result.files.single;
        String extension = pFile.extension?.toLowerCase() ?? '';
        print("Selected file: ${pFile.name}, extension: $extension");
        
        // Use bytes if available (Web or withData: true), otherwise try path
        List<int>? fileBytes = pFile.bytes;
        
        if (fileBytes == null && pFile.path != null) {
          // Fallback to reading from path if bytes are null (e.g. Desktop/Mobile without withData, though we requested it)
          File file = File(pFile.path!);
          fileBytes = await file.readAsBytes();
        }

        if (fileBytes != null) {
          print("File bytes loaded: ${fileBytes.length} bytes");
          if (extension == 'csv') {
            return _parseCsvBytes(fileBytes);
          } else if (extension == 'xlsx' || extension == 'xls') {
            return _parseExcelBytes(fileBytes);
          }
        } else {
          print("Failed to load file bytes");
        }
      } else {
        print("File picker cancelled");
      }
    } catch (e) {
      print("Error picking/parsing file: $e");
      rethrow;
    }
    return [];
  }

  List<Employee> _parseCsvBytes(List<int> bytes) {
    final input = utf8.decode(bytes);
    List<List<dynamic>> fields = const CsvToListConverter().convert(input);
    
    // Remove header if present (check for common header keywords)
    if (fields.isNotEmpty && fields[0].isNotEmpty) {
      String firstCell = fields[0][0].toString().toLowerCase();
      if (firstCell.contains('nama') || firstCell == 'name') {
        fields.removeAt(0);
      }
    }

    List<Employee> employees = [];
    for (var row in fields) {
      // Skip empty rows
      if (row.isEmpty || row.every((val) => val == null || val.toString().trim().isEmpty)) {
        continue;
      }
      
      if (row.length >= 7) {
        try {
          employees.add(_mapRowToEmployee(row));
        } catch (e) {
          print("Error parsing row: $row, error: $e");
        }
      } else {
        print("Skipping row with insufficient columns: $row");
      }
    }
    return employees;
  }

  List<Employee> _parseExcelBytes(List<int> bytes) {
    var excel = Excel.decodeBytes(bytes);
    List<Employee> employees = [];

    for (var table in excel.tables.keys) {
      var sheet = excel.tables[table];
      if (sheet == null) continue;

      bool isHeader = true;
      for (var row in sheet.rows) {
        if (isHeader) {
          isHeader = false;
          continue; // Skip header
        }

        // Convert Data objects to values
        List<dynamic> rowValues = row.map((cell) => cell?.value).toList();
        
        // Check if row is empty or all values are null/empty
        if (rowValues.isEmpty || rowValues.every((val) => val == null || val.toString().trim().isEmpty)) {
          continue;
        }

        // Ensure we have at least 7 columns
        if (rowValues.length < 7) {
          print("Skipping row with insufficient columns: $rowValues");
          continue;
        }

        try {
          employees.add(_mapRowToEmployee(rowValues));
        } catch (e) {
          print("Error parsing excel row: $rowValues, error: $e");
        }
      }
    }
    return employees;
  }

  Employee _mapRowToEmployee(List<dynamic> row) {
    // Helper to safely get string
    String getString(dynamic val) => val?.toString().trim() ?? '';
    
    // Helper to parse date with multiple format support
    DateTime parseDate(dynamic val) {
      if (val == null) return DateTime.now();
      if (val is DateTime) return val;
      
      String dateStr = val.toString().trim();
      if (dateStr.isEmpty) return DateTime.now();
      
      try {
        // Try ISO format first (YYYY-MM-DD)
        return DateTime.parse(dateStr);
      } catch (e) {
        // Try Indonesian format (DD-MM-YYYY or DD/MM/YYYY)
        try {
          List<String> parts = dateStr.contains('-') 
              ? dateStr.split('-') 
              : dateStr.split('/');
          
          if (parts.length == 3) {
            int day = int.parse(parts[0]);
            int month = int.parse(parts[1]);
            int year = int.parse(parts[2]);
            return DateTime(year, month, day);
          }
        } catch (e2) {
          print("Failed to parse date: $dateStr, error: $e2");
        }
        return DateTime.now();
      }
    }

    // Helper to parse int
    int getInt(dynamic val) {
      if (val == null) return 1;
      if (val is int) return val;
      String strVal = val.toString().trim();
      return int.tryParse(strVal) ?? 1;
    }

    return Employee(
      id: DateTime.now().millisecondsSinceEpoch.toString() + getString(row[0]).replaceAll(' ', ''), // Generate temp ID
      nama: getString(row[0]),
      posisi: getString(row[1]),
      departemen: getString(row[2]),
      atasanLangsung: getString(row[3]),
      tglMasuk: parseDate(row[4]),
      tglPkwtBerakhir: parseDate(row[5]),
      pkwtKe: getInt(row[6]),
    );
  }

  /// Generate and download Excel template
  Future<void> downloadTemplate() async {
    var excel = Excel.createExcel();
    Sheet sheetObject = excel['Template Karyawan'];
    excel.setDefaultSheet('Template Karyawan');

    // Define Header Style
    CellStyle headerStyle = CellStyle(
      fontFamily: 'Calibri',
      bold: true,
      fontSize: 12,
      backgroundColorHex: ExcelColor.fromHexString('#BFDBFE'), // Blue 200 equivalent
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    // Define Data Style
    CellStyle dataStyle = CellStyle(
      fontFamily: 'Calibri',
      fontSize: 11,
      horizontalAlign: HorizontalAlign.Left,
      verticalAlign: VerticalAlign.Center,
    );

    // Add headers
    List<String> headers = _headers;
    for (var i = 0; i < headers.length; i++) {
      var cell = sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = headerStyle;
    }

    // Add a sample row
    List<dynamic> sampleData = [
      'John Doe',
      'Software Engineer',
      'IT',
      'Jane Smith',
      '2024-01-01',
      '2025-01-01',
      1,
    ];

    for (var i = 0; i < sampleData.length; i++) {
      var cell = sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 1));
      if (sampleData[i] is int) {
        cell.value = IntCellValue(sampleData[i]);
      } else {
        cell.value = TextCellValue(sampleData[i].toString());
      }
      cell.cellStyle = dataStyle;
    }

    // Set Column Widths (Approximate)
    sheetObject.setColumnWidth(0, 25.0); // Nama
    sheetObject.setColumnWidth(1, 20.0); // Posisi
    sheetObject.setColumnWidth(2, 15.0); // Departemen
    sheetObject.setColumnWidth(3, 20.0); // Atasan
    sheetObject.setColumnWidth(4, 20.0); // Tgl Masuk
    sheetObject.setColumnWidth(5, 25.0); // Tgl Berakhir
    sheetObject.setColumnWidth(6, 10.0); // PKWT Ke

    // Save file
    try {
      var fileBytes = excel.save();
      if (fileBytes == null) return;

      // Use FileSaver for cross-platform support (Web, Mobile, Desktop)
      await FileSaver.instance.saveFile(
        name: 'template_karyawan',
        bytes: Uint8List.fromList(fileBytes),
        ext: 'xlsx',
        mimeType: MimeType.microsoftExcel,
      );
      
    } catch (e) {
      print("Error saving template: $e");
      rethrow;
    }
  }
}
