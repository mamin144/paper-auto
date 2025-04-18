import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:paperauto/Auth/LoginPage.dart';
import 'package:paperauto/Auth/splashScreen.dart';
import 'package:paperauto/screens/firstscreen.dart';
import 'package:paperauto/screens/create_project.dart';
import 'package:paperauto/screens/templates.dart';
import 'services/firebase_options.dart';
import 'screens/test_payment_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    await dotenv.load();  // Remove fileName parameter since .env is the default
    runApp(const MyApp());
  } catch (e) {
    print('Error initializing app: $e');
    // You might want to show an error screen here
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('Error initializing app: $e'),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PayMob Test',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 0, 0, 0),
        ),
        useMaterial3: true,
      ),
      home: SplashScreen(),
    );
  }
}

// class MyHomePage extends StatefulWidget {
//   const MyHomePage({super.key, required this.title});

//   final String title;

//   @override
//   State<MyHomePage> createState() => _MyHomePageState();
// }

// class _MyHomePageState extends State<MyHomePage> {
//   int _counter = 0;

//   void _incrementCounter() {
//     setState(() {
//       _counter++;
//     });
//   }

//   // @override
//   // Widget build(BuildContext context) {
//   //   return Scaffold(
//   //     appBar: AppBar(
//   //       backgroundColor: Theme.of(context).colorScheme.inversePrimary,
//   //       title: Text(widget.title),
//   //     ),
//   //     body: Center(
//   //       child: Column(
//   //         mainAxisAlignment: MainAxisAlignment.center,
//   //         children: <Widget>[
//   //           const Text('You have pushed the button this many times:'),
//   //           Text(
//   //             '$_counter',
//   //             style: Theme.of(context).textTheme.headlineMedium,
//   //           ),
//   //         ],
//   //       ),
//   //     ),
//   //     floatingActionButton: FloatingActionButton(
//   //       onPressed: _incrementCounter,
//   //       tooltip: 'Increment',
//   //       child: const Icon(Icons.add),
//   //     ),
//   //   );
//   // }
// }
