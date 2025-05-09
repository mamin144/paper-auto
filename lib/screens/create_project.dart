import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:paperauto/screens/firstscreen.dart';
import 'package:paperauto/screens/create_or_view.dart';
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

class _RegistrationScreenState extends State<RegistrationScreen>
    with SingleTickerProviderStateMixin {
  int _currentStep = 0;
  final int _totalSteps = 3;
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

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
  final TextEditingController _villageController = TextEditingController();
  final TextEditingController _buildingController = TextEditingController();
  final TextEditingController _mallsController = TextEditingController();
  final TextEditingController _parkingController = TextEditingController();
  // Add new controllers for residential fields
  final TextEditingController _repetitionController = TextEditingController();
  final TextEditingController _basementController = TextEditingController();
  final TextEditingController _roofsController = TextEditingController();
  final TextEditingController _apartmentsController = TextEditingController();
  final TextEditingController _numberOfshopsontroller = TextEditingController();

  // Project service instance
  final ProjectService _projectService = ProjectService();

  String? _selectedProjectType;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    // Clean up controllers
    _firstNameController.dispose();
    _lastNameController.dispose();
    _displayNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _projectNameController.dispose();
    _projectAreaController.dispose();
    _villageController.dispose();
    _buildingController.dispose();
    _mallsController.dispose();
    _parkingController.dispose();
    // Dispose new controllers
    _repetitionController.dispose();
    _basementController.dispose();
    _roofsController.dispose();
    _apartmentsController.dispose();
    super.dispose();
  }

  void _goToNextStep() {
    if (_currentStep < _totalSteps - 1) {
      setState(() {
        _currentStep++;
      });
      _controller.reset();
      _controller.forward();
    }
  }

  void _goToPreviousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _controller.reset();
      _controller.forward();
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ScreenOne()),
      );
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
        'projectType': _selectedProjectType,
      };

      final projectDescription =
          _selectedProjectType == 'Residential'
              ? {
                'repetition': _repetitionController.text,
                'basement': _basementController.text,
                'roofs': _roofsController.text,
                'apartments': _apartmentsController.text,
              }
              : {
                'repetition': _repetitionController.text,
                'basement': _basementController.text,
                'roofs': _roofsController.text,
                'apartments': _apartmentsController.text,
                'number of shops': _numberOfshopsontroller.text,
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
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF3949AB), Color(0xFF1A237E)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: _goToPreviousStep,
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'Create New Project',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Logo with animation
              FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: GestureDetector(
                    onTap: _pickProfileImage,
                    child: Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            backgroundColor: const Color(0xFF5C6BC0),
                            radius: 50,
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
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _profileImage != null
                              ? 'Tap to change'
                              : 'Tap to upload profile',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              // Steps indicator with animation
              FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildStepIndicator(0, 'Personal Info'),
                      const SizedBox(width: 24),
                      _buildStepIndicator(1, 'Project Details'),
                      const SizedBox(width: 24),
                      _buildStepIndicator(2, 'Description'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),
              // Form with animation
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 10,
                            offset: Offset(0, -5),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30),
                        ),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                          child: _buildCurrentStep(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
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
            shape: BoxShape.circle,
            color:
                isActive
                    ? Colors.white
                    : isCompleted
                    ? Colors.green
                    : Colors.white.withOpacity(0.3),
            boxShadow:
                isActive
                    ? [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ]
                    : null,
          ),
          child: Center(
            child:
                isCompleted
                    ? const Icon(Icons.check, color: Colors.white, size: 20)
                    : Text(
                      '${step + 1}',
                      style: TextStyle(
                        color:
                            isActive ? const Color(0xFF3949AB) : Colors.white,
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
            fontSize: 12,
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
        // Name row label
        Row(
          children: [
            Icon(Icons.person, color: const Color(0xFF3949AB), size: 20),
            const SizedBox(width: 8),
            Text(
              'Name',
              style: const TextStyle(
                color: Color(0xFF3949AB),
                fontWeight: FontWeight.w600,
                fontSize: 16,
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
        Container(
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      color: const Color(0xFF3949AB),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Project Type',
                      style: const TextStyle(
                        color: Color(0xFF3949AB),
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedProjectType,
                    hint: Text(
                      'Select project type',
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(
                        value: 'Residential',
                        child: Text('Residential'),
                      ),
                      DropdownMenuItem(
                        value: 'Commercial',
                        child: Text('Commercial'),
                      ),
                    ],
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedProjectType = newValue;
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
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
        if (_selectedProjectType == 'Residential') ...[
          _buildFormField(
            icon: Icons.repeat,
            label: 'عدد متكرر',
            hintText: 'ادخل العدد المتكرر',
            controller: _repetitionController,
          ),
          const SizedBox(height: 20),
          _buildFormField(
            icon: Icons.layers,
            label: 'عدد البدرومات',
            hintText: 'ادخل عدد البدرومات',
            controller: _basementController,
          ),
          const SizedBox(height: 20),
          _buildFormField(
            icon: Icons.roofing,
            label: 'عدد الروفات',
            hintText: 'ادخل عدد الروفات',
            controller: _roofsController,
          ),
          const SizedBox(height: 20),
          _buildFormField(
            icon: Icons.apartment,
            label: 'عدد الشقق',
            hintText: 'ادخل عدد الشقق',
            controller: _apartmentsController,
          ),
        ] else ...[
          _buildFormField(
            icon: Icons.repeat,
            label: 'عدد متكرر',
            hintText: 'ادخل العدد المتكرر',
            controller: _repetitionController,
          ),
          const SizedBox(height: 20),
          _buildFormField(
            icon: Icons.layers,
            label: 'عدد البدرومات',
            hintText: 'ادخل عدد البدرومات',
            controller: _basementController,
          ),
          const SizedBox(height: 20),
          _buildFormField(
            icon: Icons.roofing,
            label: 'عدد الروفات',
            hintText: 'ادخل عدد الروفات',
            controller: _roofsController,
          ),
          const SizedBox(height: 20),
          _buildFormField(
            icon: Icons.apartment,
            label: 'عدد الشقق',
            hintText: 'ادخل عدد الشقق',
            controller: _apartmentsController,
          ),
          const SizedBox(height: 20),
          _buildFormField(
            icon: Icons.apartment,
            label: ' عدد المحلات في الدور',
            hintText: 'ادخل عدد المحلات',
            controller: _numberOfshopsontroller,
          ),
        ],
        const SizedBox(height: 30),
        _buildFinalStepButtons(),
      ],
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ElevatedButton(
            onPressed: _currentStep > 0 ? _goToPreviousStep : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[200],
              foregroundColor: Colors.black87,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Row(
              children: const [
                Icon(Icons.arrow_back, size: 20),
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
              backgroundColor: const Color(0xFF3949AB),
              foregroundColor: Colors.white,
              elevation: 0,
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
                Icon(Icons.arrow_forward, size: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinalStepButtons() {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ElevatedButton(
            onPressed: _goToPreviousStep,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[200],
              foregroundColor: Colors.black87,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Row(
              children: const [
                Icon(Icons.arrow_back, size: 20),
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
              backgroundColor: const Color(0xFF3949AB),
              foregroundColor: Colors.white,
              elevation: 0,
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
                Icon(Icons.check_circle, size: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormField({
    required IconData icon,
    required String label,
    required String hintText,
    required TextEditingController controller,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Icon(icon, color: const Color(0xFF3949AB), size: 20),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF3949AB),
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(color: Colors.grey[400]),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              border: InputBorder.none,
              filled: true,
              fillColor: Colors.white,
            ),
          ),
        ],
      ),
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
