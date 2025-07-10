import 'package:flutter/material.dart';
import 'package:petpal/utils/colors.dart';
import 'package:petpal/services/appointment_service.dart';
import 'package:petpal/services/auth_service.dart';
import 'package:intl/intl.dart';
import 'package:flutter/cupertino.dart';

class VetSetAppointmentPage extends StatefulWidget {
  const VetSetAppointmentPage({super.key});

  @override
  State<VetSetAppointmentPage> createState() => _VetSetAppointmentPageState();
}

class _VetSetAppointmentPageState extends State<VetSetAppointmentPage> {
  final AppointmentService _appointmentService = AppointmentService();
  final AuthService _authService = AuthService();

  String? _vetId;

  DateTime _selectedDate = DateTime.now();
  List<TimeSlot> _timeSlots = [];
  bool _isLoading = false;
  String? _errorMessage;

  final int _slotDuration = 30;

  final TextEditingController _startTimeController = TextEditingController();
  final TextEditingController _endTimeController = TextEditingController();
  final TextEditingController _maxAppointmentsController =
      TextEditingController(text: '1');

  @override
  void initState() {
    super.initState();
    _fetchVetId();
    _fetchTimeSlotsForDate();
  }

  @override
  void dispose() {
    _startTimeController.dispose();
    _endTimeController.dispose();
    _maxAppointmentsController.dispose();
    super.dispose();
  }

  Future<void> _fetchVetId() async {
    final user = await _authService.getCurrentUser();
    if (user != null) {
      setState(() {
        _vetId = user.id;
      });
      _fetchTimeSlotsForDate();
    }
  }

  Future<void> _fetchTimeSlotsForDate() async {
    if (_vetId == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final slots = await _appointmentService.getTimeSlotsByVetAndDate(
        vetId: _vetId!,
        date: _selectedDate,
      );

      setState(() {
        _timeSlots = slots;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = "Failed to load time slots: ${e.toString()}";
        _isLoading = false;
      });
    }
  }

  Future<void> _addTimeSlot() async {
    if (_vetId == null) return;

    final TimeOfDay startTime = _parseTimeString(_startTimeController.text);
    final TimeOfDay endTime = _parseTimeString(_endTimeController.text);

    if (!_validateTimeSlot(startTime, endTime)) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final maxAppointments =
          int.tryParse(_maxAppointmentsController.text) ?? 1;

      await _appointmentService.createTimeSlot(
        vetId: _vetId!,
        date: _selectedDate,
        startTime: startTime,
        endTime: endTime,
        maxAppointments: maxAppointments,
      );

      await _fetchTimeSlotsForDate();

      _startTimeController.clear();
      _endTimeController.clear();
      _maxAppointmentsController.text = '1';

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Failed to add time slot: ${e.toString()}";
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteTimeSlot(String slotId) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _appointmentService.deleteTimeSlot(slotId);
      await _fetchTimeSlotsForDate();
    } catch (e) {
      setState(() {
        _errorMessage = "Failed to delete time slot: ${e.toString()}";
        _isLoading = false;
      });
    }
  }

  TimeOfDay _parseTimeString(String timeStr) {
    final format = DateFormat.jm();
    final time = format.parse(timeStr);
    return TimeOfDay(hour: time.hour, minute: time.minute);
  }

  bool _validateTimeSlot(TimeOfDay startTime, TimeOfDay endTime) {
    final startMinutes = startTime.hour * 60 + startTime.minute;
    final endMinutes = endTime.hour * 60 + endTime.minute;

    if (endMinutes <= startMinutes) {
      _showErrorSnackBar("End time must be after start time");
      return false;
    }

    if (endMinutes - startMinutes < _slotDuration) {
      _showErrorSnackBar("Time slot must be at least $_slotDuration minutes");
      return false;
    }

    for (final slot in _timeSlots) {
      final existingStartMinutes =
          slot.startTime.hour * 60 + slot.startTime.minute;
      final existingEndMinutes = slot.endTime.hour * 60 + slot.endTime.minute;

      if ((startMinutes >= existingStartMinutes &&
              startMinutes < existingEndMinutes) ||
          (endMinutes > existingStartMinutes &&
              endMinutes <= existingEndMinutes) ||
          (startMinutes <= existingStartMinutes &&
              endMinutes >= existingEndMinutes)) {
        _showErrorSnackBar("This time slot overlaps with an existing slot");
        return false;
      }
    }

    return true;
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> _showTimePicker(TextEditingController controller) async {
    final initialTime =
        controller.text.isNotEmpty
            ? _parseTimeString(controller.text)
            : TimeOfDay.now();

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Color(0xFF2C3B46),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedTime != null) {
      final formattedTime = DateFormat.jm().format(
        DateTime(2022, 1, 1, pickedTime.hour, pickedTime.minute),
      );
      controller.text = formattedTime;
    }
  }

  void _showAddSlotBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF252D32),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder:
          (context) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 20,
              right: 20,
              top: 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Add Available Time Slot",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Time Range",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _startTimeController,
                        readOnly: true,
                        onTap: () => _showTimePicker(_startTimeController),
                        decoration: InputDecoration(
                          hintText: "Start Time",
                          hintStyle: const TextStyle(color: Colors.white54),
                          filled: true,
                          fillColor: const Color(0xFF1F2323),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          suffixIcon: const Icon(
                            Icons.access_time,
                            color: AppColors.primary,
                          ),
                        ),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      "to",
                      style: TextStyle(fontSize: 16, color: Colors.white70),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: _endTimeController,
                        readOnly: true,
                        onTap: () => _showTimePicker(_endTimeController),
                        decoration: InputDecoration(
                          hintText: "End Time",
                          hintStyle: const TextStyle(color: Colors.white54),
                          filled: true,
                          fillColor: const Color(0xFF1F2323),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          suffixIcon: const Icon(
                            Icons.access_time,
                            color: AppColors.primary,
                          ),
                        ),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text(
                  "Maximum Appointments",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _maxAppointmentsController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: "Number of appointments possible in this slot",
                    hintStyle: const TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: const Color(0xFF1F2323),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _addTimeSlot,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      "Add Time Slot",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF252D32),
      appBar: AppBar(
        title: const Text(
          "Manage Availability",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF2C3B46),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          _buildDateSelector(),
          Expanded(
            child:
                _isLoading
                    ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    )
                    : _errorMessage != null
                    ? Center(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    )
                    : _timeSlots.isEmpty
                    ? _buildEmptyState()
                    : _buildTimeSlotsList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddSlotBottomSheet,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildDateSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF2C3B46),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              "Select Date",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white70,
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 14,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemBuilder: (context, index) {
                final date = DateTime.now().add(Duration(days: index));
                final isSelected = _isSameDay(date, _selectedDate);

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedDate = date;
                    });
                    _fetchTimeSlotsForDate();
                  },
                  child: Container(
                    width: 60,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? AppColors.primary
                              : const Color(0xFF1F2323),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          DateFormat('E').format(date),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('d').format(date),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('MMM').format(date),
                          style: TextStyle(
                            fontSize: 12,
                            color: isSelected ? Colors.white : Colors.white70,
                          ),
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
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.event_busy, size: 80, color: Colors.white30),
          const SizedBox(height: 16),
          Text(
            "No time slots available for ${DateFormat('EEEE, MMMM d').format(_selectedDate)}",
            style: const TextStyle(fontSize: 16, color: Colors.white70),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showAddSlotBottomSheet,
            icon: const Icon(Icons.add),
            label: const Text("Add Time Slot"),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSlotsList() {
    final sortedSlots = List<TimeSlot>.from(_timeSlots)..sort((a, b) {
      final aMinutes = a.startTime.hour * 60 + a.startTime.minute;
      final bMinutes = b.startTime.hour * 60 + b.startTime.minute;
      return aMinutes.compareTo(bMinutes);
    });

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedSlots.length,
      itemBuilder: (context, index) {
        final slot = sortedSlots[index];
        return _buildTimeSlotCard(slot);
      },
    );
  }

  Widget _buildTimeSlotCard(TimeSlot slot) {
    final startTime = DateFormat.jm().format(
      DateTime(2022, 1, 1, slot.startTime.hour, slot.startTime.minute),
    );
    final endTime = DateFormat.jm().format(
      DateTime(2022, 1, 1, slot.endTime.hour, slot.endTime.minute),
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: const Color(0xFF2C3B46),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.access_time,
                color: AppColors.primary,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "$startTime - $endTime",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                      children: [
                        const TextSpan(
                          text: "Max appointments: ",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(text: slot.maxAppointments.toString()),
                      ],
                    ),
                  ),
                  if (slot.bookedAppointments > 0) ...[
                    const SizedBox(height: 4),
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                        children: [
                          const TextSpan(
                            text: "Booked appointments: ",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextSpan(
                            text:
                                "${slot.bookedAppointments}/${slot.maxAppointments}",
                            style: TextStyle(
                              color:
                                  slot.bookedAppointments >=
                                          slot.maxAppointments
                                      ? Colors.red
                                      : Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (slot.bookedAppointments == 0)
              IconButton(
                onPressed: () => _deleteTimeSlot(slot.id),
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                tooltip: "Delete time slot",
              ),
          ],
        ),
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class TimeSlot {
  final String id;
  final String vetId;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final int maxAppointments;
  final int bookedAppointments;

  TimeSlot({
    required this.id,
    required this.vetId,
    required this.startTime,
    required this.endTime,
    required this.maxAppointments,
    this.bookedAppointments = 0,
  });

  factory TimeSlot.fromMap(Map<String, dynamic> map) {
    return TimeSlot(
      id: map['id'],
      vetId: map['vet_id'],
      startTime: TimeOfDay(
        hour: map['start_hour'] ?? 0,
        minute: map['start_minute'] ?? 0,
      ),
      endTime: TimeOfDay(
        hour: map['end_hour'] ?? 0,
        minute: map['end_minute'] ?? 0,
      ),
      maxAppointments: map['max_appointments'] ?? 1,
      bookedAppointments: map['booked_appointments'] ?? 0,
    );
  }
}
