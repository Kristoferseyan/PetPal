import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:petpal/utils/colors.dart';

class PetOwnerMedicalRecordsPage extends StatefulWidget {
  final String petId;
  final String petName;

  const PetOwnerMedicalRecordsPage({
    Key? key,
    required this.petId,
    required this.petName,
  }) : super(key: key);

  @override
  State<PetOwnerMedicalRecordsPage> createState() =>
      _PetOwnerMedicalRecordsPageState();
}

class _PetOwnerMedicalRecordsPageState
    extends State<PetOwnerMedicalRecordsPage> {
  final _supabase = Supabase.instance.client;
  bool isLoading = true;
  List<Map<String, dynamic>> medicalRecords = [];
  Map<int, bool> expandedItems = {};

  @override
  void initState() {
    super.initState();
    _loadMedicalRecords();
  }

  Future<void> _loadMedicalRecords() async {
    try {
      setState(() => isLoading = true);

      final response = await _supabase
          .from('medical_history')
          .select()
          .eq('pet_id', widget.petId)
          .order('created_at', ascending: false);

      setState(() {
        medicalRecords = List<Map<String, dynamic>>.from(response);

        if (medicalRecords.isNotEmpty) {
          expandedItems[0] = true;
        }
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  void _toggleExpanded(int index) {
    setState(() {
      expandedItems[index] = !(expandedItems[index] ?? false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 37, 45, 50),
      appBar: _buildAppBar(),
      body:
          isLoading
              ? _buildLoadingView()
              : medicalRecords.isEmpty
              ? _buildEmptyState()
              : _buildRecordsList(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            '${widget.petName}\'s Medical Records',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            '${medicalRecords.length} record${medicalRecords.length != 1 ? 's' : ''} found',
            style: TextStyle(color: Colors.grey[400], fontSize: 12),
          ),
        ],
      ),
      backgroundColor: const Color.fromARGB(255, 44, 59, 70),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white),
          onPressed: _loadMedicalRecords,
          tooltip: 'Refresh',
        ),
      ],
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppColors.primary),
          const SizedBox(height: 24),
          Text(
            'Loading medical records...',
            style: TextStyle(color: Colors.grey[400], fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[800]!.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.medical_information_outlined,
              size: 70,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Medical Records Yet',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.grey[300],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              'Medical records will appear here\nwhen added by your veterinarian',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[500]),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _loadMedicalRecords,
            icon: const Icon(Icons.refresh),
            label: const Text('Check Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: medicalRecords.length,
      itemBuilder: (context, index) {
        final record = medicalRecords[index];
        final DateTime recordDate = DateTime.parse(record['created_at']);
        final bool isExpanded = expandedItems[index] ?? false;
        final bool isRecent = DateTime.now().difference(recordDate).inDays < 7;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 44, 54, 60),
            borderRadius: BorderRadius.circular(12),
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
              InkWell(
                onTap: () => _toggleExpanded(index),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color:
                              isRecent
                                  ? AppColors.primary.withOpacity(0.2)
                                  : Colors.grey[700]!.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            Text(
                              DateFormat('dd').format(recordDate),
                              style: TextStyle(
                                color:
                                    isRecent ? AppColors.primary : Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              DateFormat(
                                'MMM',
                              ).format(recordDate).toUpperCase(),
                              style: TextStyle(
                                color:
                                    isRecent
                                        ? AppColors.primary
                                        : Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                if (isRecent)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    margin: const EdgeInsets.only(right: 8),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'NEW',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                Expanded(
                                  child: Text(
                                    record['diagnosis'] ?? 'No diagnosis',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('EEEE, MMMM d, y').format(recordDate),
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),

                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color:
                              isExpanded
                                  ? AppColors.primary.withOpacity(0.2)
                                  : Colors.grey[700]!.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isExpanded
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          color:
                              isExpanded ? AppColors.primary : Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              AnimatedCrossFade(
                firstChild: const SizedBox(height: 0),
                secondChild: _buildExpandedContent(record),
                crossFadeState:
                    isExpanded
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 300),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildExpandedContent(Map<String, dynamic> record) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(color: Colors.white24),
          const SizedBox(height: 8),

          _buildDetailWithIcon(
            icon: Icons.medical_services_outlined,
            label: 'Treatment',
            value: record['treatment'],
          ),

          if (record['notes']?.isNotEmpty ?? false)
            _buildDetailWithIcon(
              icon: Icons.notes,
              label: 'Notes',
              value: record['notes'],
            ),

          if (record['image_url']?.isNotEmpty ?? false)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Text(
                  'Attachments',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => _FullScreenImageView(
                                  imageUrl: record['image_url'],
                                ),
                          ),
                        );
                      },
                      child: Image.network(
                        record['image_url'],
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            height: 200,
                            width: double.infinity,
                            color: Colors.grey[800],
                            child: Center(
                              child: CircularProgressIndicator(
                                value:
                                    loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress
                                                .cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                color: AppColors.primary,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildDetailWithIcon({
    required IconData icon,
    required String label,
    required String? value,
  }) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            margin: const EdgeInsets.only(right: 12, top: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FullScreenImageView extends StatelessWidget {
  final String imageUrl;

  const _FullScreenImageView({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  value:
                      loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                  color: AppColors.primary,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
