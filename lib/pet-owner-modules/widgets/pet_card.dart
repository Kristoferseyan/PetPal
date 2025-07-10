import 'package:flutter/material.dart';
import 'package:petpal/pet-owner-modules/pages/pet_details_page.dart';
import 'package:petpal/services/medical_service.dart';

class PetCard extends StatelessWidget {
  final String petName;
  final String species;
  final String breed;
  final String imageUrl;
  final String petId;
  final int age;
  final double weight;
  final String gender;

  const PetCard({
    super.key,
    required this.petName,
    required this.species,
    required this.breed,
    required this.imageUrl,
    required this.petId,
    required this.age,
    required this.weight,
    required this.gender,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color.fromARGB(255, 31, 35, 35),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 6,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    imageUrl.isNotEmpty
                        ? imageUrl
                        : 'assets/images/placeholder.jpg',
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.pets,
                        size: 60,
                        color: Colors.grey,
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      petName,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      species,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () async {
                try {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PetDetailsPage(petId: petId),
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Failed to fetch pet details")),
                  );
                }
              },
              child: Text(
                "See More Details",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
