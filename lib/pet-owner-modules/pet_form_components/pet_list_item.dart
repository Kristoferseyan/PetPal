import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:printing/printing.dart';
import 'package:flutter/services.dart' show Uint8List, rootBundle;
import 'package:flutter/material.dart';
import 'package:petpal/services/medical_service.dart';
import 'package:petpal/utils/colors.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:convert';

class PetListItem extends StatelessWidget {
  final Map<String, dynamic> pet;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final String ageDisplay;

  const PetListItem({
    Key? key,
    required this.pet,
    required this.isSelected,
    required this.onTap,
    required this.onDelete,
    required this.ageDisplay,
  }) : super(key: key);

  String _generateQrData([Map<String, dynamic>? enhancedPet]) {
    final petData = enhancedPet ?? pet;

    final Map<String, dynamic> qrData = {
      'name': petData['name'] ?? 'Unknown',
      'species': petData['species'] ?? 'Unknown',
      'breed': petData['breed'] ?? 'Unknown',
      'age': ageDisplay,
      'gender': petData['gender'] ?? 'Unknown',
      'weight': petData['weight']?.toString() ?? 'Unknown',
      'birthdate': petData['birthdate'] ?? '',
      'owner_id': petData['owner_id'] ?? '',
      'id': petData['id'] ?? '',
      'medical_record_image': petData['medical_record_image'] ?? '',

      'allergies': petData['allergies'] ?? '',
      'markings': petData['markings'] ?? '',
      'is_neutered': petData['is_neutered'] ?? false,
      'has_medical_records': petData['has_medical_records'] ?? false,
      'medical_records_count': petData['medical_records_count'] ?? 0,
      'owner_uploaded_medical_record':
          petData['owner_uploaded_medical_record'] ?? '',
    };

    return jsonEncode(qrData);
  }

  void _showQrCode(BuildContext context) async {
    final medicalService = MedicalService();
    String medicalRecordImageUrl = '';
    List<Map<String, dynamic>> petMedicalRecordSummary = [];

    try {
      final medicalRecords = await medicalService.getCompleteMedicalHistory(
        pet['id'],
      );

      if (medicalRecords.isNotEmpty) {
        medicalRecordImageUrl = medicalRecords.first['image_url'] ?? '';

        petMedicalRecordSummary =
            medicalRecords.map((record) {
              return {
                'date': record['created_at'],
                'diagnosis': record['diagnosis'],
                'source': record['source'],
                'has_image':
                    record['image_url'] != null &&
                    record['image_url'].toString().isNotEmpty,
              };
            }).toList();
      }
    } catch (e) {}

    String ownerUploadedMedicalRecord = '';
    try {
      final petDetailsResponse =
          await medicalService.supabase
              .from('pet_details')
              .select('medical_record_url')
              .eq('pet_id', pet['id'])
              .single();

      if (petDetailsResponse != null &&
          petDetailsResponse['medical_record_url'] != null) {
        ownerUploadedMedicalRecord = petDetailsResponse['medical_record_url'];
      }
    } catch (e) {}

    final petDetails = pet['pet_details'] as Map<String, dynamic>?;

    final updatedPet = {
      ...pet,
      'medical_record_image': medicalRecordImageUrl,
      'owner_uploaded_medical_record': ownerUploadedMedicalRecord,
      'has_medical_records': petMedicalRecordSummary.isNotEmpty,
      'medical_records_count': petMedicalRecordSummary.length,

      'allergies': petDetails?['allergies'] ?? pet['allergies'] ?? '',
      'markings': petDetails?['markings'] ?? pet['markings'] ?? '',
      'is_neutered': petDetails?['is_neutered'] ?? pet['isNeutered'] ?? false,
    };

    final qrData = _generateQrData(updatedPet);
    final petName = pet['name'] ?? 'Unknown';

    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            backgroundColor: const Color.fromARGB(255, 37, 45, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "$petName's QR Code",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Scan to view complete pet details",
                    style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: QrImageView(
                      data: qrData,
                      version: QrVersions.auto,
                      size: 200.0,
                      backgroundColor: Colors.white,
                      embeddedImage: const AssetImage(
                        'assets/images/logo_small.png',
                      ),
                      embeddedImageStyle: QrEmbeddedImageStyle(
                        size: const Size(40, 40),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed:
                            () => _generateAndDownloadPdf(context, updatedPet),
                        icon: const Icon(Icons.picture_as_pdf),
                        label: const Text("Export PDF"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                        label: const Text("Close"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final petName = pet['name'] ?? 'Unknown';
    final species = pet['species'] ?? 'Unknown';
    final breed = pet['breed'] ?? 'Unknown';
    final imageUrl = pet['image_url'];

    return GestureDetector(
      onTap: onTap,
      child: Container(
        color:
            isSelected
                ? AppColors.primary.withOpacity(0.1)
                : Colors.transparent,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: Colors.white10,
              backgroundImage:
                  imageUrl != null && imageUrl.toString().isNotEmpty
                      ? NetworkImage(imageUrl)
                      : null,
              child:
                  imageUrl == null || imageUrl.toString().isEmpty
                      ? Icon(
                        Icons.pets,
                        color: Colors.white.withOpacity(0.7),
                        size: 26,
                      )
                      : null,
            ),
            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    petName,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w500,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "$species • $breed",
                    style: TextStyle(color: Colors.grey[400], fontSize: 13),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    ageDisplay,
                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                  ),
                ],
              ),
            ),

            IconButton(
              onPressed: () => _showQrCode(context),
              icon: const Icon(
                Icons.qr_code,
                color: AppColors.accent,
                size: 20,
              ),
              tooltip: 'Show QR Code',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),

            IconButton(
              onPressed: onDelete,
              icon: Icon(
                Icons.delete_outline,
                color: Colors.red[300],
                size: 20,
              ),
              tooltip: 'Delete pet',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),

            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: AppColors.primary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _generateAndDownloadPdf(
    BuildContext context, [
    Map<String, dynamic>? enhancedPet,
  ]) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        },
      );

      final petData = enhancedPet ?? pet;
      final petDetails = petData['pet_details'] as Map<String, dynamic>?;

      final pdf = pw.Document();

      pw.MemoryImage? logoImage;
      try {
        final ByteData logoByteData = await rootBundle.load(
          'assets/images/logo.png',
        );
        final Uint8List logoBytes = logoByteData.buffer.asUint8List();
        logoImage = pw.MemoryImage(logoBytes);
      } catch (e) {}

      pw.MemoryImage? petImage;
      if (petData['image_url'] != null &&
          petData['image_url'].toString().isNotEmpty) {
        try {
          final imageBytes = await networkImageToByte(petData['image_url']);
          if (imageBytes != null) {
            petImage = pw.MemoryImage(imageBytes);
          }
        } catch (e) {}
      }

      pw.MemoryImage? medicalRecordImage;
      if (petData['owner_uploaded_medical_record'] != null &&
          petData['owner_uploaded_medical_record'].toString().isNotEmpty) {
        try {
          final imageBytes = await networkImageToByte(
            petData['owner_uploaded_medical_record'],
          );
          if (imageBytes != null) {
            medicalRecordImage = pw.MemoryImage(imageBytes);
          }
        } catch (e) {}
      } else if (petData['medical_record_image'] != null &&
          petData['medical_record_image'].toString().isNotEmpty) {
        try {
          final imageBytes = await networkImageToByte(
            petData['medical_record_image'],
          );
          if (imageBytes != null) {
            medicalRecordImage = pw.MemoryImage(imageBytes);
          }
        } catch (e) {}
      }

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          header: (pw.Context context) {
            return pw.Container(
              alignment: pw.Alignment.center,
              margin: const pw.EdgeInsets.only(bottom: 20),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  if (logoImage != null)
                    pw.Image(logoImage, width: 60)
                  else
                    pw.Container(width: 60),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Pet Health Information',
                        style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'Generated: ${DateTime.now().toString().split('.')[0]}',
                        style: const pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
          footer: (pw.Context context) {
            return pw.Container(
              alignment: pw.Alignment.centerRight,
              margin: const pw.EdgeInsets.only(top: 20),
              child: pw.Text(
                'Page ${context.pageNumber} of ${context.pagesCount}',
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey700,
                ),
              ),
            );
          },
          build:
              (pw.Context context) => [
                pw.Container(
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.blueGrey50,
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      if (petImage != null)
                        pw.Container(
                          width: 100,
                          height: 100,
                          decoration: pw.BoxDecoration(
                            shape: pw.BoxShape.circle,
                            image: pw.DecorationImage(
                              image: petImage,
                              fit: pw.BoxFit.cover,
                            ),
                          ),
                        ),
                      pw.SizedBox(width: 16),
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              petData['name'] ?? 'Unknown',
                              style: pw.TextStyle(
                                fontSize: 24,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.SizedBox(height: 4),
                            pw.Text(
                              '${petData['species'] ?? 'Unknown'} • ${petData['breed'] ?? 'Unknown'}',
                              style: const pw.TextStyle(fontSize: 16),
                            ),
                            pw.SizedBox(height: 2),
                            pw.Text(
                              ageDisplay,
                              style: const pw.TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),

                pw.Text(
                  'Pet Details',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Divider(),
                pw.SizedBox(height: 10),

                _buildPdfInfoTable([
                  {'label': 'Gender', 'value': petData['gender'] ?? 'Unknown'},
                  {
                    'label': 'Weight',
                    'value': '${petData['weight'] ?? 'Unknown'} kg',
                  },
                  {
                    'label': 'Birthdate',
                    'value': petData['birthdate'] ?? 'Unknown',
                  },
                  {
                    'label': 'Neutered/Spayed',
                    'value': petData['is_neutered'] == true ? 'Yes' : 'No',
                  },
                  if (petData['allergies'] != null &&
                      petData['allergies'].toString().isNotEmpty)
                    {'label': 'Allergies', 'value': petData['allergies']},
                  if (petData['markings'] != null &&
                      petData['markings'].toString().isNotEmpty)
                    {'label': 'Markings', 'value': petData['markings']},
                ]),

                pw.SizedBox(height: 20),

                if (petData['has_medical_records'] == true ||
                    medicalRecordImage != null) ...[
                  pw.Text(
                    'Medical Information',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Divider(),
                  pw.SizedBox(height: 10),

                  if (petData['medical_records_count'] != null &&
                      petData['medical_records_count'] > 0)
                    pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 10),
                      child: pw.Container(
                        padding: const pw.EdgeInsets.all(8),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.blue50,
                          borderRadius: pw.BorderRadius.circular(4),
                          border: pw.Border.all(color: PdfColors.blue200),
                        ),
                        child: pw.Text(
                          'This pet has ${petData['medical_records_count']} medical records in the PetPal system',
                          style: const pw.TextStyle(
                            fontSize: 12,
                            color: PdfColors.blue700,
                          ),
                        ),
                      ),
                    ),

                  if (medicalRecordImage != null) ...[
                    pw.Text(
                      'Latest Medical Record',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.ClipRRect(
                      verticalRadius: 8,
                      horizontalRadius: 8,
                      child: pw.Image(
                        medicalRecordImage,
                        height: 180,
                        fit: pw.BoxFit.contain,
                      ),
                    ),
                    pw.SizedBox(height: 5),
                    pw.Center(
                      child: pw.Text(
                        'For complete medical history, please access the PetPal app',
                        style: pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey700,
                          fontStyle: pw.FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ],
              ],
        ),
      );

      final appDocDir = await getApplicationDocumentsDirectory();
      final pdfPath = '${appDocDir.path}/${petData['name']}_info.pdf';
      final file = File(pdfPath);
      await file.writeAsBytes(await pdf.save());

      Navigator.of(context).pop();

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: const Color.fromARGB(255, 37, 45, 50),
            title: const Text(
              'PDF Created',
              style: TextStyle(color: Colors.white),
            ),
            content: const Text(
              'Your pet\'s information has been saved as a PDF file.',
              style: TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'Close',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await OpenFile.open(pdfPath);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('View PDF'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await Printing.sharePdf(
                    bytes: await pdf.save(),
                    filename: '${petData['name']}_info.pdf',
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Share'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error creating PDF: $e')));
    }
  }

  pw.Widget _buildPdfInfoTable(List<Map<String, String>> data) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      children:
          data.map((item) {
            return pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.white),
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text(
                    item['label']!,
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text(item['value']!),
                ),
              ],
            );
          }).toList(),
    );
  }

  Future<Uint8List?> networkImageToByte(String imageUrl) async {
    try {
      final response = await http.get(Uri.parse(imageUrl));

      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }
}
