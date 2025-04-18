import 'package:flutter/material.dart';
import 'package:paperauto/screens/create_project.dart';
import 'package:paperauto/widget/HomeDrawer.dart';
import 'package:paperauto/widget/button.dart';
import 'package:paperauto/screens/my_projects.dart';

class ScreenOne extends StatelessWidget {
  const ScreenOne({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Category"),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 25,
          fontWeight: FontWeight.bold,
        ),
        backgroundColor: Color.fromARGB(255, 17, 2, 98),
        // leading: IconButton(
        //   // 🔙 AppBar Back Button
        //   icon: const Icon(Icons.arrow_back),
        //   onPressed: () {s
        //     Navigator.pop(context);
        //   },
        // ),
        // actions: [
        //   // Move Drawer button to the right
        //   Builder(
        //     builder:
        //         (context) => IconButton(
        //           icon: const Icon(Icons.menu),
        //           onPressed: () => Scaffold.of(context).openDrawer(),
        //         ),
        //   ),
        // ],
      ),
      drawer: HomeDrawer(), // Move Drawer to the right side
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            WidgetButton(
              text: 'create project',
              onPressed: () => _navigateTo(context, const CreateProject()),
            ),
            SizedBox(height: 20),
            WidgetButton(
              text: 'view project',
              onPressed: () => _navigateTo(context, const MyProjects()),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        // ⬅ Floating Back Button
        backgroundColor: Color.fromARGB(255, 17, 2, 98),
        onPressed: () {
          Navigator.pop(context);
        },
        child: const Icon(Icons.arrow_back),
      ),
    );
  }

  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
  }
}
