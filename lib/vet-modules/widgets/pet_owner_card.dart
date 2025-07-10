import 'package:flutter/material.dart';
import 'package:petpal/utils/colors.dart';

class PetOwnerCard extends StatelessWidget {
  final Map<String, dynamic> owner;
  final List<Map<String, dynamic>> pets;
  final bool isExpanded;
  final VoidCallback onTap;
  final String Function(String) getInitials;
  final Function(Map<String, dynamic>) onViewDetails;

  const PetOwnerCard({
    Key? key,
    required this.owner,
    required this.pets,
    required this.isExpanded,
    required this.onTap,
    required this.getInitials,
    required this.onViewDetails,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      color: const Color.fromARGB(255, 44, 54, 60),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.grey[700],
                    child: Text(
                      getInitials(owner['full_name'] ?? ''),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          owner['full_name'] ?? 'Unnamed Owner',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.email_outlined,
                              size: 14,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                owner['email'] ?? 'No email',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[400],
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        if (owner['phone'] != null &&
                            owner['phone'].toString().isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.phone_outlined,
                                size: 14,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                owner['phone'],
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[400],
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (owner['address'] != null &&
                            owner['address'].toString().isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.home_outlined,
                                size: 14,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  owner['address'],
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[400],
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 6),
                        Text(
                          '${pets.length} ${pets.length == 1 ? 'pet' : 'pets'}',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.primary.withOpacity(0.7),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
          ),

          if (isExpanded)
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: Column(
                children: [
                  const Divider(
                    color: Colors.white12,
                    height: 1,
                    thickness: 1,
                    indent: 16,
                    endIndent: 16,
                  ),
                  if (pets.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Center(
                        child: Text(
                          'No pets found',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[400],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: pets.length,
                      separatorBuilder:
                          (context, index) => const Divider(
                            color: Colors.white12,
                            height: 1,
                            thickness: 1,
                            indent: 16,
                            endIndent: 16,
                          ),
                      itemBuilder: (context, index) {
                        final pet = pets[index];
                        return _buildPetItem(context, pet);
                      },
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPetItem(BuildContext context, Map<String, dynamic> pet) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 4.0,
      ),
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.grey[800],
          image:
              pet['image_url'] != null && pet['image_url'].toString().isNotEmpty
                  ? DecorationImage(
                    image: NetworkImage(pet['image_url']),
                    fit: BoxFit.cover,
                  )
                  : null,
        ),
        child:
            pet['image_url'] == null || pet['image_url'].toString().isEmpty
                ? const Icon(Icons.pets, color: Colors.white70, size: 24)
                : null,
      ),
      title: Text(
        pet['name'] ?? 'Unnamed Pet',
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(
            '${pet['species'] != 'Unknown' ? pet['species'] : 'Unknown species'} • ${pet['breed'] != 'Unknown' ? pet['breed'] : 'Unknown breed'}',
            style: TextStyle(fontSize: 14, color: Colors.grey[400]),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              if (pet['age'] != null) ...[
                Text(
                  '${pet['age']} years',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
              if (pet['age'] != null && pet['gender'] != 'Unknown') ...[
                Text(
                  ' • ',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
              if (pet['gender'] != 'Unknown') ...[
                Text(
                  pet['gender'],
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ],
          ),
        ],
      ),
      trailing: IconButton(
        icon: const Icon(
          Icons.info_outline,
          color: AppColors.primary,
          size: 24,
        ),
        onPressed: () => onViewDetails(pet),
      ),
    );
  }
}
