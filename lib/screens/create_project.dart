import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:paperauto/screens/firstscreen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:paperauto/services/firebase_options.dart';
import 'package:paperauto/services/project_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const CreateProject());
}

class CreateProject extends StatelessWidget {
  const CreateProject({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Paper Automation',
      theme: ThemeData(
        primaryColor: const Color(0xFF3949AB),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3949AB),
          primary: const Color(0xFF3949AB),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
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
        backgroundColor: const Color(0xFF3949AB),
        title: const Text('Paper Automation'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _currentStep > 0 ? _goToPreviousStep : null,
        ),
      ),
      body: Container(
        color: const Color(0xFF3949AB),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Logo - now using profile image if available
            GestureDetector(
              onTap: _pickProfileImage,
              child: Column(
                children: [
                  const Text(
                    'Click to upload profile image',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  CircleAvatar(
                    backgroundColor: const Color(0xFF5C6BC0),
                    radius: 40,
                    backgroundImage:
                        _profileImage != null
                            ? FileImage(_profileImage!)
                            : null,
                    child:
                        _profileImage == null
                            ? Icon(
                              Icons.gavel,
                              size: 40,
                              color: Colors.white.withOpacity(0.8),
                            )
                            : null,
                  ),
                ],
              ),
            ),
            if (_profileImage != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'Tap to change',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
              ),
            const SizedBox(height: 20),
            // Title
            const Text(
              'Join Our Network of Legal Professionals',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            // Subtitle
            const Text(
              'Complete the form to start connecting with Engineers',
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
            const SizedBox(height: 24),
            // Steps indicator
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
            // Form
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFF5F5F5),
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
        CircleAvatar(
          radius: 18,
          backgroundColor:
              isActive
                  ? const Color(0xFF3949AB)
                  : isCompleted
                  ? Colors.green
                  : Colors.grey.withOpacity(0.3),
          child:
              isCompleted
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : Text(
                    '${step + 1}',
                    style: TextStyle(
                      color: isActive ? Colors.white : Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.white.withOpacity(0.7),
            fontSize: 12,
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
        // Name row label
        Row(
          children: [
            Icon(Icons.person, color: Colors.grey[600], size: 20),
            const SizedBox(width: 8),
            Text(
              'Name',
              style: TextStyle(
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // First and Last Name in one row
        Row(
          children: [
            // First Name field
            Expanded(
              child: TextField(
                controller: _firstNameController,
                decoration: InputDecoration(
                  hintText: 'First Name',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Last Name field
            Expanded(
              child: TextField(
                controller: _lastNameController,
                decoration: InputDecoration(
                  hintText: 'Last Name',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ],
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
          hintText: ' ما اسم المشروع ',
          controller: _projectNameController,
        ),
        const SizedBox(height: 20),
        _buildFormField(
          icon: Icons.business,
          label: 'Project Area',
          hintText: ' ما المنطقة التي يقع فيها المشروع ',
          controller: _projectAreaController,
        ),
        const SizedBox(height: 20),
        _buildFormField(
          icon: Icons.location_on,
          label: 'Project Type',
          hintText: ' ما نوع المشروع ',
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
          hintText: 'كم عدد الفلل',
          controller: _villageController,
        ),
        const SizedBox(height: 20),
        _buildFormField(
          icon: Icons.house,
          label: 'building ',
          hintText: 'كم عدد المباني',
          controller: _buildingController,
        ),
        const SizedBox(height: 20),
        _buildFormField(
          icon: Icons.local_mall,
          label: 'Malls',
          hintText: 'كم عدد المولات',
          controller: _mallsController,
        ),
        const SizedBox(height: 20),
        _buildFormField(
          icon: Icons.park,
          label: 'parking',
          hintText: 'كم عدد المواقف',
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
        // Back button
        ElevatedButton(
          onPressed: _currentStep > 0 ? _goToPreviousStep : null,
          style: ElevatedButton.styleFrom(
            backgroundColor:
                _currentStep > 0 ? Colors.grey[300] : Colors.grey[200],
            foregroundColor:
                _currentStep > 0 ? Colors.black87 : Colors.grey[400],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
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

        // Next button
        ElevatedButton(
          onPressed: _goToNextStep,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromARGB(255, 17, 2, 98),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
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
        // Back button
        ElevatedButton(
          onPressed: _goToPreviousStep,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey[300],
            foregroundColor: Colors.black87,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
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

        // Submit button
        ElevatedButton(
          onPressed: _saveProjectData,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3949AB),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
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
            Icon(icon, color: Colors.grey[600], size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
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
