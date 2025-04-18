import 'package:flutter/material.dart';
import 'package:paperauto/services/project_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:paperauto/screens/generate_report.dart';

class MyProjects extends StatefulWidget {
  const MyProjects({super.key});

  @override
  State<MyProjects> createState() => _MyProjectsState();
}

class _MyProjectsState extends State<MyProjects> {
  final ProjectService _projectService = ProjectService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<Map<String, dynamic>> _projects = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final projects = await _projectService.getProjects();
      setState(() {
        _projects = projects;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF3949AB),
        title: const Text('My Projects'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadProjects,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Error: $_error',
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadProjects,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _projects.isEmpty
                  ? const Center(
                      child: Text(
                        'No projects found. Create your first project!',
                        style: TextStyle(fontSize: 16),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _projects.length,
                      itemBuilder: (context, index) {
                        final project = _projects[index];
                        return _ProjectCard(
                          project: project,
                          onDelete: () async {
                            try {
                              await _projectService.deleteProject(project['id']);
                              _loadProjects();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Project deleted successfully'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error deleting project: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                        );
                      },
                    ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF3949AB),
        onPressed: () {
          // Navigate to create project screen
          Navigator.pushNamed(context, '/create_project');
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  final Map<String, dynamic> project;
  final VoidCallback onDelete;

  const _ProjectCard({
    required this.project,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final personalInfo = project['personalInfo'] as Map<String, dynamic>;
    final projectDetails = project['projectDetails'] as Map<String, dynamic>;
    final projectDescription = project['projectDescription'] as Map<String, dynamic>;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    projectDetails['projectName'] ?? 'Unnamed Project',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.description, color: Color(0xFF3949AB)),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => GenerateReport(project: project),
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: onDelete,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildInfoRow('Area', projectDetails['projectArea']),
            _buildInfoRow('Type', projectDetails['projectType']),
            const Divider(),
            const Text(
              'Project Details',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildInfoRow('Villas', projectDescription['village']),
            _buildInfoRow('Buildings', projectDescription['building']),
            _buildInfoRow('Malls', projectDescription['malls']),
            _buildInfoRow('Parking', projectDescription['parking']),
            const Divider(),
            const Text(
              'Contact Information',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildInfoRow('Name', '${personalInfo['firstName']} ${personalInfo['lastName']}'),
            _buildInfoRow('Email', personalInfo['email']),
            _buildInfoRow('Phone', personalInfo['phone']),
            if (personalInfo['profileImageUrl'] != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    personalInfo['profileImageUrl'],
                    height: 100,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(value ?? 'Not specified'),
          ),
        ],
      ),
    );
  }
} 