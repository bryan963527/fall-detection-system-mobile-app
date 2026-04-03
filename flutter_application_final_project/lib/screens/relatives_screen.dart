import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../constants/app_colors.dart';
import '../models/relative_model.dart';
import '../widgets/top_bar.dart';
import '../widgets/sidebar.dart';
import 'add_edit_relative_screen.dart';


class RelativesScreen extends StatefulWidget {
  const RelativesScreen({Key? key}) : super(key: key);

  @override
  State<RelativesScreen> createState() => _RelativesScreenState();
}

class _RelativesScreenState extends State<RelativesScreen> {
  int _selectedMenuIndex = 2; // Relatives is at index 2

  List<MapEntry<String, RelativeModel>> relatives = [];
  bool _isLoading = true;
  String? _errorMessage;
  User? _currentUser;
  late DatabaseReference _relativesRef;
  StreamSubscription<DatabaseEvent>? _relativesSubscription;

  @override
  void initState() {
    super.initState();
    _initializeRelatives();
  }

  void _initializeRelatives() {
    _currentUser = FirebaseAuth.instance.currentUser;

    if (_currentUser == null) {
      setState(() {
        _errorMessage = 'Not logged in';
        _isLoading = false;
      });
      return;
    }

    print("DEBUG: Current user UID: ${_currentUser!.uid}");
    _relativesRef = FirebaseDatabase.instance
        .ref('users/${_currentUser!.uid}/relatives');
    _loadRelativesRealtime();
  }

 @override
void dispose() {
  _relativesSubscription?.cancel();
  super.dispose();
}

  void _loadRelativesRealtime() {
    try {
      _relativesSubscription = _relativesRef.onValue.listen(
        (DatabaseEvent event) {
          try {
            // Check if snapshot exists and has data
            if (event.snapshot.exists && event.snapshot.value != null) {
              final snapshotValue = event.snapshot.value;

              // Verify the data is a Map before casting
              if (snapshotValue is! Map) {
                if (mounted) {
                  setState(() {
                    _errorMessage = 'Invalid data format from Firebase';
                    _isLoading = false;
                  });
                }
                return;
              }

              final data = Map<String, dynamic>.from(snapshotValue as Map);
              final relativesList = <MapEntry<String, RelativeModel>>[];

              data.forEach((relativeId, relativeData) {
                if (relativeData is Map && relativeId is String) {
                  try {
                    final relative = RelativeModel.fromJson(relativeData as Map<dynamic, dynamic>);
                    relativesList.add(MapEntry(relativeId, relative));
                  } catch (e) {
                    debugPrint('Error processing relative $relativeId: $e');
                  }
                }
              });

              if (mounted) {
                setState(() {
                  relatives = relativesList;
                  _isLoading = false;
                  _errorMessage = null;
                });
              }
              print("DEBUG: Loaded ${relativesList.length} relatives");
            } else {
              // No relatives found
              if (mounted) {
                setState(() {
                  relatives = [];
                  _isLoading = false;
                  _errorMessage = null;
                });
              }
              print("DEBUG: No relatives found in database");
            }
          } catch (e) {
            debugPrint('Error parsing Firebase snapshot: $e');
            if (mounted) {
              setState(() {
                _errorMessage = 'Error loading relatives: $e';
                _isLoading = false;
              });
            }
          }
        },
        onError: (Object error) {
          debugPrint('Firebase stream error: $error');
          if (mounted) {
            setState(() {
              _errorMessage = 'Connection error: Unable to load relatives';
              _isLoading = false;
            });
          }
        },
        cancelOnError: false,
      );
    } catch (e) {
      debugPrint('Error initializing Firebase listener: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to initialize data listener';
          _isLoading = false;
        });
      }
    }
  }

  void _onMenuItemSelected(int index) {
    setState(() {
      _selectedMenuIndex = index;
    });

    switch (index) {
      case 0: // Dashboard
        Navigator.of(context).pushReplacementNamed('/');
        break;
      case 1: // History
        Navigator.of(context).pushReplacementNamed('/history');
        break;
      case 2: // Relatives - Already on relatives screen
        break;
      case 3: // Profile
        Navigator.of(context).pushReplacementNamed('/profile');
        break;
    }
  }



  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 800;

    if (isMobile) {
      return _buildMobileLayout();
    } else {
      return _buildDesktopLayout();
    }
  }

  Widget _buildMobileLayout() {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: const TopBar(),
      drawer: Drawer(
        child: Sidebar(
          selectedIndex: _selectedMenuIndex,
          onItemSelected: _onMenuItemSelected,
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddRelativeModal(context),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            _buildContactsGrid(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddRelativeModal(context),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Row(
        children: [
          // Sidebar
          Sidebar(
            selectedIndex: _selectedMenuIndex,
            onItemSelected: _onMenuItemSelected,
          ),
          // Main Content
          Expanded(
            child: Column(
              children: [
                const TopBar(),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 20),
                        _buildContactsGrid(),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'My Relatives',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Manage your family members and emergency contacts',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textMedium,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap a relative to edit or delete',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textLight,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactsGrid() {
    if (_isLoading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading relatives...'),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                color: AppColors.dangerRed,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (relatives.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.family_restroom_outlined,
                color: AppColors.textLight,
                size: 64,
              ),
              const SizedBox(height: 16),
              const Text(
                'No relatives added yet',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMedium,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tap the + button to add your first relative',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textLight,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          int columns = constraints.maxWidth > 1200
              ? 3
              : constraints.maxWidth > 600
                  ? 2
                  : 1;

          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.0,
            ),
            itemCount: relatives.length,
            itemBuilder: (context, index) {
              final MapEntry<String, RelativeModel> entry = relatives[index];
              return _buildRelativeCard(entry.key, entry.value);
            },
          );
        },
      ),
    );
  }

  String _getInitials(String name) {
    return name
        .split(' ')
        .map((n) => n[0])
        .take(2)
        .join()
        .toUpperCase();
  }

  Widget _buildRelativeCard(String relativeId, RelativeModel relative) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with avatar, name, and action buttons
          Row(
            children: [
              // Avatar with initials
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    _getInitials(relative.name),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Name and Relationship
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      relative.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      relative.relationship,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.safeGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              // Edit button
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddEditRelativeScreen(
                        relative: relative.copyWith(id: relativeId),
                        isEdit: true,
                      ),
                    ),
                  );
                },
                child: Icon(
                  Icons.edit,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Age
          Row(
            children: [
              Icon(
                Icons.cake_outlined,
                size: 14,
                color: AppColors.textMedium,
              ),
              const SizedBox(width: 8),
              Text(
                '${relative.age} years old',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Address
          Row(
            children: [
              Icon(
                Icons.location_on,
                size: 14,
                color: AppColors.textMedium,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  relative.address,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMedium,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Contact Number
          Row(
            children: [
              Icon(
                Icons.phone_outlined,
                size: 14,
                color: AppColors.textMedium,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  relative.contact,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMedium,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Delete button
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.dangerRed.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: GestureDetector(
              onTap: () => _showDeleteDialog(relativeId, relative.name),
              child: Center(
                child: Text(
                  'Delete',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.dangerRed,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(String relativeId, String relativeName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Relative'),
        content: Text('Are you sure you want to delete $relativeName?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteRelative(relativeId);
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.dangerRed),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteRelative(String relativeId) async {
    try {
      print("DEBUG: Deleting relative $relativeId");
      await _relativesRef.child(relativeId).remove();
      print("DEBUG: Relative deleted successfully");

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Relative deleted!'),
            backgroundColor: AppColors.dangerRed,
          ),
        );
      }
    } catch (e) {
      print("ERROR: Failed to delete relative - $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting relative: $e'),
            backgroundColor: AppColors.dangerRed,
          ),
        );
      }
    }
  }

  void _showAddRelativeModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddRelativeModalContent(),
    );
  }
}

class _AddRelativeModalContent extends StatefulWidget {
  const _AddRelativeModalContent();

  @override
  State<_AddRelativeModalContent> createState() =>
      _AddRelativeModalContentState();
}

class _AddRelativeModalContentState extends State<_AddRelativeModalContent>
    with SingleTickerProviderStateMixin {
  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late TextEditingController _contactController;
  late TextEditingController _addressController;

  String _selectedRelationship = 'Other Family Member';
  final List<String> _relationships = [
    'Parent',
    'Sibling',
    'Child',
    'Spouse',
    'Grandparent',
    'Grandchild',
    'Aunt/Uncle',
    'Cousin',
    'Friend',
    'Other Family Member',
  ];

  bool _isLoading = false;
  late AnimationController _animationController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _ageController = TextEditingController();
    _contactController = TextEditingController();
    _addressController = TextEditingController();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _contactController.dispose();
    _addressController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _saveRelative() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User not authenticated'),
            backgroundColor: AppColors.dangerRed,
          ),
        );
        return;
      }

      final relativesRef = FirebaseDatabase.instance
          .ref('users/${user.uid}/relatives');

      final age = int.tryParse(_ageController.text) ?? 0;

      print("DEBUG: Creating new relative");
      final newRelativeRef = relativesRef.push();
      await newRelativeRef.set({
        'name': _nameController.text.trim(),
        'age': age,
        'relationship': _selectedRelationship,
        'contact': _contactController.text.trim(),
        'address': _addressController.text.trim(),
        'createdAt': DateTime.now().toIso8601String(),
      });
      print("DEBUG: Relative created successfully with ID: ${newRelativeRef.key}");

      if (mounted) {
        // Show success snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Relative added successfully!'),
            backgroundColor: AppColors.safeGreen,
            duration: const Duration(seconds: 2),
          ),
        );

        // Close modal with slight delay for visual feedback
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) Navigator.pop(context);
        });
      }
    } catch (e) {
      print("ERROR: Failed to save relative - $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving relative: $e'),
            backgroundColor: AppColors.dangerRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;
    final maxModalHeight = screenHeight * 0.9;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, (1 - _animationController.value) * 100),
          child: Opacity(
            opacity: _animationController.value,
            child: child,
          ),
        );
      },
      child: Container(
        constraints: BoxConstraints(maxHeight: maxModalHeight),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 16,
            bottom: 20 + keyboardHeight,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Draggable indicator
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Header
              const Text(
                'Add Relative',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Add a family member or emergency contact',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textMedium,
                ),
              ),
              const SizedBox(height: 24),

              // Form
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Name Field
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: const Icon(Icons.person_outline),
                        filled: true,
                        fillColor: Colors.grey[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                      validator: (value) =>
                          value!.isEmpty ? 'Name is required' : null,
                    ),
                    const SizedBox(height: 16),

                    // Age and Relationship Row
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _ageController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Age',
                              prefixIcon: const Icon(Icons.cake_outlined),
                              filled: true,
                              fillColor: Colors.grey[50],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                            ),
                            validator: (value) {
                              if (value!.isEmpty) return 'Required';
                              final age = int.tryParse(value);
                              if (age == null || age <= 0) return 'Invalid';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedRelationship,
                            decoration: InputDecoration(
                              labelText: 'Relationship',
                              prefixIcon: const Icon(
                                Icons.family_restroom_outlined,
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                            ),
                            items: _relationships
                                .map((rel) => DropdownMenuItem(
                                      value: rel,
                                      child: Text(rel),
                                    ))
                                .toList(),
                            onChanged: (newValue) {
                              setState(() =>
                                  _selectedRelationship =
                                      newValue ?? 'Other Family Member');
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Contact Field
                    TextFormField(
                      controller: _contactController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Contact Number',
                        prefixIcon: const Icon(Icons.phone_outlined),
                        filled: true,
                        fillColor: Colors.grey[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                      validator: (value) =>
                          value!.isEmpty ? 'Contact number is required' : null,
                    ),
                    const SizedBox(height: 16),

                    // Address Field
                    TextFormField(
                      controller: _addressController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Address',
                        prefixIcon: const Icon(Icons.location_on_outlined),
                        filled: true,
                        fillColor: Colors.grey[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        alignLabelWithHint: true,
                      ),
                      validator: (value) =>
                          value!.isEmpty ? 'Address is required' : null,
                    ),
                    const SizedBox(height: 24),

                    // Submit Button
                    ElevatedButton(
                      onPressed: _isLoading ? null : _saveRelative,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.safeGreen,
                        disabledBackgroundColor: Colors.grey[300],
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: _isLoading
                          ? SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white.withOpacity(0.8),
                                ),
                              ),
                            )
                          : const Text(
                              'Add Relative',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                    const SizedBox(height: 8),

                    // Cancel Button
                    TextButton(
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 16,
                          color: _isLoading ? Colors.grey : AppColors.textMedium,
                        ),
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
  }

    }