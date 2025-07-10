import 'package:flutter/material.dart';
import 'package:petpal/utils/colors.dart';
import 'package:intl/intl.dart';

class PetDetailsDialog extends StatelessWidget {
  final Map<String, dynamic> pet;

  const PetDetailsDialog({Key? key, required this.pet}) : super(key: key);

  static void show(BuildContext context, Map<String, dynamic> pet) {
    showDialog(
      context: context,
      builder: (context) => PetDetailsDialog(pet: pet),
    );
  }

  String? _getImageUrl() {
    if (pet['image_url'] != null && pet['image_url'].toString().isNotEmpty) {
      return pet['image_url'];
    }
    if (pet['imageUrl'] != null && pet['imageUrl'].toString().isNotEmpty) {
      return pet['imageUrl'];
    }

    return null;
  }

  String? _findBirthdate() {
    if (pet['birthdate'] != null) {
      return pet['birthdate'];
    }

    final alternativeNames = [
      'birth_date',
      'dob',
      'date_of_birth',
      'birthDate',
    ];
    for (var name in alternativeNames) {
      if (pet[name] != null) {
        return pet[name];
      }
    }

    if (pet['age'] != null && pet['age'] != 'null') {
      try {
        final age = int.tryParse(pet['age'].toString()) ?? 3;
        final now = DateTime.now();

        return DateTime(now.year - age, now.month, now.day).toIso8601String();
      } catch (e) {}
    }

    return DateTime.now()
        .subtract(const Duration(days: 365 * 3))
        .toIso8601String();
  }

  String _getAgeDisplay(String? birthdateStr) {
    if (birthdateStr == null || birthdateStr.isEmpty) {
      if (pet['age'] != null) {
        final age = pet['age'];
        return "$age year${age != 1 ? 's' : ''}";
      }
      return "Unknown";
    }

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
      if (pet['age'] != null) {
        final age = pet['age'];
        return "$age year${age != 1 ? 's' : ''}";
      }
      return "Unknown";
    }
  }

  String _formatBirthdate(String? birthdateStr) {
    if (birthdateStr == null || birthdateStr.isEmpty) return "Unknown";

    try {
      final birthdate = DateTime.parse(birthdateStr);
      return DateFormat('MMM d, yyyy').format(birthdate);
    } catch (e) {
      return "Unknown";
    }
  }

  @override
  Widget build(BuildContext context) {
    final String? birthdateStr = _findBirthdate();

    final String ageDisplay = _getAgeDisplay(birthdateStr);
    final String birthdateFormatted = _formatBirthdate(birthdateStr);

    final String? imageUrl = _getImageUrl();

    return AlertDialog(
      backgroundColor: const Color.fromARGB(255, 44, 54, 60),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      contentPadding: EdgeInsets.zero,
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                image:
                    imageUrl != null
                        ? DecorationImage(
                          image: NetworkImage(imageUrl),
                          fit: BoxFit.cover,
                        )
                        : null,
              ),
              child:
                  imageUrl == null
                      ? const Center(
                        child: Icon(
                          Icons.pets,
                          size: 80,
                          color: Colors.white30,
                        ),
                      )
                      : null,
            ),

            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          pet['name'] ?? 'Unnamed Pet',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          pet['species'] ?? 'Unknown',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  _buildDetailRow('Breed', pet['breed'] ?? 'Unknown'),
                  _buildDetailRow('Gender', pet['gender'] ?? 'Unknown'),
                  _buildDetailRow('Birthdate', birthdateFormatted),
                  _buildDetailRow('Age', ageDisplay),
                  _buildDetailRow(
                    'Weight',
                    pet['weight'] != null ? '${pet['weight']} kg' : 'Unknown',
                  ),

                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.close, size: 18),
                        label: const Text('Close'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white70,
                          side: const BorderSide(color: Colors.white30),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(fontSize: 16, color: Colors.grey[400]),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
