import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:petpal/services/medical_service.dart';
import 'package:petpal/utils/colors.dart';
import 'package:petpal/vet-modules/pages/health-record-widgets/medical_record_edit_dialog.dart';

class MedicalRecordsList extends StatefulWidget {
  final String petId;
  final List<Map<String, dynamic>> medicalRecords;
  final Function() onRecordUpdated;
  final MedicalService medicalService;

  const MedicalRecordsList({
    Key? key,
    required this.petId,
    required this.medicalRecords,
    required this.onRecordUpdated,
    required this.medicalService,
  }) : super(key: key);

  @override
  State<MedicalRecordsList> createState() => _MedicalRecordsListState();
}

class _MedicalRecordsListState extends State<MedicalRecordsList> {
  @override
  Widget build(BuildContext context) {
    if (widget.medicalRecords.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.healing, size: 60, color: Colors.grey[600]),
            const SizedBox(height: 16),
            Text(
              'No medical records found',
              style: TextStyle(color: Colors.grey[500], fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: widget.medicalRecords.length,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemBuilder: (context, index) {
        final record = widget.medicalRecords[index];

        return MedicalRecordItem(
          record: record,
          onArchived: widget.onRecordUpdated,
          onEdited: widget.onRecordUpdated,
          medicalService: widget.medicalService,
        );
      },
    );
  }
}

class MedicalRecordItem extends StatelessWidget {
  final Map<String, dynamic> record;
  final Function() onArchived;
  final Function() onEdited;
  final MedicalService medicalService;

  const MedicalRecordItem({
    Key? key,
    required this.record,
    required this.onArchived,
    required this.onEdited,
    required this.medicalService,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isOwnerRecord = record['source'] == 'owner';

    if (isOwnerRecord) {
      return _buildRecordCard(context);
    }

    return Dismissible(
      key: Key(record['id']),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.amber[700],
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'ARCHIVE',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(width: 8),
            Icon(Icons.archive, color: Colors.white),
          ],
        ),
      ),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: const Color.fromARGB(255, 37, 45, 50),
              title: const Text(
                'Archive Record',
                style: TextStyle(color: Colors.white),
              ),
              content: const Text(
                'Are you sure you want to archive this medical record?',
                style: TextStyle(color: Colors.white70),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('CANCEL'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('ARCHIVE'),
                ),
              ],
            );
          },
        );
      },
      onDismissed: (direction) async {
        try {
          await medicalService.archiveRecord(record['id']);
          onArchived();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Record archived'),
              action: SnackBarAction(
                label: 'UNDO',
                onPressed: () async {
                  await medicalService.unarchiveRecord(record['id']);
                  onArchived();
                },
              ),
            ),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: _buildRecordCard(context),
    );
  }

  Widget _buildRecordCard(BuildContext context) {
    final isOwnerRecord = record['source'] == 'owner';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color:
          isOwnerRecord
              ? const Color.fromARGB(255, 50, 50, 45)
              : const Color.fromARGB(255, 45, 55, 60),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side:
            isOwnerRecord
                ? BorderSide(color: Colors.amber.withOpacity(0.5), width: 1.5)
                : BorderSide.none,
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          colorScheme: ColorScheme.dark(
            primary: isOwnerRecord ? Colors.amber : AppColors.primary,
          ),
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          expandedAlignment: Alignment.topLeft,
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color:
                      isOwnerRecord
                          ? Colors.amber.withOpacity(0.2)
                          : AppColors.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isOwnerRecord ? Icons.upload_file : Icons.healing,
                  color: isOwnerRecord ? Colors.amber : AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (isOwnerRecord)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            margin: const EdgeInsets.only(right: 6),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'OWNER',
                              style: TextStyle(
                                color: Colors.amber,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        Expanded(
                          child: Text(
                            record['diagnosis'] ?? 'No diagnosis',
                            style: TextStyle(
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
                      DateFormat(
                        'MMM d, y',
                      ).format(DateTime.parse(record['created_at'])),
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  DateFormat(
                    'h:mm a',
                  ).format(DateTime.parse(record['created_at'])),
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
              ),
            ],
          ),
          trailing:
              isOwnerRecord
                  ? const Icon(Icons.visibility, color: Colors.white70)
                  : IconButton(
                    icon: const Icon(Icons.edit, color: Colors.white70),
                    onPressed: () => _showEditDialog(context),
                  ),
          children: [
            const Divider(color: Colors.grey),
            const SizedBox(height: 8),

            if (isOwnerRecord) ...[
              if (record['image_url']?.isNotEmpty ?? false) ...[
                GestureDetector(
                  onTap:
                      () => _showFullScreenImage(context, record['image_url']),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber[700]!, width: 1),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        record['image_url'],
                        height: 300,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            height: 300,
                            color: Colors.grey[800],
                            child: const Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.amber,
                                ),
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 300,
                            color: Colors.grey[800],
                            child: const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.broken_image,
                                    size: 48,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Failed to load image',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'Document uploaded by pet owner',
                    style: TextStyle(
                      color: Colors.amber[200],
                      fontStyle: FontStyle.italic,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ] else ...[
              _buildRecordDetail(
                icon: Icons.medical_information,
                label: 'Treatment Plan',
                value: record['treatment'],
              ),
              if (record['notes']?.isNotEmpty ?? false)
                _buildRecordDetail(
                  icon: Icons.note,
                  label: 'Notes',
                  value: record['notes'],
                ),
              if (record['image_url']?.isNotEmpty ?? false) ...[
                const SizedBox(height: 16),
                GestureDetector(
                  onTap:
                      () => _showFullScreenImage(context, record['image_url']),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[700]!, width: 1),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        record['image_url'],
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            height: 200,
                            color: Colors.grey[800],
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 200,
                            color: Colors.grey[800],
                            child: const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.broken_image,
                                    size: 48,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Failed to load image',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Edit Record'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                    ),
                    onPressed: () => _showEditDialog(context),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRecordDetail({
    required IconData icon,
    required String label,
    required String? value,
  }) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: Colors.grey[400]),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 24),
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context) async {
    if (record['source'] == 'owner') {
      if (record['image_url'] != null) {
        _showFullScreenImage(context, record['image_url']);
      }
      return;
    }

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color.fromARGB(255, 37, 45, 50),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => MedicalRecordEditDialog(
            record: record,
            medicalService: medicalService,
          ),
    );

    if (result == true) {
      onEdited();
    }
  }

  void _showFullScreenImage(BuildContext context, String imageUrl) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) => Scaffold(
              backgroundColor: Colors.black,
              appBar: AppBar(
                backgroundColor: Colors.black,
                iconTheme: const IconThemeData(color: Colors.white),
                title: const Text(
                  'Medical Image',
                  style: TextStyle(color: Colors.white),
                ),
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
                      return const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(
                            Icons.broken_image,
                            color: Colors.white70,
                            size: 64,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Failed to load image',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
      ),
    );
  }
}

class ArchivedRecordsList extends StatelessWidget {
  final String petId;
  final Function() onRecordRestored;
  final MedicalService medicalService;

  const ArchivedRecordsList({
    Key? key,
    required this.petId,
    required this.onRecordRestored,
    required this.medicalService,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: medicalService.getArchivedMedicalHistory(petId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading archived records: ${snapshot.error}',
              style: TextStyle(color: Colors.red[300]),
            ),
          );
        }

        final archivedRecords = snapshot.data ?? [];

        if (archivedRecords.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.archive, size: 60, color: Colors.grey[600]),
                const SizedBox(height: 16),
                Text(
                  'No archived records found',
                  style: TextStyle(color: Colors.grey[500], fontSize: 16),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: archivedRecords.length,
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemBuilder: (context, index) {
            final record = archivedRecords[index];

            return _buildArchivedRecordItem(context, record);
          },
        );
      },
    );
  }

  Widget _buildArchivedRecordItem(
    BuildContext context,
    Map<String, dynamic> record,
  ) {
    return Dismissible(
      key: Key(record['id']),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.green[700],
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'RESTORE',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(width: 8),
            Icon(Icons.restore_from_trash, color: Colors.white),
          ],
        ),
      ),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: const Color.fromARGB(255, 37, 45, 50),
              title: const Text(
                'Restore Record',
                style: TextStyle(color: Colors.white),
              ),
              content: const Text(
                'Move this record back to active medical records?',
                style: TextStyle(color: Colors.white70),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('CANCEL'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('RESTORE'),
                ),
              ],
            );
          },
        );
      },
      onDismissed: (direction) async {
        try {
          await medicalService.unarchiveRecord(record['id']);
          onRecordRestored();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Record restored'),
              backgroundColor: Colors.green,
            ),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: MedicalRecordItem(
        record: record,
        onArchived: () {},
        onEdited: onRecordRestored,
        medicalService: medicalService,
      ),
    );
  }
}
