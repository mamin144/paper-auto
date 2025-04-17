import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:paperauto/widget/profilee.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(ProfileApp());
}

class ProfileApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Professional Profile',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.grey[200],
      ),
      home: ProfileScreen(),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Profile", style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: Color.fromARGB(255, 17, 2, 98),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ProfilePageState(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Navigate to profile edit page
          print("Edit Profile Clicked");
        },
        child: Icon(Icons.edit, size: 28, color: Colors.white),
        backgroundColor: Color.fromARGB(255, 17, 2, 98),
      ),
    );
  }
}

class ProfilePageState extends StatefulWidget {
  @override
  _ProfilePageStateState createState() => _ProfilePageStateState();
}

class _ProfilePageStateState extends State<ProfilePageState> {
  late String email = 'Loading...';
  late String name = 'Loading...';
  late String profilePicture = '';
  late String phoneNumber = '';

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        FirebaseFirestore firestore = FirebaseFirestore.instance;
        DocumentSnapshot documentSnapshot =
            await firestore.collection('users').doc(user.uid).get();
        if (documentSnapshot.exists) {
          Map<String, dynamic> data =
              documentSnapshot.data() as Map<String, dynamic>;
          setState(() {
            email = data['email'] ?? 'No Email';
            name = data['First name'] ?? 'No Name';
            profilePicture = data['profilePicture'] ?? '';
            phoneNumber = data['phone number'] ?? 'No Phone Number';
          });
        } else {
          print('Document does not exist');
        }
      } else {
        print('User not logged in');
      }
    } catch (e, stackTrace) {
      print('Error in fetchData: $e');
      print(stackTrace);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ProfessionalProfileWidget(
        profilePicture: profilePicture,
        name: name,
        email: email,
        phoneNumber: phoneNumber,
      ),
    );
  }
}

class ProfessionalProfileWidget extends StatelessWidget {
  final String profilePicture;
  final String name;
  final String email;
  final String phoneNumber;

  const ProfessionalProfileWidget({
    Key? key,
    required this.profilePicture,
    required this.name,
    required this.email,
    required this.phoneNumber,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
          child: Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Profile Picture
                ClipRRect(
                  borderRadius: BorderRadius.circular(60),
                  child:
                      profilePicture.isNotEmpty
                          ? Image.network(
                            profilePicture,
                            width: 120,
                            height: 120,
                            fit: BoxFit.cover,
                          )
                          : Icon(
                            Icons.account_circle,
                            size: 120,
                            color: Colors.grey,
                          ),
                ),
                const SizedBox(height: 20),

                // Name
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),

                // Email
                ListTile(
                  leading: Icon(Icons.email, color: Colors.blueAccent),
                  title: Text(
                    email,
                    style: TextStyle(fontSize: 16),
                    // textAlign: TextAlign.center,
                  ),
                ),

                // Phone Number
                ListTile(
                  leading: Icon(Icons.phone, color: Colors.green),
                  title: Text(
                    '+20 ' + phoneNumber,
                    style: TextStyle(fontSize: 16),
                  ),
                ),

                const SizedBox(height: 20),

                // Edit Button
                ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Add edit profile functionality
                    print("Edit Profile Clicked");
                  },
                  icon: Icon(Icons.edit, color: Colors.white),
                  label: Text("Edit Profile"),
                  style: ElevatedButton.styleFrom(
                    textStyle: const TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: Color.fromARGB(255, 17, 2, 98),
                  ),
                ),
                Expanded(child: SettingsFragment()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
