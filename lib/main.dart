import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Org Hub',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const ProfileSetupScreen(),
    );
  }
}

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  final _nameController = TextEditingController();
  final _courseController = TextEditingController();
  final _roleController = TextEditingController();
  final _contactController = TextEditingController();

  File? _profilePhoto;
  bool _isPickingPhoto = false;

  // Design Question 1:
  // If camera permission is denied once, request permission again
  // when needed. If it is permanently denied, guide the member
  // to the phone Settings. Gallery selection uses the system picker.

  // Design Question 2:
  // Track readiness using the selected photo and the current field
  // values. Recheck whenever a field changes and validate again
  // before opening the ID card screen.

  // Design Question 3:
  // Pass the photo File and entered information to the ID screen.
  // The picked photo is not permanently saved by this code, so
  // it may not be available after the app is closed or restarted.

  bool get _readyToGenerateCard {
    final name = _nameController.text.trim();
    final course = _courseController.text.trim();
    final role = _roleController.text.trim();
    final contact = _contactController.text.trim();

    return _profilePhoto != null &&
        name.isNotEmpty &&
        course.isNotEmpty &&
        role.isNotEmpty &&
        RegExp(r'^09\d{9}$').hasMatch(contact);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _courseController.dispose();
    _roleController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  Future<void> _showPhotoOptions() async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Wrap(
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 18, 20, 8),
                child: Text(
                  'Choose Profile Photo',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _pickProfilePhoto(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _pickProfilePhoto(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickProfilePhoto(ImageSource source) async {
    if (_isPickingPhoto) return;

    setState(() {
      _isPickingPhoto = true;
    });

    try {
      if (source == ImageSource.camera) {
        var status = await Permission.camera.status;

        if (status.isPermanentlyDenied || status.isRestricted) {
          if (!mounted) return;
          _showCameraSettingsMessage();
          return;
        }

        if (!status.isGranted) {
          status = await Permission.camera.request();
        }

        if (!status.isGranted) {
          if (!mounted) return;

          if (status.isPermanentlyDenied || status.isRestricted) {
            _showCameraSettingsMessage();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Camera permission was denied. '
                  'You can try again or choose a photo from Gallery.',
                ),
              ),
            );
          }
          return;
        }
      }

      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 80,
      );

      if (!mounted) return;

      if (pickedFile != null) {
        setState(() {
          _profilePhoto = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to select the photo. Please try again.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isPickingPhoto = false;
        });
      }
    }
  }

  void _showCameraSettingsMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Camera access is blocked. Enable it in Settings, '
          'or choose a photo from Gallery.',
        ),
        action: SnackBarAction(
          label: 'Settings',
          onPressed: () {
            openAppSettings();
          },
        ),
      ),
    );
  }

  void _generateCard() {
    FocusScope.of(context).unfocus();

    final isValid = _formKey.currentState?.validate() ?? false;

    if (_profilePhoto == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a profile photo first.')),
      );
      return;
    }

    if (!isValid) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => IdCardScreen(
          photo: _profilePhoto!,
          name: _nameController.text.trim(),
          course: _courseController.text.trim(),
          role: _roleController.text.trim(),
          contact: _contactController.text.trim(),
        ),
      ),
    );
  }

  Widget _buildField({
    required String label,
    required String hint,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        textCapitalization: TextCapitalization.words,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        ),
        validator:
            validator ??
            (value) {
              if (value == null || value.trim().isEmpty) {
                return 'This field is required';
              }
              return null;
            },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Org Hub'), centerTitle: true),
      body: SafeArea(
        child: Form(
          key: _formKey,
          onChanged: () {
            setState(() {});
          },
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text(
                'Set Up Your Profile',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 22),

              Center(
                child: InkWell(
                  onTap: _isPickingPhoto ? null : _showPhotoOptions,
                  customBorder: const CircleBorder(),
                  child: CircleAvatar(
                    radius: 58,
                    backgroundColor: Colors.indigo.shade100,
                    backgroundImage: _profilePhoto != null
                        ? FileImage(_profilePhoto!)
                        : null,
                    child: _isPickingPhoto
                        ? const CircularProgressIndicator()
                        : _profilePhoto == null
                        ? const Icon(
                            Icons.add_a_photo,
                            size: 36,
                            color: Colors.indigo,
                          )
                        : null,
                  ),
                ),
              ),

              const SizedBox(height: 12),
              const Center(
                child: Text(
                  'Tap the photo to use Camera or Gallery',
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),

              _buildField(
                label: 'Full Name',
                hint: 'Enter your full name',
                controller: _nameController,
              ),

              _buildField(
                label: 'Course and Year',
                hint: 'e.g. BSCS 4',
                controller: _courseController,
              ),

              _buildField(
                label: 'Organization Role',
                hint: 'e.g. Organization Head',
                controller: _roleController,
              ),

              _buildField(
                label: 'Contact Number',
                hint: 'e.g. 09171234567',
                controller: _contactController,
                keyboardType: TextInputType.phone,
                validator: (value) {
                  final number = value?.trim() ?? '';

                  if (!RegExp(r'^09\d{9}$').hasMatch(number)) {
                    return 'Enter a valid 11-digit number starting with 09';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 4),

              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _readyToGenerateCard ? _generateCard : null,
                  child: const Text(
                    'Generate ID Card',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              const SizedBox(height: 16),
              const Text(
                'All fields and a profile photo are required.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class IdCardScreen extends StatelessWidget {
  final File photo;
  final String name;
  final String course;
  final String role;
  final String contact;

  const IdCardScreen({
    super.key,
    required this.photo,
    required this.name,
    required this.course,
    required this.role,
    required this.contact,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Digital Membership ID'),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Card(
            elevation: 5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'STUDENT ORGANIZATION',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),

                  const SizedBox(height: 24),

                  CircleAvatar(radius: 58, backgroundImage: FileImage(photo)),

                  const SizedBox(height: 18),

                  Text(
                    name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    role,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 17),
                  ),

                  const Divider(height: 35),

                  _infoRow('Course and Year', course),
                  _infoRow('Contact', contact),

                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Text(label, style: const TextStyle(fontSize: 14)),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 4,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
