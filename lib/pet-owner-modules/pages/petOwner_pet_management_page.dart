import 'package:flutter/material.dart';
import 'package:petpal/pet-owner-modules/widgets/add_pet_form.dart';
import 'package:petpal/pet-owner-modules/widgets/edit_pet_form.dart';
import 'package:petpal/services/auth_service.dart';
import 'package:petpal/services/pet_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PetManagementPage extends StatefulWidget {
  const PetManagementPage({super.key});

  @override
  _PetManagementPageState createState() => _PetManagementPageState();
}

class _PetManagementPageState extends State<PetManagementPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final PetService _petService = PetService();
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> pets = [];
  bool isLoading = true;
  String? ownerId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _getCurrentUser();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentUser() async {
    final user = _supabase.auth.currentUser;

    if (user != null) {
      setState(() {
        ownerId = user.id;
      });
      _loadPets();
    } else {
      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You need to be logged in to manage pets'),
          backgroundColor: Colors.red,
        ),
      );

      Future.delayed(const Duration(seconds: 2), () {
        Navigator.of(context).pop();
      });
    }
  }

  Future<void> _loadPets() async {
    if (ownerId == null) return;

    setState(() {
      isLoading = true;
    });

    try {
      List<Map<String, dynamic>> petList = await _petService.getPetsByOwner(
        ownerId!,
      );
      if (mounted) {
        setState(() {
          pets = petList;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _refreshPets() {
    _loadPets();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 37, 45, 50),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          "Pet Management",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color.fromARGB(255, 44, 59, 70),
        bottom: TabBar(
          labelColor: Colors.white,
          indicatorColor: Colors.white,
          unselectedLabelColor: Colors.grey,
          controller: _tabController,
          tabs: const [Tab(text: "My Pets"), Tab(text: "Add Pet")],
        ),
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : ownerId == null
              ? const Center(
                child: Text(
                  "Authentication error",
                  style: TextStyle(color: Colors.white),
                ),
              )
              : TabBarView(
                controller: _tabController,
                children: [
                  EditPetForm(
                    pets: pets,
                    onPetUpdated: _refreshPets,
                    onPetDeleted: _refreshPets,
                  ),
                  AddPetForm(ownerId: ownerId!, onPetAdded: _refreshPets),
                ],
              ),
    );
  }
}
