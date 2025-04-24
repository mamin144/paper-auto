import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:paperauto/screens/firstscreen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:paperauto/services/firebase_options.dart';
import 'package:paperauto/services/project_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const CreateProject());
}

class CreateProject extends StatelessWidget {
  const CreateProject({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Paper Automation',
      theme: ThemeData(
        primaryColor: const Color(0xFF1A237E),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A237E),
          primary: const Color(0xFF1A237E),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF1A237E), width: 2),
          ),
        ),
      ),
      home: const RegistrationScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  int _currentStep = 0;
  final int _totalSteps = 3;

  // Add variable to store the selected profile image
  File? _profileImage;
  // Add variable to store the selected document image
  File? _documentImage;

  // Image picker instance
  final ImagePicker _picker = ImagePicker();

  // Form controllers
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _displayNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _projectNameController = TextEditingController();
  final TextEditingController _projectAreaController = TextEditingController();
  final TextEditingController _projectTypeController = TextEditingController();
  final TextEditingController _villageController = TextEditingController();
  final TextEditingController _buildingController = TextEditingController();
  final TextEditingController _mallsController = TextEditingController();
  final TextEditingController _parkingController = TextEditingController();

  // Project service instance
  final ProjectService _projectService = ProjectService();

  void _goToNextStep() {
    if (_currentStep < _totalSteps - 1) {
      setState(() {
        _currentStep++;
      });
    }
  }

  void _goToPreviousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  // Method to pick profile image
  Future<void> _pickProfileImage() async {
    final XFile? pickedImage = await _picker.pickImage(
      source: ImageSource.gallery,
    );

    if (pickedImage != null) {
      setState(() {
        _profileImage = File(pickedImage.path);
      });
    }
  }

  // Method to pick document image
  Future<void> _pickDocumentImage() async {
    final XFile? pickedImage = await _picker.pickImage(
      source: ImageSource.gallery,
    );

    if (pickedImage != null) {
      setState(() {
        _documentImage = File(pickedImage.path);
      });
    }
  }

  // Method to save data to Firebase
  Future<void> _saveProjectData() async {
    try {
      // Prepare the data
      final personalInfo = {
        'firstName': _firstNameController.text,
        'lastName': _lastNameController.text,
        'displayName': _displayNameController.text,
        'email': _emailController.text,
        'phone': _phoneController.text,
      };

      final projectDetails = {
        'projectName': _projectNameController.text,
        'projectArea': _projectAreaController.text,
        'projectType': _projectTypeController.text,
      };

      final projectDescription = {
        'village': _villageController.text,
        'building': _buildingController.text,
        'malls': _mallsController.text,
        'parking': _parkingController.text,
      };

      // Save project using the service
      await _projectService.createProject(
        personalInfo: personalInfo,
        projectDetails: projectDetails,
        projectDescription: projectDescription,
        profileImage: _profileImage,
        documentImage: _documentImage,
      );

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Project created successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate to next screen
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const Firstscreen()),
      );
    } catch (e) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating project: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    // Clean up controllers
    _firstNameController.dispose();
    _lastNameController.dispose();
    _displayNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _projectNameController.dispose();
    _projectAreaController.dispose();
    _projectTypeController.dispose();
    _villageController.dispose();
    _buildingController.dispose();
    _mallsController.dispose();
    _parkingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A237E),
        title: const Text(
          'Create New Project',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _currentStep > 0 ? _goToPreviousStep : null,
        ),
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1A237E).withOpacity(0.9),
              const Color(0xFF3949AB).withOpacity(0.9),
            ],
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _pickProfileImage,
              child: Column(
                children: [
                  const Text(
                    'Upload Project Image',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child:
                        _profileImage != null
                            ? ClipOval(
                              child: Image.file(
                                _profileImage!,
                                fit: BoxFit.cover,
                              ),
                            )
                            : Icon(
                              Icons.add_a_photo,
                              size: 40,
                              color: Colors.white.withOpacity(0.8),
                            ),
                  ),
                ],
              ),
            ),
            if (_profileImage != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'Tap to change image',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
              ),
            const SizedBox(height: 24),
            const Text(
              'Create Your Project',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Fill in the details to get started',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildStepIndicator(0, 'Personal Info'),
                const SizedBox(width: 24),
                _buildStepIndicator(1, 'Project Details'),
                const SizedBox(width: 24),
                _buildStepIndicator(2, 'Description'),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: _buildCurrentStep(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator(int step, String label) {
    final isActive = _currentStep == step;
    final isCompleted = _currentStep > step;

    return Column(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color:
                isActive
                    ? Colors.white
                    : isCompleted
                    ? Colors.green
                    : Colors.white.withOpacity(0.3),
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive ? const Color(0xFF1A237E) : Colors.transparent,
              width: 2,
            ),
          ),
          child: Center(
            child:
                isCompleted
                    ? const Icon(Icons.check, color: Colors.white, size: 20)
                    : Text(
                      '${step + 1}',
                      style: TextStyle(
                        color: isActive ? const Color(0xFF1A237E) : Colors.grey,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.white.withOpacity(0.7),
            fontSize: 14,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildPersonalInfoStep();
      case 1:
        return _buildProfessionalDetailsStep();
      case 2:
        return _buildCredentialsStep();
      default:
        return _buildPersonalInfoStep();
    }
  }

  Widget _buildPersonalInfoStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFormField(
          icon: Icons.person,
          label: 'Name',
          hintText: 'Enter your full name',
          controller: _firstNameController,
        ),
        const SizedBox(height: 20),
        _buildFormField(
          icon: Icons.badge,
          label: 'Display Name',
          hintText: 'Name displayed to clients',
          controller: _displayNameController,
        ),
        const SizedBox(height: 20),
        _buildFormField(
          icon: Icons.email,
          label: 'Email Address',
          hintText: 'Your professional email',
          controller: _emailController,
        ),
        const SizedBox(height: 20),
        _buildFormField(
          icon: Icons.phone,
          label: 'Phone Number',
          hintText: '+20',
          controller: _phoneController,
        ),
        const SizedBox(height: 30),
        _buildNavigationButtons(),
      ],
    );
  }

  Widget _buildProfessionalDetailsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFormField(
          icon: Icons.work,
          label: 'Project name',
          hintText: 'Enter project name',
          controller: _projectNameController,
        ),
        const SizedBox(height: 20),
        _buildFormField(
          icon: Icons.business,
          label: 'Project Area',
          hintText: 'Enter project area',
          controller: _projectAreaController,
        ),
        const SizedBox(height: 20),
        _buildFormField(
          icon: Icons.location_on,
          label: 'Project Type',
          hintText: 'Enter project type',
          controller: _projectTypeController,
        ),
        const SizedBox(height: 30),
        _buildNavigationButtons(),
      ],
    );
  }

  Widget _buildCredentialsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFormField(
          icon: Icons.villa,
          label: 'Villas',
          hintText: 'Enter number of villas',
          controller: _villageController,
        ),
        const SizedBox(height: 20),
        _buildFormField(
          icon: Icons.house,
          label: 'Buildings',
          hintText: 'Enter number of buildings',
          controller: _buildingController,
        ),
        const SizedBox(height: 20),
        _buildFormField(
          icon: Icons.local_mall,
          label: 'Malls',
          hintText: 'Enter number of malls',
          controller: _mallsController,
        ),
        const SizedBox(height: 20),
        _buildFormField(
          icon: Icons.park,
          label: 'Parking',
          hintText: 'Enter number of parking spaces',
          controller: _parkingController,
        ),
        const SizedBox(height: 30),
        _buildFinalStepButtons(),
      ],
    );
  }

  Widget _buildNavigationButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        ElevatedButton(
          onPressed: _currentStep > 0 ? _goToPreviousStep : null,
          style: ElevatedButton.styleFrom(
            backgroundColor:
                _currentStep > 0 ? Colors.grey[200] : Colors.grey[100],
            foregroundColor:
                _currentStep > 0 ? Colors.black87 : Colors.grey[400],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: Row(
            children: const [
              Icon(Icons.arrow_back, size: 16),
              SizedBox(width: 8),
              Text(
                "Back",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
        ElevatedButton(
          onPressed: _goToNextStep,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1A237E),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: Row(
            children: const [
              Text(
                "Next",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              SizedBox(width: 8),
              Icon(Icons.arrow_forward, size: 16),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFinalStepButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        ElevatedButton(
          onPressed: _goToPreviousStep,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey[200],
            foregroundColor: Colors.black87,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: Row(
            children: const [
              Icon(Icons.arrow_back, size: 16),
              SizedBox(width: 8),
              Text(
                "Back",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
        ElevatedButton(
          onPressed: _saveProjectData,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1A237E),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: Row(
            children: const [
              Text(
                "Submit",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              SizedBox(width: 8),
              Icon(Icons.check_circle, size: 16),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFormField({
    required IconData icon,
    required String label,
    required String hintText,
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF1A237E).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: const Color(0xFF1A237E), size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1A237E),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(color: Colors.grey[400]),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            prefixIcon: Icon(icon, color: Colors.grey[400], size: 20),
          ),
        ),
      ],
    );
  }

  Widget _buildProfilePictureUpload() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.photo_camera, color: Colors.grey[600], size: 20),
            const SizedBox(width: 8),
            Text(
              'Profile Picture',
              style: TextStyle(
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'A professional photo of yourself',
          style: TextStyle(color: Colors.grey[500], fontSize: 12),
        ),
        const SizedBox(height: 20),
        GestureDetector(
          onTap: _pickDocumentImage,
          child: Center(
            child: Column(
              children: [
                // Show selected image if available
                if (_documentImage != null)
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      image: DecorationImage(
                        image: FileImage(_documentImage!),
                        fit: BoxFit.cover,
                      ),
                    ),
                  )
                else
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFF3949AB),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: const Icon(
                      Icons.cloud_upload,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                const SizedBox(height: 12),
                Text(
                  _documentImage != null ? 'Change Image' : 'Upload Image',
                  style: TextStyle(color: Colors.grey[700]),
                ),
                const SizedBox(height: 16),
                Container(width: 120, height: 2, color: Colors.grey[300]),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
