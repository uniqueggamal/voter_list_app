import 'dart:io';
import 'package:excel/excel.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:flutter/material.dart';
import '../models/voter.dart';
import '../helpers/database_helper.dart';

class ExportService {
  Future<void> exportToExcel(BuildContext context) async {
    // Show progress indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final db = await DatabaseHelper.instance.database;

      // Create the view
      await db.execute('DROP VIEW IF EXISTS voter_export_view;');
      await db.execute('''
        CREATE VIEW voter_export_view AS
        SELECT
            v.voter_no, v.name_np AS name, vd.name_en AS name_en, vd.name_en AS name_english, v.age, v.gender,
            v.parent_name_np AS parents_name, v.spouse_name_np,
            p.name AS province, d.name AS district_name, m.name AS municipality_name,
            w.ward_no, eb.booth_name,
            COALESCE(c.Mname, 'Unrecognized') as main_category,
            c.Sname as sub_category,
            (SELECT GROUP_CONCAT(t.name, ', ') FROM voter_tag vt INNER JOIN tags t ON vt.tag_id = t.id WHERE vt.voterdetail_id = vd.id) AS tags,
            vd.phone AS phone_no,
            vd.description
        FROM voter v
        LEFT JOIN election_booth eb ON v.booth_id = eb.id
        LEFT JOIN ward w ON eb.ward_id = w.id
        LEFT JOIN municipality m ON w.municipality_id = m.id
        LEFT JOIN district d ON m.district_id = d.id
        LEFT JOIN province p ON d.province_id = p.id
        LEFT JOIN categorized c ON v.voter_no = c.voter_no
        LEFT JOIN (SELECT * FROM voterdetails GROUP BY voterid) vd ON v.id = vd.voterid;
      ''');

      // Query all rows from the view
      final rows = await db.rawQuery('SELECT * FROM voter_export_view');

      if (rows.isEmpty) {
        Navigator.of(context).pop(); // Close progress dialog
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('No data to export')));
        return;
      }

      // Create Excel workbook
      final excel = Excel.createExcel();
      // Rename the default sheet to 'Voters'
      final sheet = excel.sheets.values.first;
      excel.rename('Sheet1', 'Voters');
      // Remove any extra sheets
      final sheetNames = excel.sheets.keys.toList();
      for (final name in sheetNames) {
        if (name != 'Voters') {
          excel.delete(name);
        }
      }

      // Get headers from first row keys
      final headers = rows.first.keys.map((key) => TextCellValue(key)).toList();
      sheet.appendRow(headers);

      // Add data rows
      for (final row in rows) {
        final rowData = row.values
            .map((value) => TextCellValue(value?.toString() ?? ''))
            .toList();
        sheet.appendRow(rowData);
      }

      // Save to Downloads or Documents folder
      Directory? directory;
      if (Platform.isAndroid) {
        directory = await getExternalStorageDirectory();
        if (directory != null) {
          directory = Directory('${directory.path}/Download');
          if (!await directory.exists()) {
            directory = await getExternalStorageDirectory();
          }
        }
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory == null) {
        throw Exception('Could not access storage directory');
      }

      final fileName =
          'voter_export_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      final file = File('${directory.path}/$fileName');

      await file.writeAsBytes(excel.encode()!);

      // Close progress dialog
      Navigator.of(context).pop();

      // Show success SnackBar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Exported ${rows.length} records to $fileName'),
          action: SnackBarAction(
            label: 'Open',
            onPressed: () => OpenFile.open(file.path),
          ),
        ),
      );
    } catch (e) {
      // Close progress dialog
      Navigator.of(context).pop();

      // Show error SnackBar
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
    }
  }

  Future<void> exportToExcelOld(
    List<Voter> voters,
    List<String> selectedFields,
  ) async {
    final excel = Excel.createExcel();
    final sheet = excel['Voters'];

    // Create field mapping
    final fieldMapping = {
      'voter_id': {
        'header': 'Voter ID',
        'value': (Voter v) => v.voterNo.toString(),
      },
      'name': {'header': 'Name', 'value': (Voter v) => v.nameNepali},
      'age': {'header': 'Age', 'value': (Voter v) => v.age?.toString() ?? ''},
      'gender': {'header': 'Gender', 'value': (Voter v) => v.gender ?? ''},
      'spouse_name': {
        'header': 'Spouse Name',
        'value': (Voter v) => '',
      }, // Not available in Voter model
      'parent_name': {
        'header': 'Parent Name',
        'value': (Voter v) => '',
      }, // Not available in Voter model
      'booth': {'header': 'Booth', 'value': (Voter v) => v.boothCode},
      'ward_no': {
        'header': 'Ward No',
        'value': (Voter v) => v.wardNo.toString(),
      },
      'municipality': {
        'header': 'Municipality',
        'value': (Voter v) => v.municipality,
      },
      'district': {'header': 'District', 'value': (Voter v) => v.district},
      'province': {'header': 'Province', 'value': (Voter v) => v.province},
    };

    // Add headers for selected fields
    final headers = selectedFields
        .map((field) => TextCellValue(fieldMapping[field]!['header'] as String))
        .toList();
    sheet.appendRow(headers);

    // Add data for selected fields
    for (final voter in voters) {
      final rowData = selectedFields.map((field) {
        final value = (fieldMapping[field]!['value'] as String Function(Voter))(
          voter,
        );
        return value.isNotEmpty ? TextCellValue(value) : TextCellValue('');
      }).toList();
      sheet.appendRow(rowData);
    }

    // Save file
    final directory = await getExternalStorageDirectory();
    final fileName = 'voters_${DateTime.now().millisecondsSinceEpoch}.xlsx';
    final file = File('${directory!.path}/$fileName');

    await file.writeAsBytes(excel.encode()!);
    await OpenFile.open(file.path);
  }

  Future<void> exportToPdf(List<Voter> voters) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(level: 0, child: pw.Text('Voter List Report')),
          pw.Table.fromTextArray(
            headers: [
              'ID',
              'Voter No',
              'Name (Nepali)',
              'Age',
              'Gender',
              'Booth Code',
              'Ward No',
              'Municipality',
              'Municipality Code',
              'District',
              'Province',
            ],
            data: voters
                .map(
                  (voter) => [
                    voter.id.toString(),
                    voter.voterNo,
                    voter.nameNepali,
                    voter.age?.toString() ?? '',
                    voter.gender ?? '',
                    voter.boothCode,
                    voter.wardNo.toString(),
                    voter.municipality,
                    voter.municipalityCode,
                    voter.district,
                    voter.province,
                  ],
                )
                .toList(),
          ),
        ],
      ),
    );

    // Save file
    final directory = await getExternalStorageDirectory();
    final fileName = 'voters_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File('${directory!.path}/$fileName');
    await file.writeAsBytes(await pdf.save());
    await OpenFile.open(file.path);
  }

  Future<void> exportToExcelWithFields(
    BuildContext context,
    Map<String, String> fieldMapping,
    List<String> selectedKeys, {
    int? startIndex,
    int? endIndex,
    String? filename,
  }) async {
    // Show progress indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final db = await DatabaseHelper.instance.database;

      // Create the view with selected columns, using table aliases to avoid ambiguity
      final columnMappings = {
        'voter_no': 'v.voter_no',
        'name': 'v.name_np',
        'name_en': 'vd.name_en',
        'age': 'v.age',
        'gender': 'v.gender',
        'parents_name': 'v.parent_name_np',
        'spouse_name_np': 'v.spouse_name_np',
        'province': 'p.name',
        'district_name': 'd.name',
        'municipality_name': 'm.name',
        'ward_no': 'w.ward_no',
        'booth_name': 'eb.booth_name',
        'main_category': 'COALESCE(c.Mname, \'Unrecognized\')',
        'sub_category': 'c.Sname',
        'tags':
            '(SELECT GROUP_CONCAT(t.name, \', \') FROM voter_tag vt INNER JOIN tags t ON vt.tag_id = t.id WHERE vt.voterdetail_id = vd.id)',
        'phone_no': 'vd.phone',
        'description': 'vd.description',
      };

      final columns = selectedKeys
          .map((key) => '${columnMappings[key]} AS $key')
          .join(', ');
      await db.execute('DROP VIEW IF EXISTS voter_export_view;');
      await db.execute('''
        CREATE VIEW voter_export_view AS
        SELECT $columns
        FROM voter v
        LEFT JOIN election_booth eb ON v.booth_id = eb.id
        LEFT JOIN ward w ON eb.ward_id = w.id
        LEFT JOIN municipality m ON w.municipality_id = m.id
        LEFT JOIN district d ON m.district_id = d.id
        LEFT JOIN province p ON d.province_id = p.id
        LEFT JOIN categorized c ON v.voter_no = c.voter_no
        LEFT JOIN (SELECT * FROM voterdetails GROUP BY voterid) vd ON v.id = vd.voterid;
      ''');

      // Query rows from the view with limit and offset
      String query = 'SELECT * FROM voter_export_view';
      if (startIndex != null) {
        final offset = startIndex - 1;
        if (endIndex != null) {
          final limit = endIndex - startIndex + 1;
          query += ' LIMIT $limit OFFSET $offset';
        } else {
          query += ' LIMIT -1 OFFSET $offset'; // No limit, just offset
        }
      }
      final rows = await db.rawQuery(query);

      if (rows.isEmpty) {
        Navigator.of(context).pop(); // Close progress dialog
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('No data to export')));
        return;
      }

      // Create Excel workbook
      final excel = Excel.createExcel();
      final sheet = excel['Voters'];

      // Add headers using display names
      final headers = selectedKeys
          .map((key) => TextCellValue(fieldMapping[key]!))
          .toList();
      sheet.appendRow(headers);

      // Add data rows
      for (final row in rows) {
        final rowData = row.values
            .map((value) => TextCellValue(value?.toString() ?? ''))
            .toList();
        sheet.appendRow(rowData);
      }

      // Save to Downloads or Documents folder
      Directory? directory;
      if (Platform.isAndroid) {
        directory = await getExternalStorageDirectory();
        if (directory != null) {
          directory = Directory('${directory.path}/Download');
          if (!await directory.exists()) {
            directory = await getExternalStorageDirectory();
          }
        }
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory == null) {
        throw Exception('Could not access storage directory');
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'voter_export_$timestamp.xlsx';
      final file = File('${directory.path}/$fileName');

      await file.writeAsBytes(excel.encode()!);

      // Close progress dialog
      Navigator.of(context).pop();

      // Show success SnackBar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Exported ${rows.length} records to $fileName'),
          action: SnackBarAction(
            label: 'Open',
            onPressed: () => OpenFile.open(file.path),
          ),
        ),
      );
    } catch (e) {
      // Close progress dialog
      Navigator.of(context).pop();

      // Show error SnackBar
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
    }
  }
}
