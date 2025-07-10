import 'package:flutter/material.dart';

class EmptyPetsView extends StatelessWidget {
  const EmptyPetsView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
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
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[800]!.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.pets, size: 48, color: Colors.grey[400]),
            ),
            const SizedBox(height: 16),
            Text(
              "No pets found",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Add your first pet using the 'Add Pet' tab",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }
}
