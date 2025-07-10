import 'package:flutter/material.dart';
import 'package:petpal/services/medication_service.dart';
import 'package:petpal/utils/colors.dart';
import 'package:intl/intl.dart';
import 'package:petpal/vet-modules/widgets/text_field_with_unit.dart';

class AddMedicationForm extends StatefulWidget {
  final String petId;
  final Function(bool) onMedicationAdded;

  const AddMedicationForm({
    super.key,
    required this.petId,
    required this.onMedicationAdded,
  });

  @override
  State<AddMedicationForm> createState() => _AddMedicationFormState();
}

class _AddMedicationFormState extends State<AddMedicationForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();
  final _frequencyController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;

  final MedicationService _medicationService = MedicationService();
  bool _isLoading = false;

  String _dosageUnit = 'mg';
  String _frequencyUnit = 'daily';

  final List<String> _dosageUnits = [
    'mg',
    'ml',
    'g',
    'mcg',
    'IU',
    'tablet(s)',
    'capsule(s)',
    'drops',
  ];
  final List<String> _frequencyUnits = [
    'daily',
    'every 8h',
    'every 12h',
    'weekly',
    'as needed',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _frequencyController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          isStartDate ? (DateTime.now()) : (_startDate ?? DateTime.now()),
      firstDate: isStartDate ? DateTime(2000) : (_startDate ?? DateTime.now()),
      lastDate: DateTime(2101),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Color.fromARGB(255, 50, 60, 65),
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: const Color.fromARGB(255, 37, 45, 50),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          if (_endDate != null && _endDate!.isBefore(_startDate!)) {
            _endDate = null;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return "Not Set";
    return DateFormat('MMM d, yyyy').format(date);
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState?.validate() ?? false) {
      if (_startDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Please select a start date"),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        await _medicationService.addMedication(
          petId: widget.petId,
          name: _nameController.text,
          dosage: '${_dosageController.text} $_dosageUnit',
          frequency: '${_frequencyController.text} $_frequencyUnit',
          startDate: _startDate!,
          endDate: _endDate,
          notes: _notesController.text.isEmpty ? null : _notesController.text,
        );

        widget.onMedicationAdded(true);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Failed to add medication: ${e.toString()}"),
              backgroundColor: Colors.red,
            ),
          );

          widget.onMedicationAdded(false);
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Medication Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.medication),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter medication name';
                }
                return null;
              },
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),
            TextFieldWithUnitDropdown(
              controller: _dosageController,
              label: "Dosage",
              hintText: "Enter dosage amount",
              isRequired: true,
              units: _dosageUnits,
              initialUnit: _dosageUnit,
              onUnitChanged: (unit) {
                setState(() {
                  _dosageUnit = unit;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter the dosage';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFieldWithUnitDropdown(
              controller: _frequencyController,
              label: "Frequency",
              hintText: "Enter administration frequency",
              isRequired: true,
              units: _frequencyUnits,
              initialUnit: _frequencyUnit,
              onUnitChanged: (unit) {
                setState(() {
                  _frequencyUnit = unit;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter the frequency';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(
                vertical: 4.0,
                horizontal: 16.0,
              ),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(4.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Treatment Duration',
                    style: TextStyle(color: Colors.grey, fontSize: 12.0),
                  ),
                  const SizedBox(height: 8.0),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, color: Colors.grey),
                      const SizedBox(width: 16.0),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Start Date',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14.0,
                              ),
                            ),
                            const SizedBox(height: 4.0),
                            GestureDetector(
                              onTap: () => _selectDate(context, true),
                              child: Text(
                                _startDate != null
                                    ? _formatDate(_startDate)
                                    : 'Select Start Date',
                                style: TextStyle(
                                  color:
                                      _startDate != null
                                          ? Colors.white
                                          : Colors.grey,
                                  fontSize: 16.0,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16.0),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'End Date (Optional)',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14.0,
                              ),
                            ),
                            const SizedBox(height: 4.0),
                            GestureDetector(
                              onTap:
                                  _startDate != null
                                      ? () => _selectDate(context, false)
                                      : null,
                              child: Text(
                                _endDate != null
                                    ? _formatDate(_endDate)
                                    : _startDate != null
                                    ? 'Select End Date'
                                    : 'Set start date first',
                                style: TextStyle(
                                  color:
                                      _endDate != null
                                          ? Colors.white
                                          : Colors.grey,
                                  fontSize: 16.0,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (Optional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.notes),
                hintText: 'Additional information',
              ),
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              onPressed: _isLoading ? null : _submitForm,
              child:
                  _isLoading
                      ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                          strokeWidth: 2,
                        ),
                      )
                      : const Text(
                        'Add Medication',
                        style: TextStyle(fontSize: 16.0, color: Colors.white),
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
