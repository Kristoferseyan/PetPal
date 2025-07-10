import 'package:flutter/material.dart';
import 'package:petpal/services/auth_service.dart';
import 'package:petpal/services/pet_service.dart';
import 'package:petpal/utils/colors.dart';
import 'package:intl/intl.dart';
import 'package:petpal/services/behavior_notes_service.dart';

class PetActivitiesPage extends StatefulWidget {
  const PetActivitiesPage({super.key});

  @override
  State<PetActivitiesPage> createState() => _PetActivitiesPageState();
}

class _PetActivitiesPageState extends State<PetActivitiesPage>
    with TickerProviderStateMixin {
  final PetService _petService = PetService();
  final AuthService _authService = AuthService();
  final BehaviorNoteService _behaviorNoteService = BehaviorNoteService();

  List<Map<String, dynamic>> _pets = [];
  Map<String, List<Map<String, dynamic>>> _petActivities = {};
  Map<String, List<Map<String, dynamic>>> _behaviorNotes = {};

  bool _isLoading = true;
  String? _error;
  int _selectedPetIndex = 0;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadPetsAndActivities();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPetsAndActivities() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final user = _petService.supabase.auth.currentUser;
      if (user == null || user.id.isEmpty) {
        setState(() {
          _error = 'User not authenticated';
          _isLoading = false;
        });
        return;
      }

      final pets = await _petService.getPetsByOwner(user.id);
      if (pets.isEmpty) {
        setState(() {
          _pets = [];
          _isLoading = false;
        });
        return;
      }

      Map<String, List<Map<String, dynamic>>> petActivities = {};
      Map<String, List<Map<String, dynamic>>> behaviorNotes = {};

      for (var pet in pets) {
        final petId = pet['id'];

        petActivities[petId] = _generateActivityRecommendations(
          pet['species'],
          pet['breed'],
        );

        try {
          final notes = await _behaviorNoteService.getBehaviorNotes(petId);
          behaviorNotes[petId] = notes;
        } catch (e) {
          behaviorNotes[petId] = [];
        }
      }

      setState(() {
        _pets = pets;
        _petActivities = petActivities;
        _behaviorNotes = behaviorNotes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error loading pets: $e';
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> _generateActivityRecommendations(
    String? species,
    String? breed,
  ) {
    final speciesLower = species?.toLowerCase() ?? 'unknown';

    if (speciesLower == 'dog') {
      return [
        {
          'name': 'Daily Walk',
          'description':
              'Take your dog for a 30-minute walk around the neighborhood to promote cardiovascular health and healthy weight.',
          'duration': '30 min',
          'frequency': 'Daily',
          'intensity': 'Moderate',
          'icon': Icons.directions_walk,
        },
        {
          'name': 'Fetch',
          'description':
              'Play fetch in the backyard or local park. This is especially good for high-energy breeds to burn excess energy.',
          'duration': '15-20 min',
          'frequency': '3-4 times per week',
          'intensity': 'High',
          'icon': Icons.sports_baseball,
        },
        {
          'name': 'Obedience Training',
          'description':
              'Practice basic commands and tricks. Mental stimulation is just as important as physical exercise.',
          'duration': '10-15 min',
          'frequency': 'Daily',
          'intensity': 'Low',
          'icon': Icons.school,
        },
        {
          'name': 'Socialization',
          'description':
              'Visit a dog park to let your dog interact with other dogs. Proper socialization helps prevent behavioral issues.',
          'duration': '30-60 min',
          'frequency': 'Weekly',
          'intensity': 'Moderate',
          'icon': Icons.groups,
        },
      ];
    } else if (speciesLower == 'cat') {
      return [
        {
          'name': 'Interactive Toy Play',
          'description':
              'Use feather wands or laser pointers for active play. This satisfies hunting instincts and provides exercise.',
          'duration': '10-15 min',
          'frequency': '2-3 times daily',
          'intensity': 'Moderate',
          'icon': Icons.toys,
        },
        {
          'name': 'Climbing Exercise',
          'description':
              'Encourage use of cat tree or climbing structures to promote muscle tone and natural behavior.',
          'duration': 'Throughout the day',
          'frequency': 'Daily',
          'intensity': 'Low to Moderate',
          'icon': Icons.architecture,
        },
        {
          'name': 'Hide and Seek',
          'description':
              'Hide treats around your home for your cat to find. This engages their sense of smell and hunting instincts.',
          'duration': '10-15 min',
          'frequency': 'Daily',
          'intensity': 'Low',
          'icon': Icons.search,
        },
      ];
    } else if (speciesLower == 'bird') {
      return [
        {
          'name': 'Out-of-Cage Time',
          'description':
              'Let your bird fly freely in a safe, enclosed room to exercise their wings and natural flying behavior.',
          'duration': '30-60 min',
          'frequency': 'Daily',
          'intensity': 'Moderate',
          'icon': Icons.flight_takeoff,
        },
        {
          'name': 'Foraging Activities',
          'description':
              'Hide treats in toys or puzzles to encourage natural foraging behavior and mental stimulation.',
          'duration': '15-30 min',
          'frequency': 'Daily',
          'intensity': 'Low',
          'icon': Icons.psychology,
        },
      ];
    } else if (speciesLower == 'rabbit' || speciesLower == 'guinea pig') {
      return [
        {
          'name': 'Supervised Floor Time',
          'description':
              'Allow your small pet to explore a safe, enclosed area to promote exercise and natural exploration.',
          'duration': '30-60 min',
          'frequency': 'Daily',
          'intensity': 'Moderate',
          'icon': Icons.crop_free,
        },
        {
          'name': 'Tunnels and Hideaways',
          'description':
              'Provide tunnels, boxes, and hiding spots to encourage natural burrowing and exploring behaviors.',
          'duration': 'Always available',
          'frequency': 'Daily',
          'intensity': 'Low',
          'icon': Icons.motion_photos_auto,
        },
      ];
    } else {
      return [
        {
          'name': 'Regular Interaction',
          'description':
              'Spend quality time with your pet daily. Regular handling and interaction promotes bonding and mental well-being.',
          'duration': '15-30 min',
          'frequency': 'Daily',
          'intensity': 'Low',
          'icon': Icons.favorite,
        },
        {
          'name': 'Enrichment Activities',
          'description':
              'Provide species-appropriate toys and activities to prevent boredom and encourage natural behaviors.',
          'duration': 'Varies',
          'frequency': 'Daily',
          'intensity': 'Varies',
          'icon': Icons.extension,
        },
      ];
    }
  }

  List<Map<String, dynamic>> _generateSampleBehaviorNotes() {
    final now = DateTime.now();

    return [
      {
        'date': now.subtract(const Duration(days: 2)),
        'note': 'Has been very energetic and playful today.',
        'mood': 'Happy',
      },
      {
        'date': now.subtract(const Duration(days: 5)),
        'note': 'Seemed a bit lethargic, monitored food intake.',
        'mood': 'Tired',
      },
      {
        'date': now.subtract(const Duration(days: 8)),
        'note': 'Responded well to new training commands.',
        'mood': 'Attentive',
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 31, 38, 42),
      appBar: AppBar(
        title: const Text(
          'Pet Activities',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color.fromARGB(255, 44, 59, 70),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
              : _error != null
              ? _buildErrorView()
              : _pets.isEmpty
              ? _buildNoPetsView()
              : _buildContent(),
      floatingActionButton:
          _pets.isNotEmpty
              ? FloatingActionButton(
                onPressed: _showAddBehaviorNoteDialog,
                backgroundColor: AppColors.primary,
                child: const Icon(Icons.add, color: Colors.white),
                tooltip: 'Add Behavior Note',
              )
              : null,
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 70, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              'Error Loading Data',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red[300],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Unknown error occurred',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadPetsAndActivities,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoPetsView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.pets, size: 70, color: Colors.grey[600]),
            const SizedBox(height: 16),
            const Text(
              'No Pets Found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add a pet to view activity recommendations',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: const Text('Add a Pet'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        _buildPetSelector(),

        TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Activity Recommendations'),
            Tab(text: 'Behavior Notes'),
          ],
        ),

        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [_buildActivityRecommendations(), _buildBehaviorNotes()],
          ),
        ),
      ],
    );
  }

  Widget _buildPetSelector() {
    return Container(
      height: 120,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _pets.length,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemBuilder: (context, index) {
          final pet = _pets[index];
          final isSelected = index == _selectedPetIndex;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedPetIndex = index;
              });
            },
            child: Container(
              width: 90,
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.grey[800],
                    backgroundImage:
                        pet['image_url'] != null &&
                                pet['image_url'].toString().isNotEmpty
                            ? NetworkImage(pet['image_url'])
                            : null,
                    child:
                        pet['image_url'] == null ||
                                pet['image_url'].toString().isEmpty
                            ? Icon(
                              _getPetIcon(pet['species']),
                              size: 30,
                              color: Colors.white70,
                            )
                            : null,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    pet['name'] ?? 'Pet',
                    style: TextStyle(
                      color: isSelected ? AppColors.primary : Colors.white,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  IconData _getPetIcon(String? species) {
    if (species == null) return Icons.pets;

    switch (species.toLowerCase()) {
      case 'dog':
        return Icons.pets;
      case 'cat':
        return Icons.pets;
      case 'bird':
        return Icons.flutter_dash;
      case 'fish':
        return Icons.water;
      case 'rabbit':
        return Icons.pets;
      default:
        return Icons.pets;
    }
  }

  Widget _buildActivityRecommendations() {
    if (_pets.isEmpty) return const SizedBox.shrink();

    final pet = _pets[_selectedPetIndex];
    final activities = _petActivities[pet['id']] ?? [];

    if (activities.isEmpty) {
      return const Center(
        child: Text(
          'No activity recommendations available',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: activities.length,
      itemBuilder: (context, index) {
        final activity = activities[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          color: const Color.fromARGB(255, 37, 45, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        activity['icon'] ?? Icons.pets,
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            activity['name'],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              _buildInfoChip(
                                Icons.timer_outlined,
                                activity['duration'],
                              ),
                              const SizedBox(width: 8),
                              _buildInfoChip(
                                Icons.repeat,
                                activity['frequency'],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _getIntensityColor(
                          activity['intensity'],
                        ).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        activity['intensity'],
                        style: TextStyle(
                          color: _getIntensityColor(activity['intensity']),
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  activity['description'],
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.grey[400]),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(color: Colors.grey[400], fontSize: 12)),
        ],
      ),
    );
  }

  Color _getIntensityColor(String? intensity) {
    if (intensity == null) return Colors.blue;

    if (intensity.toLowerCase().contains('high')) {
      return Colors.orange;
    } else if (intensity.toLowerCase().contains('moderate')) {
      return Colors.blue;
    } else {
      return Colors.green;
    }
  }

  Widget _buildBehaviorNotes() {
    if (_pets.isEmpty) return const SizedBox.shrink();

    final pet = _pets[_selectedPetIndex];
    final notes = _behaviorNotes[pet['id']] ?? [];

    if (notes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notes, size: 60, color: Colors.grey[600]),
            const SizedBox(height: 16),
            const Text(
              'No behavior notes yet',
              style: TextStyle(fontSize: 18, color: Colors.white70),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tap the + button to add your first note',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    notes.sort((a, b) {
      final dateA =
          a['created_at'] != null
              ? DateTime.parse(a['created_at'].toString())
              : DateTime.now();
      final dateB =
          b['created_at'] != null
              ? DateTime.parse(b['created_at'].toString())
              : DateTime.now();
      return dateB.compareTo(dateA);
    });

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: notes.length,
      itemBuilder: (context, index) {
        final note = notes[index];
        final date =
            note['created_at'] != null
                ? DateTime.parse(note['created_at'].toString())
                : DateTime.now();
        final formattedDate = DateFormat('MMM dd, yyyy').format(date);

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          color: const Color.fromARGB(255, 37, 45, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      formattedDate,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _getMoodColor(note['mood']).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getMoodIcon(note['mood']),
                            size: 14,
                            color: _getMoodColor(note['mood']),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            note['mood'],
                            style: TextStyle(
                              color: _getMoodColor(note['mood']),
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  note['note'],
                  style: const TextStyle(color: Colors.white, height: 1.5),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.edit,
                        size: 18,
                        color: Colors.white54,
                      ),
                      onPressed: () => _editBehaviorNote(note),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'Edit note',
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      icon: const Icon(
                        Icons.delete,
                        size: 18,
                        color: Colors.white54,
                      ),
                      onPressed: () => _deleteBehaviorNote(note),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'Delete note',
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getMoodColor(String mood) {
    switch (mood.toLowerCase()) {
      case 'happy':
        return Colors.green;
      case 'tired':
        return Colors.orange;
      case 'sad':
        return Colors.blue;
      case 'anxious':
        return Colors.amber;
      case 'angry':
        return Colors.red;
      case 'attentive':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getMoodIcon(String mood) {
    switch (mood.toLowerCase()) {
      case 'happy':
        return Icons.sentiment_very_satisfied;
      case 'tired':
        return Icons.sentiment_neutral;
      case 'sad':
        return Icons.sentiment_dissatisfied;
      case 'anxious':
        return Icons.sentiment_very_dissatisfied;
      case 'angry':
        return Icons.mood_bad;
      case 'attentive':
        return Icons.visibility;
      default:
        return Icons.sentiment_neutral;
    }
  }

  void _showAddBehaviorNoteDialog() {
    if (_pets.isEmpty) return;

    final TextEditingController noteController = TextEditingController();
    String selectedMood = 'Happy';

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                backgroundColor: const Color.fromARGB(255, 37, 45, 50),
                title: const Text(
                  'Add Behavior Note',
                  style: TextStyle(color: Colors.white),
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pet',
                        style: TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _pets[_selectedPetIndex]['name'] ?? 'Pet',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Mood',
                        style: TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildMoodOption('Happy', selectedMood, (mood) {
                            setState(() => selectedMood = mood);
                          }),
                          _buildMoodOption('Tired', selectedMood, (mood) {
                            setState(() => selectedMood = mood);
                          }),
                          _buildMoodOption('Sad', selectedMood, (mood) {
                            setState(() => selectedMood = mood);
                          }),
                          _buildMoodOption('Anxious', selectedMood, (mood) {
                            setState(() => selectedMood = mood);
                          }),
                          _buildMoodOption('Angry', selectedMood, (mood) {
                            setState(() => selectedMood = mood);
                          }),
                          _buildMoodOption('Attentive', selectedMood, (mood) {
                            setState(() => selectedMood = mood);
                          }),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Note',
                        style: TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: noteController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: 'Describe your pet\'s behavior...',
                          hintStyle: TextStyle(color: Colors.grey[600]),
                          filled: true,
                          fillColor: Colors.grey.withOpacity(0.2),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      if (noteController.text.trim().isNotEmpty) {
                        final pet = _pets[_selectedPetIndex];

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Saving note...'),
                            duration: Duration(milliseconds: 500),
                          ),
                        );

                        try {
                          final newNote = await _behaviorNoteService
                              .addBehaviorNote(
                                petId: pet['id'],
                                note: noteController.text.trim(),
                                mood: selectedMood,
                              );

                          if (_behaviorNotes[pet['id']] == null) {
                            _behaviorNotes[pet['id']] = [];
                          }
                          _behaviorNotes[pet['id']]!.add(newNote);

                          Navigator.pop(context);

                          this.setState(() {});

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Behavior note added successfully'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error saving note: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                    ),
                    child: const Text('Save'),
                  ),
                ],
              );
            },
          ),
    );
  }

  Widget _buildMoodOption(
    String mood,
    String selectedMood,
    Function(String) onSelect,
  ) {
    final isSelected = mood == selectedMood;

    return GestureDetector(
      onTap: () => onSelect(mood),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? _getMoodColor(mood).withOpacity(0.2)
                  : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? _getMoodColor(mood) : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getMoodIcon(mood),
              size: 16,
              color: isSelected ? _getMoodColor(mood) : Colors.grey,
            ),
            const SizedBox(width: 4),
            Text(
              mood,
              style: TextStyle(
                color: isSelected ? _getMoodColor(mood) : Colors.grey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _editBehaviorNote(Map<String, dynamic> note) {}

  void _deleteBehaviorNote(Map<String, dynamic> note) {
    showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            backgroundColor: const Color.fromARGB(255, 37, 45, 50),
            title: const Text(
              'Delete Note?',
              style: TextStyle(color: Colors.white),
            ),
            content: const Text(
              'Are you sure you want to delete this behavior note? This action cannot be undone.',
              style: TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  final scaffoldContext = context;

                  Navigator.pop(dialogContext);

                  if (mounted) {
                    ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                      const SnackBar(
                        content: Text('Deleting note...'),
                        duration: Duration(milliseconds: 500),
                      ),
                    );
                  }

                  try {
                    await _behaviorNoteService.deleteBehaviorNote(note['id']);

                    if (mounted) {
                      setState(() {
                        final pet = _pets[_selectedPetIndex];
                        _behaviorNotes[pet['id']]?.remove(note);
                      });

                      ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                        const SnackBar(
                          content: Text('Note deleted successfully'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                        SnackBar(
                          content: Text('Error deleting note: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }
}
