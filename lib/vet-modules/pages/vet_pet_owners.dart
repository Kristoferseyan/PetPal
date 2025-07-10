import 'package:flutter/material.dart';
import 'package:petpal/utils/colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:petpal/services/auth_service.dart';
import 'package:petpal/vet-modules/widgets/pet_owner_card.dart';
import 'package:petpal/vet-modules/widgets/pet_details_dialog.dart';

class VetPetOwnerPage extends StatefulWidget {
  const VetPetOwnerPage({Key? key}) : super(key: key);

  @override
  State<VetPetOwnerPage> createState() => _VetPetOwnerPageState();
}

class _VetPetOwnerPageState extends State<VetPetOwnerPage> {
  final _supabase = Supabase.instance.client;
  final AuthService _authService = AuthService();
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;

  List<Map<String, dynamic>> _petOwners = [];
  Map<String, List<Map<String, dynamic>>> _petsByOwner = {};
  Map<String, bool> _expandedOwners = {};

  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadPetOwners();
  }

  int _calculateAgeFromBirthdate(String? birthdateStr) {
    if (birthdateStr == null || birthdateStr.isEmpty) return 0;

    try {
      final birthdate = DateTime.parse(birthdateStr);
      final now = DateTime.now();
      int age = now.year - birthdate.year;

      if (now.month < birthdate.month ||
          (now.month == birthdate.month && now.day < birthdate.day)) {
        age--;
      }

      return age < 0 ? 0 : age;
    } catch (e) {
      return 0;
    }
  }

  Future<void> _loadPetOwners() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      final ownersData = await _authService.getPetOwners();

      ownersData.sort(
        (a, b) => (a['full_name'] ?? '').toString().compareTo(
          (b['full_name'] ?? '').toString(),
        ),
      );

      for (var owner in ownersData) {
        _expandedOwners[owner['id']] = false;
      }

      setState(() {
        _petOwners = ownersData;
      });

      for (var owner in ownersData) {
        await _loadPetsForOwner(owner['id']);
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Failed to load pet owners. Please try again.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadPetsForOwner(String ownerId) async {
    try {
      final petsData = await _supabase
          .from('pets')
          .select('''
            *,
            pet_details(*)
          ''')
          .eq('owner_id', ownerId)
          .eq('is_deleted', false);

      List<Map<String, dynamic>> normalizedPets = [];

      for (var pet in petsData) {
        Map<String, dynamic> petDetails = {};

        if (pet['pet_details'] != null) {
          if (pet['pet_details'] is Map) {
            petDetails = pet['pet_details'];
          } else if (pet['pet_details'] is List &&
              pet['pet_details'].isNotEmpty) {
            petDetails = pet['pet_details'][0];
          }
        }

        String? birthdate = petDetails['birthdate'];
        int age = 0;

        if (birthdate != null) {
          age = _calculateAgeFromBirthdate(birthdate);
        }

        Map<String, dynamic> normalizedPet = {
          'id': pet['id'],
          'name': pet['name'] ?? 'Unnamed Pet',
          'owner_id': pet['owner_id'],
          'species': petDetails['species'] ?? 'Unknown',
          'breed': petDetails['breed'] ?? 'Unknown',
          'birthdate': birthdate,
          'age': age,
          'gender': petDetails['gender'] ?? 'Unknown',
          'weight': petDetails['weight'],
          'image_url': petDetails['image_url'] ?? '',
        };

        normalizedPets.add(normalizedPet);
      }

      normalizedPets.sort(
        (a, b) => (a['name'] ?? '').toString().compareTo(
          (b['name'] ?? '').toString(),
        ),
      );

      if (mounted) {
        setState(() {
          _petsByOwner[ownerId] = normalizedPets;
        });
      }
    } catch (e) {}
  }

  List<Map<String, dynamic>> _getFilteredOwners() {
    if (_searchQuery.isEmpty) {
      return _petOwners;
    }

    return _petOwners.where((owner) {
      final name = (owner['full_name'] ?? '').toString().toLowerCase();
      final email = (owner['email'] ?? '').toString().toLowerCase();
      final query = _searchQuery.toLowerCase();

      if (name.contains(query) || email.contains(query)) {
        return true;
      }

      final ownerPets = _petsByOwner[owner['id']] ?? [];
      for (var pet in ownerPets) {
        final petName = (pet['name'] ?? '').toString().toLowerCase();
        final species = (pet['species'] ?? '').toString().toLowerCase();
        final breed = (pet['breed'] ?? '').toString().toLowerCase();

        if (petName.contains(query) ||
            species.contains(query) ||
            breed.contains(query)) {
          return true;
        }
      }

      return false;
    }).toList();
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '';

    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.length == 1 && parts[0].isNotEmpty) {
      return parts[0][0].toUpperCase();
    }

    return '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 37, 45, 50),
      appBar: AppBar(
        title: const Text('Pet Owners', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color.fromARGB(255, 44, 59, 70),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPetOwners,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child:
                _isLoading
                    ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    )
                    : _hasError
                    ? _buildErrorView()
                    : _buildOwnersList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: const Color.fromARGB(255, 44, 59, 70),
      padding: const EdgeInsets.all(12),
      child: TextField(
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Search owners or pets...',
          hintStyle: TextStyle(color: Colors.grey[400]),
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          suffixIcon:
              _searchQuery.isNotEmpty
                  ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.grey),
                    onPressed: () {
                      setState(() {
                        _searchQuery = '';
                      });
                    },
                  )
                  : null,
          filled: true,
          fillColor: const Color.fromARGB(255, 31, 41, 48),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            const Text(
              'Something went wrong',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Failed to load data',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[400]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadPetOwners,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOwnersList() {
    final filteredOwners = _getFilteredOwners();

    if (filteredOwners.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[600]),
            const SizedBox(height: 16),
            Text(
              'No results found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try another search term',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: filteredOwners.length,
      padding: const EdgeInsets.only(bottom: 16),
      itemBuilder: (context, index) {
        final owner = filteredOwners[index];
        final isExpanded = _expandedOwners[owner['id']] ?? false;
        final ownerPets = _petsByOwner[owner['id']] ?? [];

        return PetOwnerCard(
          owner: owner,
          pets: ownerPets,
          isExpanded: isExpanded,
          onTap: () {
            setState(() {
              _expandedOwners[owner['id']] = !isExpanded;
            });
          },
          getInitials: _getInitials,
          onViewDetails: (pet) {
            PetDetailsDialog.show(context, pet);
          },
        );
      },
    );
  }
}
