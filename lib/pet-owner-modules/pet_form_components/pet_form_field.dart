import 'package:flutter/material.dart';
import 'package:petpal/utils/colors.dart';

class PetFormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String hint;
  final TextInputType keyboardType;

  const PetFormField({
    Key? key,
    required this.controller,
    required this.label,
    required this.icon,
    required this.hint,
    this.keyboardType = TextInputType.text,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 4),
          child: Row(
            children: [
              Icon(icon, size: 16, color: AppColors.primary),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[300],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        TextFormField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[600]),
            filled: true,
            fillColor: Colors.grey[800]!.withOpacity(0.3),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.primary, width: 1),
            ),
          ),
        ),
      ],
    );
  }
}

class DropdownPetFormField extends StatelessWidget {
  final String label;
  final IconData icon;
  final List<String> items;
  final String? value;
  final Function(String?) onChanged;
  final String hintText;

  const DropdownPetFormField({
    Key? key,
    required this.label,
    required this.icon,
    required this.items,
    required this.value,
    required this.onChanged,
    required this.hintText,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 4),
          child: Row(
            children: [
              Icon(icon, size: 16, color: AppColors.primary),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[300],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[800]!.withOpacity(0.3),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.transparent, width: 1),
          ),
          child: DropdownButtonFormField<String>(
            value: value,
            isExpanded: true,
            icon: const Icon(Icons.arrow_drop_down, color: AppColors.primary),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 4,
              ),
              border: InputBorder.none,
              hintText: hintText,
              hintStyle: TextStyle(color: Colors.grey[600]),
            ),
            dropdownColor: const Color.fromARGB(255, 50, 60, 65),
            items:
                items.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(
                      value,
                      style: const TextStyle(color: Colors.white),
                    ),
                  );
                }).toList(),
            onChanged: onChanged,
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }
}
