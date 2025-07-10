import 'package:flutter/material.dart';
import 'package:petpal/utils/colors.dart';

class PetSelector extends StatelessWidget {
  final List<Map<String, dynamic>> pets;
  final String selectedPetId;
  final Function(String, String) onPetSelected;

  const PetSelector({
    Key? key,
    required this.pets,
    required this.selectedPetId,
    required this.onPetSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 44, 54, 60),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.pets, color: Colors.white70, size: 16),
              const SizedBox(width: 8),
              const Text(
                'Select Pet',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          pets.isEmpty
              ? _buildNoPetsIndicator()
              : SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: pets.map((pet) => _buildPetCard(pet)).toList(),
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildNoPetsIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[800]!.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[700]!),
      ),
      child: const Center(
        child: Text(
          'No pets registered for this owner',
          style: TextStyle(color: Colors.white70),
        ),
      ),
    );
  }

  Widget _buildPetCard(Map<String, dynamic> pet) {
    final petId = pet['id'];
    final petName = pet['name'];
    final petSpecies = pet['species'];
    final petBreed = pet['breed'];
    final petPhoto = pet['photo_url'];
    final isSelected = petId == selectedPetId;

    return GestureDetector(
      onTap: () => onPetSelected(petId, petName),
      child: Container(
        width: 110,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? AppColors.primary.withOpacity(0.2)
                  : Colors.grey[850],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey[800]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(8),
              ),
              child:
                  petPhoto != null
                      ? Image.network(
                        petPhoto,
                        height: 80,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 80,
                            color: Colors.grey[700],
                            child: const Icon(
                              Icons.pets,
                              color: Colors.white54,
                              size: 30,
                            ),
                          );
                        },
                      )
                      : Container(
                        height: 80,
                        color: Colors.grey[700],
                        child: const Icon(
                          Icons.pets,
                          color: Colors.white54,
                          size: 30,
                        ),
                      ),
            ),

            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    petName,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$petSpecies${petBreed != null ? ' • $petBreed' : ''}',
                    style: TextStyle(color: Colors.grey[400], fontSize: 10),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
