import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../models/contact_model.dart';
import '../widgets/top_bar.dart';
import '../widgets/sidebar.dart';
import 'profile_screen.dart';

class RelativesScreen extends StatefulWidget {
  const RelativesScreen({super.key});

  @override
  State<RelativesScreen> createState() => _RelativesScreenState();
}

class _RelativesScreenState extends State<RelativesScreen> {
  int _selectedMenuIndex = 2; // Relatives is at index 2

  List<Contact> contacts = [
    const Contact(
      id: '1',
      name: 'Sarah Johnson',
      relationship: 'Daughter',
      phoneNumber: '+1 (555) 123-4567',
      emergencyNotificationsEnabled: true,
    ),
    const Contact(
      id: '2',
      name: 'Michael Smith',
      relationship: 'Son',
      phoneNumber: '+1 (555) 987-6543',
      emergencyNotificationsEnabled: true,
    ),
    const Contact(
      id: '3',
      name: 'Dr. Emily White',
      relationship: 'Doctor',
      phoneNumber: '+1 (555) 555-5555',
      emergencyNotificationsEnabled: false,
    ),
  ];

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
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const ProfileScreen()),
        );
        break;
    }
  }

  void _addContact() {
    final nameController = TextEditingController();
    final relationController = TextEditingController();
    final phoneController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Contact'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Full Name'),
              ),
              TextField(
                controller: relationController,
                decoration: const InputDecoration(
                  labelText: 'Relationship (e.g. Son)',
                ),
              ),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'Phone Number'),
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () {
              if (nameController.text.isNotEmpty &&
                  phoneController.text.isNotEmpty) {
                setState(() {
                  contacts.add(
                    Contact(
                      id: DateTime.now().toString(), // Quick unique ID
                      name: nameController.text,
                      relationship: relationController.text,
                      phoneNumber: phoneController.text,
                      emergencyNotificationsEnabled: true,
                    ),
                  );
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Contact Added Successfully')),
                );
              }
            },
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _toggleNotification(int index) {
    setState(() {
      contacts[index] = contacts[index].copyWith(
        emergencyNotificationsEnabled:
            !contacts[index].emergencyNotificationsEnabled,
      );
    });
  }

  void _deleteContact(int index) {
    setState(() {
      contacts.removeAt(index);
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Contact deleted')));
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Emergency Contacts',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Manage who gets notified in case of an emergency.',
                style: TextStyle(fontSize: 14, color: AppColors.textMedium),
              ),
            ],
          ),
          GestureDetector(
            onTap: _addContact,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  const Icon(Icons.add, color: Colors.white, size: 18),
                  const SizedBox(width: 6),
                  const Text(
                    'Add Contact',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactsGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Determine number of columns based on screen width
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
              childAspectRatio: 1.1,
            ),
            itemCount: contacts.length,
            itemBuilder: (context, index) {
              return _buildContactCard(contacts[index], index);
            },
          );
        },
      ),
    );
  }

  Widget _buildContactCard(Contact contact, int index) {
    return GestureDetector(
      onLongPress: () => _showContactOptions(contact, index),
      child: Container(
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
            // Header with avatar and name
            Row(
              children: [
                // Avatar
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.person, color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: 12),
                // Name and Relationship
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        contact.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        contact.relationship,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Phone number
            Row(
              children: [
                Icon(Icons.phone, size: 16, color: AppColors.textMedium),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    contact.phoneNumber,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMedium,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Emergency Notifications Toggle
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.favorite_border,
                      size: 16,
                      color: AppColors.textMedium,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Emergency Notifications',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textMedium,
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () => _toggleNotification(index),
                  child: Switch(
                    value: contact.emergencyNotificationsEnabled,
                    onChanged: (_) => _toggleNotification(index),
                    activeThumbColor: AppColors.safeGreen,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showContactOptions(Contact contact, int index) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit Contact'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Edit functionality coming soon'),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: AppColors.dangerRed),
                title: const Text(
                  'Delete Contact',
                  style: TextStyle(color: AppColors.dangerRed),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _deleteContact(index);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
