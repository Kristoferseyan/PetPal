import 'package:flutter/material.dart';
import 'package:petpal/services/auth_service.dart';
import 'package:petpal/utils/colors.dart';
import 'package:petpal/vet-modules/pages/vet_health_record_page.dart';

class VetMainhealthRecords extends StatefulWidget {
  final String? petId;
  final String? ownerId;

  const VetMainhealthRecords({Key? key, this.petId, this.ownerId})
    : super(key: key);

  @override
  State<VetMainhealthRecords> createState() => _VetMainhealthRecordsState();
}

class _VetMainhealthRecordsState extends State<VetMainhealthRecords> {
  final AuthService _authService = AuthService();
  List<Map<String, dynamic>> petOwners = [];
  List<Map<String, dynamic>> filteredOwners = [];
  String selectedOwnerName = '';
  bool isLoading = true;
  bool initialNavigationDone = false;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPetOwners();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!initialNavigationDone &&
        (widget.petId != null || widget.ownerId != null)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleDirectNavigation();
      });
    }
  }

  Future<void> _handleDirectNavigation() async {
    if (initialNavigationDone) return;
    initialNavigationDone = true;

    if (widget.ownerId != null) {
      String ownerName = 'Pet Owner';
      for (var owner in petOwners) {
        if (owner['id'] == widget.ownerId) {
          ownerName = owner['full_name'] ?? 'Pet Owner';
          break;
        }
      }

      if (mounted) {
        _goToHealthRecords(widget.ownerId!, ownerName, widget.petId);
      }
    }
  }

  Future<void> _loadPetOwners() async {
    setState(() => isLoading = true);
    try {
      List<Map<String, dynamic>> owners = await _authService.getPetOwners();
      setState(() {
        petOwners = owners;
        filteredOwners = owners;
        isLoading = false;
      });

      if (!initialNavigationDone &&
          (widget.petId != null || widget.ownerId != null)) {
        _handleDirectNavigation();
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  void _goToHealthRecords(String ownerId, String ownerName, [String? petId]) {
    setState(() => selectedOwnerName = ownerName);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => HealthRecordsPage(
              ownerId: ownerId,
              ownerName: selectedOwnerName,
              initialPetId: petId,
            ),
      ),
    );
  }

  void _filterOwners(String searchTerm) {
    setState(() {
      if (searchTerm.isEmpty) {
        filteredOwners = List.from(petOwners);
      } else {
        filteredOwners =
            petOwners.where((owner) {
              final String name = (owner['full_name'] ?? '').toLowerCase();

              final String email = (owner['email'] ?? '').toLowerCase();

              final String phone = (owner['phone'] ?? '').toLowerCase();

              final String term = searchTerm.toLowerCase();

              return name.contains(term) ||
                  email.contains(term) ||
                  phone.contains(term);
            }).toList();
      }
    });
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';

    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.length == 1 && parts[0].isNotEmpty) {
      return parts[0][0].toUpperCase();
    }

    return '?';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Medical Records",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color.fromARGB(255, 37, 45, 50),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadPetOwners,
            tooltip: 'Refresh',
          ),
        ],
      ),
      backgroundColor: const Color.fromARGB(255, 37, 45, 50),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child:
                isLoading
                    ? _buildLoadingView()
                    : filteredOwners.isEmpty
                    ? _buildEmptyState()
                    : _buildOwnersList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 44, 59, 70),
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
          TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search pet owners...',
              hintStyle: TextStyle(color: Colors.grey[400]),
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              suffixIcon:
                  _searchController.text.isNotEmpty
                      ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                          _filterOwners('');
                        },
                      )
                      : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: const Color.fromARGB(255, 55, 71, 79),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onChanged: _filterOwners,
          ),
          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              RichText(
                text: TextSpan(
                  children: [
                    const TextSpan(
                      text: 'Pet Owners ',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextSpan(
                      text: '(${filteredOwners.length})',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 16,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: _loadPetOwners,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Refresh List'),
                style: TextButton.styleFrom(foregroundColor: AppColors.primary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppColors.primary),
          const SizedBox(height: 20),
          Text(
            'Loading pet owners...',
            style: TextStyle(color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final bool isSearching = _searchController.text.isNotEmpty;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSearching ? Icons.search_off : Icons.people_outline,
              size: 80,
              color: Colors.grey[600],
            ),
            const SizedBox(height: 24),
            Text(
              isSearching ? 'No matching owners found' : 'No pet owners yet',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              isSearching
                  ? 'Try a different search term or check spelling'
                  : 'Pet owners will appear here when added to the system',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[400]),
            ),
            const SizedBox(height: 32),
            if (isSearching)
              ElevatedButton.icon(
                onPressed: () {
                  _searchController.clear();
                  _filterOwners('');
                },
                icon: const Icon(Icons.clear),
                label: const Text('Clear Search'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOwnersList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredOwners.length,
      itemBuilder: (context, index) {
        final owner = filteredOwners[index];
        final String ownerName = owner['full_name'] ?? 'Unnamed Owner';
        final String ownerEmail = owner['email'] ?? 'No email';

        return Card(
          elevation: 3,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          color: const Color.fromARGB(255, 44, 54, 60),
          child: InkWell(
            onTap: () => _goToHealthRecords(owner['id'], ownerName, null),
            borderRadius: BorderRadius.circular(15),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: _getAvatarColor(ownerName),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        _getInitials(ownerName),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ownerName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(
                              Icons.email_outlined,
                              size: 14,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                ownerEmail,
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 14,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.medical_information,
                          color: AppColors.primary,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'View Records',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getAvatarColor(String name) {
    if (name.isEmpty) return Colors.grey;

    final int hashCode = name.hashCode;
    final List<Color> colors = [
      Colors.teal,
      Colors.indigo,
      Colors.orange.shade800,
      Colors.deepPurple,
      Colors.pink.shade700,
      Colors.blueGrey.shade700,
      Colors.green.shade800,
    ];

    return colors[hashCode.abs() % colors.length];
  }
}
