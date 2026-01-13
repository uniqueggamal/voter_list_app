import 'dart:io';
import 'package:excel/excel.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import '../models/voter.dart';

class ExportService {
  Future<void> exportToExcel(
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
}
