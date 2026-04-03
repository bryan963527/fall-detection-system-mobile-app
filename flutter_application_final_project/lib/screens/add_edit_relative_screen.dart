import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../constants/app_colors.dart';
import '../models/relative_model.dart';

class AddEditRelativeScreen extends StatefulWidget {
  final RelativeModel? relative;
  final bool isEdit;

  const AddEditRelativeScreen({
    Key? key,
    this.relative,
    this.isEdit = false,
  }) : super(key: key);

  @override
  State<AddEditRelativeScreen> createState() => _AddEditRelativeScreenState();
}

class _AddEditRelativeScreenState extends State<AddEditRelativeScreen> {
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
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.relative?.name ?? '');
    _ageController = TextEditingController(text: widget.relative?.age.toString() ?? '');
    _contactController = TextEditingController(text: widget.relative?.contact ?? '');
    _addressController = TextEditingController(text: widget.relative?.address ?? '');
    _selectedRelationship = widget.relative?.relationship ?? 'Other Family Member';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _contactController.dispose();
    _addressController.dispose();
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

      if (widget.isEdit && widget.relative?.id != null) {
        // Update existing relative
        print("DEBUG: Updating relative ${widget.relative!.id}");
        await relativesRef.child(widget.relative!.id!).update({
          'name': _nameController.text.trim(),
          'age': age,
          'relationship': _selectedRelationship,
          'contact': _contactController.text.trim(),
          'address': _addressController.text.trim(),
        });
        print("DEBUG: Relative updated successfully");
      } else {
        // Create new relative
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
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isEdit ? 'Relative updated!' : 'Relative added!'),
            backgroundColor: AppColors.safeGreen,
          ),
        );
        Navigator.pop(context);
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
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: Text(
          widget.isEdit ? 'Edit Relative' : 'Add Relative',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
            padding: const EdgeInsets.all(24),
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
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Relative Information',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Name Field
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(),
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
                          decoration: const InputDecoration(
                            labelText: 'Age',
                            prefixIcon: Icon(Icons.cake_outlined),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value!.isEmpty) return 'Age is required';
                            final age = int.tryParse(value);
                            if (age == null || age <= 0)
                              return 'Invalid age';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedRelationship,
                          decoration: const InputDecoration(
                            labelText: 'Relationship',
                            prefixIcon: Icon(Icons.family_restroom_outlined),
                            border: OutlineInputBorder(),
                          ),
                          items: _relationships
                              .map((rel) => DropdownMenuItem(
                                    value: rel,
                                    child: Text(rel),
                                  ))
                              .toList(),
                          onChanged: (newValue) {
                            setState(() =>
                                _selectedRelationship = newValue ?? 'Other Family Member');
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
                    decoration: const InputDecoration(
                      labelText: 'Contact Number',
                      prefixIcon: Icon(Icons.phone_outlined),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        value!.isEmpty ? 'Contact number is required' : null,
                  ),
                  const SizedBox(height: 16),

                  // Address Field
                  TextFormField(
                    controller: _addressController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Address',
                      prefixIcon: Icon(Icons.location_on_outlined),
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                    validator: (value) =>
                        value!.isEmpty ? 'Address is required' : null,
                  ),
                  const SizedBox(height: 24),

                  // Save Button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _saveRelative,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.safeGreen,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            widget.isEdit ? 'Update Relative' : 'Add Relative',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                  if (widget.isEdit) ...[
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _isLoading ? null : () => _showDeleteDialog(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.dangerRed,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        'Delete Relative',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Relative'),
        content: const Text('Are you sure you want to delete this relative?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteRelative();
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

  Future<void> _deleteRelative() async {
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final relativesRef = FirebaseDatabase.instance
          .ref('users/${user.uid}/relatives');

      print("DEBUG: Deleting relative ${widget.relative!.id}");
      await relativesRef.child(widget.relative!.id!).remove();
      print("DEBUG: Relative deleted successfully");

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Relative deleted!'),
            backgroundColor: AppColors.dangerRed,
          ),
        );
        Navigator.pop(context);
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
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
