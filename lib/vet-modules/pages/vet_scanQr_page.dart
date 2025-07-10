import 'package:flutter/material.dart';
import 'package:petpal/services/appointment_service.dart';
import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';
import 'package:petpal/utils/colors.dart';
import 'dart:convert';

class VetScanQRPage extends StatefulWidget {
  final bool appointmentMode;

  const VetScanQRPage({Key? key, this.appointmentMode = false})
    : super(key: key);

  @override
  State<VetScanQRPage> createState() => _VetScanQRPageState();
}

class _VetScanQRPageState extends State<VetScanQRPage> {
  String? _scanResult;
  bool _isLoading = false;
  Map<String, dynamic>? _petData;
  Map<String, dynamic>? _appointmentData;
  String? _errorMessage;
  bool _currentMode = false;

  @override
  void initState() {
    super.initState();
    _currentMode = widget.appointmentMode;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 37, 45, 50),
      appBar: AppBar(
        title: Text(
          "PetPal Scanner",
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color.fromARGB(255, 44, 59, 70),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body:
          _isLoading
              ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: AppColors.primary),
                    SizedBox(height: 16),
                    Text(
                      "Processing QR code...",
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              )
              : _currentMode
              ? (_appointmentData != null
                  ? _buildAppointmentDetails()
                  : _buildScannerUI())
              : (_petData != null ? _buildPetDetails() : _buildScannerUI()),
    );
  }

  Widget _buildScannerUI() {
    final String scanType = _currentMode ? "Appointment" : "Pet";

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.qr_code_scanner, size: 80, color: AppColors.primary),
          const SizedBox(height: 24),

          Text(
            "Scan QR Code",
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),

          Text(
            "Position the QR code in the scanner area",
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, color: Colors.white70),
          ),

          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildModeToggleButton(
                icon: Icons.pets,
                label: "Pet Scan",
                isActive: !_currentMode,
                onPressed: () => setState(() => _currentMode = false),
              ),
              const SizedBox(width: 16),
              _buildModeToggleButton(
                icon: Icons.event_available,
                label: "Appointment",
                isActive: _currentMode,
                onPressed: () => setState(() => _currentMode = true),
              ),
            ],
          ),

          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade900.withOpacity(0.6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Colors.white),
              ),
            ),
          ],

          const SizedBox(height: 40),
          ElevatedButton.icon(
            onPressed: _scanQRCode,
            icon: const Icon(Icons.camera_alt),
            label: Text("Scan QR Code"),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeToggleButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onPressed,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 140,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color:
            isActive
                ? AppColors.primary.withOpacity(0.15)
                : Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? AppColors.primary : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            Icon(
              icon,
              color: isActive ? AppColors.primary : Colors.grey,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: isActive ? AppColors.primary : Colors.grey,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentDetails() {
    if (_appointmentData == null) return const SizedBox.shrink();

    String formattedTime = _formatTimeWithAMPM(_appointmentData!['time']);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: Colors.green, width: 2),
              ),
              child: const Icon(
                Icons.check_circle_outline,
                size: 80,
                color: Colors.green,
              ),
            ),
          ),
          const SizedBox(height: 24),

          Center(
            child: Column(
              children: [
                const Text(
                  "Approved Appointment",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    "${_appointmentData!['date']} · $formattedTime",
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          Card(
            color: const Color.fromARGB(255, 31, 38, 42),
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildAppointmentDetailRow(
                    "Pet Name",
                    _appointmentData!['petName'] ?? 'Unknown',
                  ),
                  const Divider(color: Colors.white24),
                  _buildAppointmentDetailRow(
                    "Appointment Type",
                    _getFormattedAppointmentType(_appointmentData!),
                  ),
                  const Divider(color: Colors.white24),
                  _buildAppointmentDetailRow(
                    "Owner",
                    _appointmentData!['ownerName'] ?? 'Unknown',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    setState(() => _isLoading = true);

                    try {
                      final appointmentId = _appointmentData!['id'];

                      await AppointmentService().updateAppointmentStatus(
                        appointmentId,
                        'on-going',
                      );

                      setState(() => _isLoading = false);

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Appointment check-in successful! Session started.',
                          ),
                          backgroundColor: Colors.green,
                        ),
                      );

                      Navigator.of(context).pushNamedAndRemoveUntil(
                        '/appointments',
                        (Route<dynamic> route) => false,
                        arguments: {'appointmentUpdated': true},
                      );

                      return;
                    } catch (e) {
                      setState(() {
                        _isLoading = false;
                        _errorMessage = "Failed to update appointment: $e";
                      });
                    }
                  },
                  icon: const Icon(Icons.play_circle_outline),
                  label: const Text("Start Appointment Session"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Center(
            child: TextButton.icon(
              onPressed: _resetAndScanAgain,
              icon: const Icon(Icons.refresh),
              label: const Text("Scan Again"),
              style: TextButton.styleFrom(foregroundColor: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentDetailRow(
    String label,
    String value, {
    bool isId = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 16, color: Colors.grey[400])),
          SizedBox(
            width: 200,
            child: Text(
              value,
              textAlign: TextAlign.end,
              overflow: isId ? TextOverflow.ellipsis : TextOverflow.visible,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: isId ? 'monospace' : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimeWithAMPM(String? timeString) {
    if (timeString == null || timeString.isEmpty) {
      return 'N/A';
    }

    try {
      final parts = timeString.split(':');
      if (parts.length < 2) return timeString;

      int hour = int.parse(parts[0]);
      final minute = parts[1].padLeft(2, '0');
      final period = hour >= 12 ? 'PM' : 'AM';

      hour = hour > 12 ? hour - 12 : hour;
      hour = hour == 0 ? 12 : hour;

      return '$hour:$minute $period';
    } catch (e) {
      return timeString;
    }
  }

  Widget _buildPetDetails() {
    if (_petData == null) return const SizedBox.shrink();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child:
                  _petData!['image_url'] != null &&
                          _petData!['image_url'].toString().isNotEmpty
                      ? Image.network(
                        _petData!['image_url'],
                        height: 200,
                        width: 200,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 200,
                            width: 200,
                            color: Colors.grey.shade800,
                            child: const Icon(
                              Icons.pets,
                              size: 80,
                              color: Colors.white54,
                            ),
                          );
                        },
                      )
                      : Container(
                        height: 200,
                        width: 200,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade800,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.pets,
                          size: 80,
                          color: Colors.white54,
                        ),
                      ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _petData!['name'] ?? 'Unnamed Pet',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          _buildInfoCard(),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context, _petData);
                  },
                  icon: const Icon(Icons.pets),
                  label: const Text("Use This Pet Data"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Center(
            child: TextButton.icon(
              onPressed: _resetAndScanAgain,
              icon: const Icon(Icons.refresh),
              label: const Text("Scan Again"),
              style: TextButton.styleFrom(foregroundColor: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      color: const Color.fromARGB(255, 31, 35, 35),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildDetailRow("Species", _petData!['species'] ?? 'Unknown'),
            const Divider(color: Colors.white24),
            _buildDetailRow("Breed", _petData!['breed'] ?? 'Unknown'),
            const Divider(color: Colors.white24),
            _buildDetailRow("Age", "${_petData!['age'] ?? 'Unknown'} years"),
            const Divider(color: Colors.white24),
            _buildDetailRow("Gender", _petData!['gender'] ?? 'Unknown'),
            const Divider(color: Colors.white24),
            _buildDetailRow("Weight", "${_petData!['weight'] ?? 'Unknown'} kg"),
            const Divider(color: Colors.white24),
            _buildDetailRow(
              "Neutered/Spayed",
              _petData!['is_neutered'] == true ? 'Yes' : 'No',
            ),
            if (_petData!['allergies'] != null &&
                _petData!['allergies'].toString().isNotEmpty) ...[
              const Divider(color: Colors.white24),
              _buildDetailRow("Allergies", _petData!['allergies']),
            ],
            if (_petData!['markings'] != null &&
                _petData!['markings'].toString().isNotEmpty) ...[
              const Divider(color: Colors.white24),
              _buildDetailRow("Markings", _petData!['markings']),
            ],
            if (_petData!['medical_record_image'] != null &&
                _petData!['medical_record_image'].toString().isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                "Recent Veterinary Record",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  _petData!['medical_record_image'],
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 150,
                      width: double.infinity,
                      color: Colors.grey.shade800,
                      child: const Icon(
                        Icons.medical_services,
                        size: 50,
                        color: Colors.white54,
                      ),
                    );
                  },
                ),
              ),
            ],
            if (_petData!['owner_uploaded_medical_record'] != null &&
                _petData!['owner_uploaded_medical_record']
                    .toString()
                    .isNotEmpty) ...[
              const SizedBox(height: 24),
              const Text(
                "Owner-Provided Medical Document",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber,
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap:
                    () => _viewFullImage(
                      _petData!['owner_uploaded_medical_record'],
                    ),
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        _petData!['owner_uploaded_medical_record'],
                        height: 150,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 150,
                            width: double.infinity,
                            color: Colors.grey.shade800,
                            child: const Icon(
                              Icons.upload_file,
                              size: 50,
                              color: Colors.amber,
                            ),
                          );
                        },
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.all(8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.zoom_in,
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (_petData!['medical_records_count'] != null &&
                _petData!['medical_records_count'] > 0) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.medical_services,
                      size: 16,
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Pet has ${_petData!['medical_records_count']} medical records",
                      style: const TextStyle(color: Colors.blue),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isId = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 16, color: Colors.grey[400])),
          SizedBox(
            width: 200,
            child: Text(
              value,
              textAlign: TextAlign.end,
              overflow: isId ? TextOverflow.ellipsis : TextOverflow.visible,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isId ? Colors.grey[400] : Colors.white,
                fontFamily: isId ? 'monospace' : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _parseAppointmentType(String detailsJson) {
    try {
      final Map<String, dynamic> details = jsonDecode(detailsJson);
      return details['appointment_type'] ??
          details['operation_type'] ??
          'Check-up';
    } catch (e) {
      return 'Check-up';
    }
  }

  String _getFormattedAppointmentType(Map<String, dynamic> appointmentData) {
    if (appointmentData['type'] != null) {
      String type = appointmentData['type'];

      if (type == 'Operation' && appointmentData['operation_type'] != null) {
        return 'Operation: ${appointmentData['operation_type']}';
      }
      return type;
    }

    if (appointmentData['details'] != null &&
        appointmentData['details'] is String) {
      return _parseAppointmentType(appointmentData['details']);
    }

    return 'Check-up';
  }

  Future<void> _scanQRCode() async {
    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    try {
      String? result = await SimpleBarcodeScanner.scanBarcode(context);

      setState(() {
        _scanResult = result;
        _isLoading = false;
      });

      if (result != "-1") {
        _processScanResult(result!);
      } else {
        setState(() {
          _errorMessage = null;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = "Error scanning: ${e.toString()}";
      });
    }
  }

  void _resetAndScanAgain() {
    setState(() {
      _petData = null;
      _appointmentData = null;
      _scanResult = null;
      _errorMessage = null;
    });

    _scanQRCode();
  }

  void _processScanResult(String result) {
    try {
      Map<String, dynamic> parsedData = jsonDecode(result);

      if (parsedData.containsKey('date') && parsedData.containsKey('time')) {
        if (_currentMode) {
          setState(() {
            _appointmentData = parsedData;
            _errorMessage = null;
          });
        } else {
          setState(() {
            _appointmentData = null;
            _errorMessage =
                "This is a pet QR code. Please scan an appointment QR code.";
          });
        }
      } else {
        if (!_currentMode) {
          if (parsedData.containsKey('is_neutered')) {
            parsedData['is_neutered'] =
                parsedData['is_neutered'] == true ||
                parsedData['is_neutered'] == "true";
          }

          if (parsedData.containsKey('has_medical_records')) {
            parsedData['has_medical_records'] =
                parsedData['has_medical_records'] == true ||
                parsedData['has_medical_records'] == "true";
          }

          if (parsedData.containsKey('medical_records_count') &&
              parsedData['medical_records_count'] is String) {
            parsedData['medical_records_count'] =
                int.tryParse(parsedData['medical_records_count']) ?? 0;
          }

          setState(() {
            _petData = parsedData;
            _errorMessage = null;
          });
        } else {}
      }
    } catch (e) {
      try {
        List<String> lines = result.split('\n');
        Map<String, dynamic> extractedData = {};

        for (String line in lines) {
          if (line.contains(':')) {
            List<String> parts = line.split(':');
            if (parts.length >= 2) {
              String key = parts[0].trim().toLowerCase();
              String value = parts[1].trim();

              switch (key) {
                case 'name':
                case 'pet':
                case 'pet name':
                  extractedData['name'] = value;
                  break;
                case 'species':
                  extractedData['species'] = value;
                  break;
                case 'breed':
                  extractedData['breed'] = value;
                  break;
                case 'gender':
                  extractedData['gender'] = value;
                  break;
                case 'age':
                  extractedData['age'] = int.tryParse(
                    value.replaceAll(RegExp(r'[^0-9]'), ''),
                  );
                  break;
                case 'weight':
                  extractedData['weight'] = double.tryParse(
                    value.replaceAll(RegExp(r'[^0-9.]'), ''),
                  );
                  break;
                case 'id':
                case 'pet id':
                  extractedData['id'] = value;
                  break;
                case 'image':
                case 'image_url':
                case 'photo':
                  extractedData['image_url'] = value;
                  break;
                case 'medical_record_image':
                  extractedData['medical_record_image'] = value;
                  break;
              }
            }
          }
        }

        if (extractedData.isNotEmpty) {
          setState(() {
            _petData = extractedData;
          });
        } else {
          setState(() {
            _errorMessage = "Could not parse pet data from QR code";
          });
        }
      } catch (e) {
        setState(() {
          _errorMessage = "Invalid QR code format: ${e.toString()}";
        });
      }
    }
  }

  void _viewFullImage(String imageUrl) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) => Scaffold(
              backgroundColor: Colors.black,
              appBar: AppBar(
                backgroundColor: Colors.black,
                iconTheme: const IconThemeData(color: Colors.white),
                title: const Text(
                  'Medical Record',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              body: Center(
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value:
                              loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                          color: Colors.white,
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.broken_image,
                            color: Colors.grey[600],
                            size: 60,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Failed to load image',
                            style: TextStyle(color: Colors.grey[500]),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Go Back'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
      ),
    );
  }
}
