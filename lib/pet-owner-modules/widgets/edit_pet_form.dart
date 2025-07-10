import 'dart:io';
import 'package:flutter/material.dart';
import 'package:petpal/pet-owner-modules/pages/petOwner_appointment_page.dart';
import 'package:petpal/pet-owner-modules/pet_form_components/empty_pets_view.dart';
import 'package:petpal/pet-owner-modules/pet_form_components/pet_edit_panel.dart';
import 'package:petpal/pet-owner-modules/pet_form_components/pet_list_item.dart';
import 'package:petpal/services/pet_service.dart';
import 'package:petpal/utils/colors.dart';
import 'package:intl/intl.dart';

class EditPetForm extends StatefulWidget {
  final List<Map<String, dynamic>> pets;
  final VoidCallback onPetUpdated;
  final VoidCallback onPetDeleted;

  const EditPetForm({
    Key? key,
    required this.pets,
    required this.onPetUpdated,
    required this.onPetDeleted,
  }) : super(key: key);

  @override
  _EditPetFormState createState() => _EditPetFormState();
}

class _EditPetFormState extends State<EditPetForm> {
  final PetService _petService = PetService();
  String? selectedPetId;

  void _selectPet(String id) {
    setState(() {
      selectedPetId = id;
    });
  }

  void _clearSelection() {
    setState(() {
      selectedPetId = null;
    });
  }

  Future<void> _deletePet(String petId) async {
    try {
      final hasAppointments = await _petService.petHasOngoingAppointments(
        petId,
      );

      if (hasAppointments) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'This pet has ongoing or upcoming appointments and cannot be deleted.',
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }

      await _petService.softDeletePet(petId);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Pet deleted successfully')));

      if (selectedPetId == petId) {
        _clearSelection();
      }

      widget.onPetDeleted();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete pet: ${e.toString()}')),
      );
    }
  }

  void _showDeleteConfirmationDialog(String petId, String petName) async {
    final hasAppointments = await _petService.petHasOngoingAppointments(petId);

    if (hasAppointments) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: const Color.fromARGB(255, 50, 60, 65),
            title: const Text(
              "Cannot Delete Pet",
              style: TextStyle(color: Colors.white),
            ),
            content: Text(
              "$petName has ongoing or upcoming appointments. Please cancel or reschedule these appointments before deleting this pet.",
              style: const TextStyle(color: Colors.white70),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("OK", style: TextStyle(color: Colors.grey)),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();

                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => PetOwnerAppointmentsPage(),
                    ),
                  );
                },
                child: const Text(
                  "View Appointments",
                  style: TextStyle(color: AppColors.primary),
                ),
              ),
            ],
          );
        },
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color.fromARGB(255, 50, 60, 65),
          title: const Text(
            "Delete Pet",
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            "Are you sure you want to remove $petName? This action cannot be undone.",
            style: const TextStyle(color: Colors.white70),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deletePet(petId);
              },
              child: const Text("Delete", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  String getAgeDisplay(String? birthdateStr) {
    if (birthdateStr == null) return "Unknown age";

    try {
      final birthdate = DateTime.parse(birthdateStr);
      final now = DateTime.now();

      int years = now.year - birthdate.year;
      int months = now.month - birthdate.month;

      if (months < 0) {
        years--;
        months += 12;
      }

      if (now.day < birthdate.day) {
        months--;
        if (months < 0) {
          years--;
          months += 12;
        }
      }

      if (years > 0) {
        return months > 0
            ? "$years year${years != 1 ? 's' : ''}, $months month${months != 1 ? 's' : ''}"
            : "$years year${years != 1 ? 's' : ''}";
      } else {
        return "$months month${months != 1 ? 's' : ''}";
      }
    } catch (e) {
      return "Unknown age";
    }
  }

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic>? selectedPet;
    if (selectedPetId != null) {
      selectedPet = widget.pets.firstWhere(
        (pet) => pet['id'] == selectedPetId,
        orElse: () => <String, dynamic>{},
      );

      if (selectedPet.isEmpty) {
        selectedPetId = null;
      }
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "My Pets",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Select a pet to update their information",
                  style: TextStyle(fontSize: 16, color: Colors.grey[400]),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),

          SliverToBoxAdapter(
            child:
                widget.pets.isEmpty ? const EmptyPetsView() : _buildPetsList(),
          ),

          SliverToBoxAdapter(child: const SizedBox(height: 24)),

          SliverToBoxAdapter(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SizeTransition(sizeFactor: animation, child: child),
                );
              },
              child:
                  selectedPet != null
                      ? PetEditPanel(
                        pet: selectedPet,
                        onCancel: _clearSelection,
                        onSaved: () {
                          _clearSelection();
                          widget.onPetUpdated();
                        },
                      )
                      : const SizedBox.shrink(),
            ),
          ),

          SliverToBoxAdapter(child: const SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildPetsList() {
    return Container(
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 44, 54, 60),
        borderRadius: BorderRadius.circular(16),
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
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Icon(Icons.pets, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  "${widget.pets.length} Pet${widget.pets.length != 1 ? 's' : ''}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Colors.white24),

          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.pets.length,
            separatorBuilder:
                (context, index) => const Divider(
                  height: 1,
                  color: Colors.white12,
                  indent: 70,
                  endIndent: 16,
                ),
            itemBuilder: (context, index) {
              final pet = widget.pets[index];
              final bool isSelected = selectedPetId == pet['id'];

              final String ageDisplay = getAgeDisplay(pet['birthdate']);

              return PetListItem(
                pet: pet,
                isSelected: isSelected,
                onTap: () => _selectPet(pet['id']),
                onDelete:
                    () => _showDeleteConfirmationDialog(
                      pet['id'],
                      pet['name'] ?? 'this pet',
                    ),
                ageDisplay: ageDisplay,
              );
            },
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
