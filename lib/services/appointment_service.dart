import 'package:intl/intl.dart';
import 'package:petpal/vet-modules/pages/vet_set_appointment_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:petpal/services/auth_service.dart';

class AppointmentService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final AuthService _authService = AuthService();

  bool isStatusMatch(String actual, String expected) {
    if (actual == expected) return true;
    return actual.toLowerCase() == expected.toLowerCase();
  }

  Future<void> createAppointment({
    required String petId,
    required String vetId,
    required DateTime appointmentDateTime,
    required String purpose,
    required BuildContext context,
  }) async {
    try {
      final userDetails = await _authService.getUserDetails();
      final petOwner = userDetails?['id'];

      if (petOwner == null) {
        throw Exception('Could not identify pet owner');
      }

      final details = {'appointment_type': 'Check-up', 'notes': purpose};

      await _supabase.from('appointments').insert({
        'pet_id': petId,
        'vet_id': vetId,
        'pet_owner_id': petOwner,
        'appointment_date': appointmentDateTime.toIso8601String(),
        'status': 'pending',
        'details': details,
        'createdDateTime': DateTime.now().toIso8601String(),
      });

      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Appointment Scheduled'),
              content: Text(
                'Your appointment has been scheduled for ${appointmentDateTime.toLocal()}',
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to schedule appointment: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> createAppointmentWithDetails({
    required String petId,
    required DateTime appointmentDateTime,
    required String purpose,
    required Map<String, dynamic> details,
    required BuildContext context,
  }) async {
    try {
      final userDetails = await _authService.getUserDetails();
      final petOwner = userDetails?['id'];

      if (petOwner == null) {
        throw Exception('Could not identify pet owner');
      }

      if (purpose.isNotEmpty) {
        details['notes'] = purpose;
      }

      final Map<String, dynamic> appointmentData = {
        'pet_id': petId,
        'vet_id': null,
        'pet_owner_id': petOwner,
        'appointment_date': appointmentDateTime.toIso8601String(),
        'status': 'pending',
        'details': details,
        'createdDateTime': DateTime.now().toIso8601String(),
      };

      await _supabase.from('appointments').insert(appointmentData);

      final String appointmentType =
          details['appointment_type'] ?? 'appointment';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your $appointmentType has been scheduled.',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text('Status: Pending approval'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 5),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to schedule appointment: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String calculatePetAge(String birthDateString) {
    try {
      final DateTime birthDate = DateTime.parse(birthDateString);
      final DateTime now = DateTime.now();

      int years = now.year - birthDate.year;
      int months = now.month - birthDate.month;

      if (now.day < birthDate.day) {
        months--;
      }

      if (months < 0) {
        years--;
        months += 12;
      }

      if (years > 0) {
        return "$years ${years == 1 ? 'year' : 'years'}";
      } else {
        return "$months ${months == 1 ? 'month' : 'months'}";
      }
    } catch (e) {
      return "Unknown";
    }
  }

  Future<List<Map<String, dynamic>>> getAllPendingAppointments() async {
    try {
      final response = await _supabase
          .from('appointments')
          .select('id, pet_id, pet_owner_id, appointment_date, status, details')
          .order('appointment_date', ascending: true);

      final pendingResponse =
          response.where((appointment) {
            final status =
                appointment['status']?.toString().toLowerCase() ?? '';
            return status == 'pending';
          }).toList();

      List<Map<String, dynamic>> formattedAppointments = [];

      for (var appointment in pendingResponse) {
        try {
          final petResponse =
              await _supabase
                  .from('pets')
                  .select('id, name')
                  .eq('id', appointment['pet_id'])
                  .single();

          final petDetailsResponse =
              await _supabase
                  .from('pet_details')
                  .select('birthdate, species, breed, image_url')
                  .eq('pet_id', appointment['pet_id'])
                  .single();

          final ownerResponse =
              await _supabase
                  .from('users')
                  .select('id, full_name')
                  .eq('id', appointment['pet_owner_id'])
                  .single();

          String ageText = "Unknown";
          if (petDetailsResponse['birthdate'] != null) {
            ageText = calculatePetAge(petDetailsResponse['birthdate']);
          }

          final DateTime appointmentDateTime = DateTime.parse(
            appointment['appointment_date'],
          );
          final String formattedDate = DateFormat(
            'yyyy-MM-dd',
          ).format(appointmentDateTime);
          final String formattedTime = DateFormat(
            'HH:mm',
          ).format(appointmentDateTime);

          final details = appointment['details'] ?? {};
          final String appointmentType =
              details['appointment_type'] ?? 'Check-up';
          final String operationType = details['operation_type'] ?? '';
          final String notes = details['notes'] ?? '';

          formattedAppointments.add({
            'id': appointment['id'],
            'petId': petResponse['id'],
            'petName': petResponse['name'],
            'species': petDetailsResponse['species'] ?? 'Unknown',
            'breed': petDetailsResponse['breed'] ?? 'Unknown',
            'age': ageText,
            'petImageUrl': petDetailsResponse['image_url'],
            'ownerId': ownerResponse['id'],
            'ownerName': ownerResponse['full_name'],
            'ownerImage': null,
            'appointmentDate': formattedDate,
            'appointmentTime': formattedTime,
            'status': appointment['status'],
            'purpose': notes,
            'appointmentType': appointmentType,
            'operationType': operationType,
          });
        } catch (e) {}
      }

      return formattedAppointments;
    } catch (e) {
      throw Exception('Failed to fetch pending appointments: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getAppointments(String userId) async {
    try {
      final response = await _supabase
          .from('appointments')
          .select(
            'id, pet_id, appointment_date, status, details, pets(name), updated_at',
          )
          .eq('pet_owner_id', userId)
          .order('appointment_date', ascending: true);

      List<Map<String, dynamic>> appointments = [];

      for (var item in response) {
        final appointmentDate = DateTime.parse(item['appointment_date']);
        final formattedDate =
            "${appointmentDate.year}-${appointmentDate.month.toString().padLeft(2, '0')}-${appointmentDate.day.toString().padLeft(2, '0')}";
        final formattedTime =
            "${appointmentDate.hour.toString().padLeft(2, '0')}:${appointmentDate.minute.toString().padLeft(2, '0')}";

        final details = item['details'] ?? {};
        final purpose = details['notes'] ?? '';

        final appointment = {
          'id': item['id'],
          'petId': item['pet_id'],
          'petName': item['pets']['name'],
          'appointmentDate': formattedDate,
          'appointmentTime': formattedTime,
          'rawDate': item['appointment_date'],
          'status': item['status'],
          'purpose': purpose,
          'details': details,
          'created_at': null, // Not available in database
          'updated_at': item['updated_at'],
        };

        appointments.add(appointment);
      }

      return appointments;
    } catch (e) {
      throw Exception("Failed to fetch appointments: $e");
    }
  }

  Future<List<Map<String, dynamic>>> getAppointmentsForThisWeek() async {
    try {
      final today = DateTime.now();

      final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
      final endOfWeek = startOfWeek.add(
        Duration(days: 6, hours: 23, minutes: 59, seconds: 59),
      );

      final startDateStr =
          "${startOfWeek.year}-${startOfWeek.month.toString().padLeft(2, '0')}-${startOfWeek.day.toString().padLeft(2, '0')}";
      final endDateStr =
          "${endOfWeek.year}-${endOfWeek.month.toString().padLeft(2, '0')}-${endOfWeek.day.toString().padLeft(2, '0')}";

      final response = await _supabase
          .from('appointments')
          .select('id, pet_id, pet_owner_id, appointment_date, status, details')
          .gte('appointment_date', startDateStr)
          .lte('appointment_date', endDateStr + ' 23:59:59')
          .order('appointment_date');

      final approvedAppointments =
          response
              .where(
                (appt) => appt['status'].toString().toLowerCase() == 'approved',
              )
              .toList();

      if (approvedAppointments.isEmpty) {
        return [];
      }

      List<Map<String, dynamic>> formattedAppointments = [];

      for (var appointment in approvedAppointments) {
        try {
          final petResponse =
              await _supabase
                  .from('pets')
                  .select('id, name')
                  .eq('id', appointment['pet_id'])
                  .single();

          final petDetailsResponse =
              await _supabase
                  .from('pet_details')
                  .select('birthdate, species, breed, image_url')
                  .eq('pet_id', appointment['pet_id'])
                  .single();

          final ownerResponse =
              await _supabase
                  .from('users')
                  .select('id, full_name')
                  .eq('id', appointment['pet_owner_id'])
                  .single();

          String ageText = "Unknown";
          if (petDetailsResponse['birthdate'] != null) {
            ageText = calculatePetAge(petDetailsResponse['birthdate']);
          }

          final DateTime appointmentDateTime = DateTime.parse(
            appointment['appointment_date'],
          );

          final String formattedDate =
              "${appointmentDateTime.year}-${appointmentDateTime.month.toString().padLeft(2, '0')}-${appointmentDateTime.day.toString().padLeft(2, '0')}";
          final String formattedTime = DateFormat(
            'HH:mm',
          ).format(appointmentDateTime);

          String notes = "";
          String appointmentType = "Check-up";
          String operationType = "";

          if (appointment['details'] != null && appointment['details'] is Map) {
            Map<String, dynamic> details = appointment['details'];
            notes = details['notes'] ?? details['purpose'] ?? "";
            appointmentType = details['appointment_type'] ?? "Check-up";
            operationType = details['operation_type'] ?? "";
          }

          formattedAppointments.add({
            'id': appointment['id'],
            'petId': petResponse['id'],
            'petName': petResponse['name'],
            'species': petDetailsResponse['species'] ?? 'Unknown',
            'breed': petDetailsResponse['breed'] ?? 'Unknown',
            'age': ageText,
            'petImageUrl': petDetailsResponse['image_url'],
            'ownerId': ownerResponse['id'],
            'ownerName': ownerResponse['full_name'],
            'ownerImage': null,
            'appointmentDate': formattedDate,
            'appointmentTime': formattedTime,
            'status': appointment['status'],
            'purpose': notes,
            'appointmentType': appointmentType,
            'operationType': operationType,
          });
        } catch (e) {}
      }

      return formattedAppointments;
    } catch (e) {
      throw Exception("Failed to fetch appointments for this week: $e");
    }
  }

  Future<void> updateAppointmentStatus(
    String appointmentId,
    String newStatus,
  ) async {
    try {
      // Ensure status is lowercase to match database constraint
      final String normalizedStatus = newStatus.toLowerCase();

      await _supabase
          .from('appointments')
          .update({
            'status': normalizedStatus,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', appointmentId);
    } catch (e) {
      throw Exception("Failed to update appointment status: $e");
    }
  }

  Future<void> cancelAppointment(
    String appointmentId,
    BuildContext context,
  ) async {
    try {
      await _supabase
          .from('appointments')
          .update({
            'status': 'cancelled',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', appointmentId);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Appointment cancelled successfully'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error cancelling appointment: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> approveAppointment(
    String appointmentId,
    String staffId,
    BuildContext context,
  ) async {
    try {
      await _supabase
          .from('appointments')
          .update({
            'vet_id': staffId,
            'status': 'approved',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', appointmentId);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Appointment approved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to approve appointment: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      throw Exception('Failed to approve appointment');
    }
  }

  Future<List<TimeSlot>> getTimeSlotsByVetAndDate({
    required String vetId,
    required DateTime date,
  }) async {
    final formattedDate = DateFormat('yyyy-MM-dd').format(date);

    try {
      final List<dynamic> timeSlots = await _supabase
          .from('time_slots')
          .select(
            'id, start_hour, start_minute, end_hour, end_minute, max_appointments',
          )
          .eq('vet_id', vetId)
          .eq('date', formattedDate);

      List<TimeSlot> results = [];

      for (var slot in timeSlots) {
        final String slotId = slot['id'];

        final List<dynamic> appointments = await _supabase
            .from('appointments')
            .select('id')
            .eq('time_slot_id', slotId);

        final int bookedAppointments = appointments.length;

        results.add(
          TimeSlot(
            id: slot['id'],
            vetId: vetId,
            startTime: TimeOfDay(
              hour: slot['start_hour'] ?? 0,
              minute: slot['start_minute'] ?? 0,
            ),
            endTime: TimeOfDay(
              hour: slot['end_hour'] ?? 0,
              minute: slot['end_minute'] ?? 0,
            ),
            maxAppointments: slot['max_appointments'] ?? 1,
            bookedAppointments: bookedAppointments,
          ),
        );
      }

      return results;
    } catch (e) {
      throw Exception('Failed to get time slots: ${e.toString()}');
    }
  }

  Future<void> createTimeSlot({
    required String vetId,
    required DateTime date,
    required TimeOfDay startTime,
    required TimeOfDay endTime,
    required int maxAppointments,
  }) async {
    final formattedDate = DateFormat('yyyy-MM-dd').format(date);

    try {
      await _supabase.from('time_slots').insert({
        'vet_id': vetId,
        'date': formattedDate,
        'start_hour': startTime.hour,
        'start_minute': startTime.minute,
        'end_hour': endTime.hour,
        'end_minute': endTime.minute,
        'max_appointments': maxAppointments,
      });
    } catch (e) {
      throw Exception('Failed to create time slot: ${e.toString()}');
    }
  }

  Future<void> deleteTimeSlot(String slotId) async {
    try {
      await _supabase.from('time_slots').delete().eq('id', slotId);
    } catch (e) {
      throw Exception('Failed to delete time slot: ${e.toString()}');
    }
  }

  Future<List<TimeSlot>> getAvailableTimeSlots({
    required String vetId,
    required DateTime date,
  }) async {
    final formattedDate = DateFormat('yyyy-MM-dd').format(date);

    try {
      final List<dynamic> timeSlots = await _supabase
          .from('time_slots')
          .select(
            'id, start_hour, start_minute, end_hour, end_minute, max_appointments',
          )
          .eq('vet_id', vetId)
          .eq('date', formattedDate);

      List<TimeSlot> results = [];

      for (var slot in timeSlots) {
        final String slotId = slot['id'];

        final List<dynamic> appointments = await _supabase
            .from('appointments')
            .select('id')
            .eq('time_slot_id', slotId);

        final int bookedAppointments = appointments.length;
        final int maxAppointments = slot['max_appointments'] ?? 1;

        if (bookedAppointments < maxAppointments) {
          results.add(
            TimeSlot(
              id: slot['id'],
              vetId: vetId,
              startTime: TimeOfDay(
                hour: slot['start_hour'] ?? 0,
                minute: slot['start_minute'] ?? 0,
              ),
              endTime: TimeOfDay(
                hour: slot['end_hour'] ?? 0,
                minute: slot['end_minute'] ?? 0,
              ),
              maxAppointments: maxAppointments,
              bookedAppointments: bookedAppointments,
            ),
          );
        }
      }

      return results;
    } catch (e) {
      throw Exception('Failed to get available time slots: ${e.toString()}');
    }
  }

  Future<List<TimeSlot>> getAllAvailableTimeSlots({
    required DateTime date,
  }) async {
    final formattedDate = DateFormat('yyyy-MM-dd').format(date);

    try {
      final List<dynamic> timeSlots = await _supabase
          .from('time_slots')
          .select(
            'id, vet_id, start_hour, start_minute, end_hour, end_minute, max_appointments',
          )
          .eq('date', formattedDate);

      List<TimeSlot> results = [];

      for (var slot in timeSlots) {
        final String slotId = slot['id'];

        final List<dynamic> appointments = await _supabase
            .from('appointments')
            .select('id')
            .eq('time_slot_id', slotId);

        final int bookedAppointments = appointments.length;
        final int maxAppointments = slot['max_appointments'] ?? 1;

        if (bookedAppointments < maxAppointments) {
          results.add(
            TimeSlot(
              id: slot['id'],
              vetId: slot['vet_id'],
              startTime: TimeOfDay(
                hour: slot['start_hour'] ?? 0,
                minute: slot['start_minute'] ?? 0,
              ),
              endTime: TimeOfDay(
                hour: slot['end_hour'] ?? 0,
                minute: slot['end_minute'] ?? 0,
              ),
              maxAppointments: maxAppointments,
              bookedAppointments: bookedAppointments,
            ),
          );
        }
      }

      return results;
    } catch (e) {
      throw Exception('Failed to get available time slots: ${e.toString()}');
    }
  }

  Future<List<Map<String, dynamic>>> getOngoingAppointments() async {
    try {
      final response = await _supabase
          .from('appointments')
          .select('id, pet_id, pet_owner_id, appointment_date, status, details')
          .order('appointment_date', ascending: true);

      final filteredResponse =
          response.where((appointment) {
            final status =
                appointment['status']?.toString().toLowerCase() ?? '';
            return status == 'on-going' ||
                status == 'ongoing' ||
                status == 'on going';
          }).toList();

      List<Map<String, dynamic>> formattedAppointments = [];

      for (var appointment in filteredResponse) {
        try {
          final petResponse =
              await _supabase
                  .from('pets')
                  .select('id, name')
                  .eq('id', appointment['pet_id'])
                  .single();

          final petDetailsResponse =
              await _supabase
                  .from('pet_details')
                  .select('birthdate, species, breed, image_url')
                  .eq('pet_id', appointment['pet_id'])
                  .single();

          final ownerResponse =
              await _supabase
                  .from('users')
                  .select('id, full_name')
                  .eq('id', appointment['pet_owner_id'])
                  .single();

          String ageText = "Unknown";
          if (petDetailsResponse['birthdate'] != null) {
            ageText = calculatePetAge(petDetailsResponse['birthdate']);
          }

          final DateTime appointmentDateTime = DateTime.parse(
            appointment['appointment_date'],
          );
          final String formattedDate = DateFormat(
            'yyyy-MM-dd',
          ).format(appointmentDateTime);
          final String formattedTime = DateFormat(
            'HH:mm',
          ).format(appointmentDateTime);

          final details = appointment['details'] ?? {};
          final String appointmentType =
              details['appointment_type'] ?? 'Check-up';
          final String operationType = details['operation_type'] ?? '';
          final String notes = details['notes'] ?? '';

          formattedAppointments.add({
            'id': appointment['id'],
            'petId': petResponse['id'],
            'petName': petResponse['name'],
            'species': petDetailsResponse['species'] ?? 'Unknown',
            'breed': petDetailsResponse['breed'] ?? 'Unknown',
            'age': ageText,
            'petImageUrl': petDetailsResponse['image_url'],
            'ownerId': ownerResponse['id'],
            'ownerName': ownerResponse['full_name'] ?? 'Unknown',
            'appointmentDate': formattedDate,
            'appointmentTime': formattedTime,
            'status': appointment['status'],
            'purpose': notes,
            'appointmentType': appointmentType,
            'operationType': operationType,
          });
        } catch (e) {}
      }

      return formattedAppointments;
    } catch (e) {
      return [];
    }
  }

  Future<void> bookAppointment({
    required String petId,
    required String timeSlotId,
    required String reason,
    Map<String, dynamic>? details,
    BuildContext? context,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      final timeSlotData =
          await _supabase
              .from('time_slots')
              .select('vet_id, date, start_hour, start_minute')
              .eq('id', timeSlotId)
              .single();

      final String vetId = timeSlotData['vet_id'];

      final String slotDate = timeSlotData['date'];
      final int startHour = timeSlotData['start_hour'];
      final int startMinute = timeSlotData['start_minute'];

      final DateTime appointmentDate = DateTime.parse(
        slotDate,
      ).add(Duration(hours: startHour, minutes: startMinute));

      await _supabase.from('appointments').insert({
        'pet_id': petId,
        'vet_id': vetId,
        'pet_owner_id': user.id,
        'time_slot_id': timeSlotId,
        'status': 'pending',
        'details': details,
        'appointment_date': appointmentDate.toIso8601String(),
        'createdDateTime': DateTime.now().toIso8601String(),
      });

      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Appointment request submitted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to book appointment: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }

      throw Exception('Failed to book appointment: ${e.toString()}');
    }
  }

  Future<List<Map<String, dynamic>>> getToPayAppointments() async {
    try {
      final response = await _supabase
          .from('appointments')
          .select('id, pet_id, pet_owner_id, appointment_date, status, details')
          .order('appointment_date', ascending: true);

      final toPayResponse =
          response.where((appointment) {
            final status =
                appointment['status']?.toString().toLowerCase() ?? '';
            return status == 'to pay';
          }).toList();

      List<Map<String, dynamic>> formattedAppointments = [];

      for (var appointment in toPayResponse) {
        try {
          final petResponse =
              await _supabase
                  .from('pets')
                  .select('id, name')
                  .eq('id', appointment['pet_id'])
                  .single();

          final petDetailsResponse =
              await _supabase
                  .from('pet_details')
                  .select('birthdate, species, breed, image_url')
                  .eq('pet_id', appointment['pet_id'])
                  .single();

          final ownerResponse =
              await _supabase
                  .from('users')
                  .select('id, full_name')
                  .eq('id', appointment['pet_owner_id'])
                  .single();

          String ageText = "Unknown";
          if (petDetailsResponse['birthdate'] != null) {
            ageText = calculatePetAge(petDetailsResponse['birthdate']);
          }

          final DateTime appointmentDateTime = DateTime.parse(
            appointment['appointment_date'],
          );
          final String formattedDate = DateFormat(
            'MMM d, yyyy',
          ).format(appointmentDateTime);
          final String formattedTime = DateFormat(
            'h:mm a',
          ).format(appointmentDateTime);

          final details = appointment['details'] as Map<String, dynamic>? ?? {};
          final String appointmentType =
              details['appointment_type'] ?? 'Check-up';
          final String operationType = details['operation_type'] ?? '';
          final String notes =
              details['notes'] ?? details['purpose'] ?? 'No notes provided';

          formattedAppointments.add({
            'id': appointment['id'],
            'petId': petResponse['id'],
            'petName': petResponse['name'],
            'species': petDetailsResponse['species'] ?? 'Unknown',
            'breed': petDetailsResponse['breed'] ?? 'Unknown',
            'age': ageText,
            'petImageUrl': petDetailsResponse['image_url'],
            'ownerId': ownerResponse['id'],
            'ownerName': ownerResponse['full_name'],
            'ownerImage': null,
            'appointmentDate': formattedDate,
            'appointmentTime': formattedTime,
            'status': appointment['status'],
            'purpose': notes,
            'appointmentType': appointmentType,
            'operationType': operationType,
          });
        } catch (e) {}
      }

      return formattedAppointments;
    } catch (e) {
      return [];
    }
  }
}
