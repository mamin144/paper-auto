import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProjectService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String?> _uploadImage(File? image, String folder) async {
    if (image == null) return null;
    
    final ref = _storage.ref().child('$folder/${DateTime.now().millisecondsSinceEpoch}.jpg');
    await ref.putFile(image);
    return await ref.getDownloadURL();
  }

  Future<void> createProject({
    required Map<String, dynamic> personalInfo,
    required Map<String, dynamic> projectDetails,
    required Map<String, dynamic> projectDescription,
    File? profileImage,
    File? documentImage,
  }) async {
    try {
      // Get current user
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Upload images if provided
      final profileImageUrl = await _uploadImage(profileImage, 'profile_images');
      final documentImageUrl = await _uploadImage(documentImage, 'document_images');

      // Add image URLs to personal info if they exist
      if (profileImageUrl != null) {
        personalInfo['profileImageUrl'] = profileImageUrl;
      }
      if (documentImageUrl != null) {
        personalInfo['documentImageUrl'] = documentImageUrl;
      }

      // Save project data to Firestore
      await _firestore.collection('projects').add({
        'personalInfo': personalInfo,
        'projectDetails': projectDetails,
        'projectDescription': projectDescription,
        'createdAt': FieldValue.serverTimestamp(),
        'userId': user.uid, // Add user ID
        'userEmail': user.email, // Add user email for reference
      });
    } catch (e) {
      throw Exception('Failed to create project: $e');
    }
  }

  // Get projects for current user
  Future<List<Map<String, dynamic>>> getProjects() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final snapshot = await _firestore
          .collection('projects')
          .where('userId', isEqualTo: user.uid)
          .get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id; // Add document ID to the data
        return data;
      }).toList();
    } catch (e) {
      throw Exception('Failed to get projects: $e');
    }
  }

  // Get a specific project (only if user owns it)
  Future<Map<String, dynamic>?> getProject(String projectId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final doc = await _firestore.collection('projects').doc(projectId).get();
      final data = doc.data();
      
      // Check if user owns this project
      if (data != null && data['userId'] == user.uid) {
        return data;
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get project: $e');
    }
  }

  Future<void> updateProject(
    String projectId, {
    Map<String, dynamic>? personalInfo,
    Map<String, dynamic>? projectDetails,
    Map<String, dynamic>? projectDescription,
    File? profileImage,
    File? documentImage,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // First verify user owns this project
      final doc = await _firestore.collection('projects').doc(projectId).get();
      if (doc.data()?['userId'] != user.uid) {
        throw Exception('User does not have permission to update this project');
      }

      final Map<String, dynamic> updateData = {};

      if (personalInfo != null) {
        updateData['personalInfo'] = personalInfo;
      }
      if (projectDetails != null) {
        updateData['projectDetails'] = projectDetails;
      }
      if (projectDescription != null) {
        updateData['projectDescription'] = projectDescription;
      }

      // Upload and update images if provided
      if (profileImage != null) {
        final profileImageUrl = await _uploadImage(profileImage, 'profile_images');
        updateData['personalInfo.profileImageUrl'] = profileImageUrl;
      }
      if (documentImage != null) {
        final documentImageUrl = await _uploadImage(documentImage, 'document_images');
        updateData['personalInfo.documentImageUrl'] = documentImageUrl;
      }

      await _firestore.collection('projects').doc(projectId).update(updateData);
    } catch (e) {
      throw Exception('Failed to update project: $e');
    }
  }

  Future<void> deleteProject(String projectId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // First verify user owns this project
      final doc = await _firestore.collection('projects').doc(projectId).get();
      if (doc.data()?['userId'] != user.uid) {
        throw Exception('User does not have permission to delete this project');
      }

      await _firestore.collection('projects').doc(projectId).delete();
    } catch (e) {
      throw Exception('Failed to delete project: $e');
    }
  }
} 