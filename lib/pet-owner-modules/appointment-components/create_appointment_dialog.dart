import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:petpal/services/appointment_service.dart';
import 'package:petpal/services/pet_service.dart';
import 'package:petpal/utils/colors.dart';
import 'package:petpal/services/auth_service.dart';
import 'package:petpal/vet-modules/pages/vet_set_appointment_page.dart';

class CreateAppointmentDialog extends StatefulWidget {
  final String ownerId;
  final VoidCallback onAppointmentCreated;

  const CreateAppointmentDialog({
    Key? key,
    required this.ownerId,
    required this.onAppointmentCreated,
  }) : super(key: key);

  @override
  _CreateAppointmentDialogState createState() =>
      _CreateAppointmentDialogState();
}

class _CreateAppointmentDialogState extends State<CreateAppointmentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _purposeController = TextEditingController();
  final _operationDetailsController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  String? _selectedPetId;
  String? _selectedTimeSlotId;

  List<Map<String, dynamic>> _pets = [];
  List<TimeSlot> _availableTimeSlots = [];

  bool _isLoading = true;
  bool _isLoadingTimeSlots = false;

  final List<String> _appointmentTypes = [
    'Check-up',
    'Vaccination',
    'Operation',
    'Grooming',
    'Other',
  ];
  String _selectedAppointmentType = 'Check-up';

  final List<String> _operationTypes = [
    'Spay/Neuter',
    'Dental Procedure',
    'Mass Removal',
    'Orthopedic Surgery',
    'Other Surgery',
  ];
  String? _selectedOperationType;

  final PetService _petService = PetService();
  final AppointmentService _appointmentService = AppointmentService();
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final pets = await _petService.getPets(widget.ownerId);

      if (mounted) {
        setState(() {
          _pets = pets;
          _selectedPetId = _pets.isNotEmpty ? _pets[0]['id'] : null;
          _isLoading = false;
        });

        _loadTimeSlots();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadTimeSlots() async {
    setState(() {
      _isLoadingTimeSlots = true;
      _selectedTimeSlotId = null;
    });

    try {
      final allAvailableSlots = await _appointmentService
          .getAllAvailableTimeSlots(date: _selectedDate);

      final now = DateTime.now();
      final isToday =
          _selectedDate.year == now.year &&
          _selectedDate.month == now.month &&
          _selectedDate.day == now.day;

      final filteredSlots =
          isToday
              ? allAvailableSlots.where((slot) {
                final slotDateTime = DateTime(
                  _selectedDate.year,
                  _selectedDate.month,
                  _selectedDate.day,
                  slot.startTime.hour,
                  slot.startTime.minute,
                );

                return slotDateTime.isAfter(
                  now.add(const Duration(minutes: 15)),
                );
              }).toList()
              : allAvailableSlots;

      if (mounted) {
        setState(() {
          _availableTimeSlots = filteredSlots;
          _isLoadingTimeSlots = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _availableTimeSlots = [];
          _isLoadingTimeSlots = false;
        });
      }
    }
  }

  Future<void> _selectDate() async {
    final DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 180)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: const Color.fromARGB(255, 45, 55, 60),
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: const Color.fromARGB(255, 37, 45, 50),
          ),
          child: child!,
        );
      },
    );

    if (selectedDate != null && selectedDate != _selectedDate) {
      setState(() {
        _selectedDate = selectedDate;
      });

      _loadTimeSlots();
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final purpose = _purposeController.text;

      final Map<String, dynamic> appointmentDetails = {
        'appointment_type': _selectedAppointmentType,
      };

      if (_selectedAppointmentType == 'Operation' &&
          _selectedOperationType != null) {
        appointmentDetails['operation_type'] = _selectedOperationType;

        if (_operationDetailsController.text.isNotEmpty) {
          appointmentDetails['operation_details'] =
              _operationDetailsController.text;
        }
      }

      if (_selectedPetId != null && _selectedTimeSlotId != null) {
        try {
          await _appointmentService.bookAppointment(
            petId: _selectedPetId!,
            timeSlotId: _selectedTimeSlotId!,
            reason: purpose,
            details: appointmentDetails,
            context: context,
          );

          widget.onAppointmentCreated();

          Navigator.of(context).pop();
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to create appointment: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a pet and time slot'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMMM dd, yyyy').format(date);
  }

  String _formatTimeSlot(TimeSlot slot) {
    final startTime = TimeOfDay(
      hour: slot.startTime.hour,
      minute: slot.startTime.minute,
    );
    final endTime = TimeOfDay(
      hour: slot.endTime.hour,
      minute: slot.endTime.minute,
    );

    return '${startTime.format(context)} - ${endTime.format(context)}';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color.fromARGB(255, 37, 45, 50),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child:
          _isLoading
              ? const SizedBox(
                height: 200,
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              )
              : Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.85,
                  maxWidth: MediaQuery.of(context).size.width * 0.9,
                ),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Set New Appointment",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.close, color: Colors.white70),
                                onPressed: () => Navigator.of(context).pop(),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          DropdownButtonFormField<String>(
                            value: _selectedPetId,
                            items:
                                _pets.map((pet) {
                                  return DropdownMenuItem<String>(
                                    value: pet['id'],
                                    child: Text(
                                      pet['name'],
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  );
                                }).toList(),
                            onChanged: (String? value) {
                              setState(() {
                                _selectedPetId = value;
                              });
                            },
                            decoration: InputDecoration(
                              labelText: 'Pet Name',
                              labelStyle: TextStyle(color: AppColors.primary),
                              border: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: AppColors.primary,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value == null) {
                                return 'Please select a pet';
                              }
                              return null;
                            },
                            dropdownColor: const Color.fromARGB(
                              255,
                              31,
                              38,
                              42,
                            ),
                          ),

                          const SizedBox(height: 16),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  "Date: ${_formatDate(_selectedDate)}",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.calendar_today,
                                  color: AppColors.primary,
                                ),
                                onPressed: _selectDate,
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    size: 16,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Available Time Slots',
                                    style: TextStyle(
                                      color: Colors.grey[400],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              _isLoadingTimeSlots
                                  ? Center(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 20,
                                      ),
                                      child: CircularProgressIndicator(
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  )
                                  : _availableTimeSlots.isEmpty
                                  ? Container(
                                    width: double.infinity,
                                    padding: EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: const Color.fromARGB(
                                        255,
                                        31,
                                        38,
                                        42,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.grey.withOpacity(0.5),
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      'No available time slots for the selected date. Please select another date or veterinarian.',
                                      style: TextStyle(color: Colors.white70),
                                      textAlign: TextAlign.center,
                                    ),
                                  )
                                  : Container(
                                    height: 100,
                                    decoration: BoxDecoration(
                                      color: const Color.fromARGB(
                                        255,
                                        31,
                                        38,
                                        42,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: AppColors.primary.withOpacity(
                                          0.5,
                                        ),
                                        width: 1,
                                      ),
                                    ),
                                    child: ListView.builder(
                                      itemCount: _availableTimeSlots.length,
                                      padding: EdgeInsets.symmetric(
                                        vertical: 8,
                                      ),
                                      itemBuilder: (context, index) {
                                        final slot = _availableTimeSlots[index];
                                        final isSelected =
                                            _selectedTimeSlotId == slot.id;

                                        return InkWell(
                                          onTap: () {
                                            setState(() {
                                              _selectedTimeSlotId = slot.id;
                                            });
                                          },
                                          child: Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 12,
                                            ),
                                            margin: EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color:
                                                  isSelected
                                                      ? AppColors.primary
                                                          .withOpacity(0.2)
                                                      : Colors.transparent,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                color:
                                                    isSelected
                                                        ? AppColors.primary
                                                        : Colors.transparent,
                                                width: 1,
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.access_time,
                                                  color:
                                                      isSelected
                                                          ? AppColors.primary
                                                          : Colors.white70,
                                                  size: 18,
                                                ),
                                                SizedBox(width: 12),
                                                Text(
                                                  _formatTimeSlot(slot),
                                                  style: TextStyle(
                                                    color:
                                                        isSelected
                                                            ? AppColors.primary
                                                            : Colors.white,
                                                    fontWeight:
                                                        isSelected
                                                            ? FontWeight.bold
                                                            : FontWeight.normal,
                                                  ),
                                                ),
                                                Spacer(),
                                                if (isSelected)
                                                  Icon(
                                                    Icons.check_circle,
                                                    color: AppColors.primary,
                                                    size: 18,
                                                  ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.medical_services_outlined,
                                    size: 16,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Appointment Type',
                                    style: TextStyle(
                                      color: Colors.grey[400],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Container(
                                decoration: BoxDecoration(
                                  color: const Color.fromARGB(255, 31, 38, 42),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: AppColors.primary.withOpacity(0.5),
                                    width: 1,
                                  ),
                                ),
                                child: DropdownButtonFormField<String>(
                                  value: _selectedAppointmentType,
                                  isExpanded: true,
                                  dropdownColor: const Color.fromARGB(
                                    255,
                                    31,
                                    38,
                                    42,
                                  ),
                                  decoration: const InputDecoration(
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                    border: InputBorder.none,
                                  ),
                                  style: const TextStyle(color: Colors.white),
                                  items:
                                      _appointmentTypes.map((String type) {
                                        return DropdownMenuItem<String>(
                                          value: type,
                                          child: Text(type),
                                        );
                                      }).toList(),
                                  onChanged: (String? value) {
                                    setState(() {
                                      _selectedAppointmentType = value!;

                                      if (value != 'Operation') {
                                        _selectedOperationType = null;
                                      }
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),

                          if (_selectedAppointmentType == 'Operation') ...[
                            const SizedBox(height: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.local_hospital,
                                      size: 16,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Operation Type',
                                      style: TextStyle(
                                        color: Colors.grey[400],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  decoration: BoxDecoration(
                                    color: const Color.fromARGB(
                                      255,
                                      31,
                                      38,
                                      42,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: AppColors.primary.withOpacity(0.5),
                                      width: 1,
                                    ),
                                  ),
                                  child: DropdownButtonFormField<String>(
                                    value: _selectedOperationType,
                                    isExpanded: true,
                                    dropdownColor: const Color.fromARGB(
                                      255,
                                      31,
                                      38,
                                      42,
                                    ),
                                    decoration: const InputDecoration(
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 16,
                                      ),
                                      border: InputBorder.none,
                                    ),
                                    style: const TextStyle(color: Colors.white),
                                    items:
                                        _operationTypes.map((String type) {
                                          return DropdownMenuItem<String>(
                                            value: type,
                                            child: Text(type),
                                          );
                                        }).toList(),
                                    onChanged: (String? value) {
                                      setState(() {
                                        _selectedOperationType = value;
                                      });
                                    },
                                    validator: (value) {
                                      if (_selectedAppointmentType ==
                                              'Operation' &&
                                          value == null) {
                                        return 'Please select an operation type';
                                      }
                                      return null;
                                    },
                                  ),
                                ),

                                if (_selectedOperationType != null) ...[
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _operationDetailsController,
                                    decoration: InputDecoration(
                                      labelText: 'Operation Details',
                                      hintText: 'Enter any specific details',
                                      labelStyle: TextStyle(
                                        color: AppColors.primary,
                                      ),
                                      hintStyle: TextStyle(color: Colors.grey),
                                      border: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: AppColors.primary,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                    style: TextStyle(color: Colors.white),
                                    maxLines: 2,
                                  ),
                                ],
                              ],
                            ),
                          ],

                          const SizedBox(height: 16),

                          TextFormField(
                            controller: _purposeController,
                            decoration: InputDecoration(
                              labelText: 'Additional Notes (Optional)',
                              hintText: 'Enter any additional information',
                              labelStyle: TextStyle(color: AppColors.primary),
                              hintStyle: TextStyle(color: Colors.grey),
                              border: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: AppColors.primary,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            style: TextStyle(color: Colors.white),
                            maxLines: 2,
                          ),

                          const SizedBox(height: 24),

                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _submitForm,
                              child: const Text(
                                'Set Appointment',
                                style: TextStyle(fontSize: 16),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16.0,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
    );
  }
}
