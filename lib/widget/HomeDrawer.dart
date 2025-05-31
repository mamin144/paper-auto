import 'package:flutter/material.dart';
import 'package:paperauto/Auth/profile.dart';
import 'package:paperauto/screens/test_payment_screen.dart';
import 'package:paperauto/screens/approval_requests_screen.dart';
import 'package:paperauto/screens/signature_screen.dart';

class HomeDrawer extends StatelessWidget {
  HomeDrawer({Key? key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // # category
            Container(
              padding: EdgeInsets.symmetric(vertical: 15, horizontal: 15),
              alignment: Alignment.center,
              color: Color.fromARGB(255, 17, 2, 98),
              child: Text(
                '\n Automation Paper \n  ',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 33,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            SizedBox(height: 25),

            // first category
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProfileScreen()),
                );
              },
              child: Row(
                children: [
                  SizedBox(width: 9),
                  Icon(Icons.account_circle, size: 30),
                  SizedBox(width: 3),
                  Text(' My Profile ', style: TextStyle(fontSize: 21)),
                ],
              ),
            ),
            SizedBox(height: 18),

            TextButton(
              onPressed: () {
                // Handle Notifications button press
              },
              child: Row(
                children: [
                  SizedBox(width: 9),
                  Icon(Icons.notifications, size: 30),
                  SizedBox(width: 3),
                  Text(' Notifications ', style: TextStyle(fontSize: 21)),
                ],
              ),
            ),
            SizedBox(height: 18),

            // Add Approval Requests button
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ApprovalRequestsScreen()),
                );
              },
              child: Row(
                children: [
                  SizedBox(width: 9),
                  Icon(Icons.approval, size: 30),
                  SizedBox(width: 3),
                  Text(' Approval Requests ', style: TextStyle(fontSize: 21)),
                ],
              ),
            ),
            SizedBox(height: 18),

            // Add Manage Signature button
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SignatureScreen()),
                );
              },
              child: Row(
                children: [
                  SizedBox(width: 9),
                  Icon(Icons.brush, size: 30),
                  SizedBox(width: 3),
                  Text(' Manage Signature ', style: TextStyle(fontSize: 21)),
                ],
              ),
            ),
            SizedBox(height: 18),

            Divider(
              color: const Color.fromARGB(255, 158, 158, 158),
              thickness: 1,
            ),
            SizedBox(height: 22),

            // second category
            TextButton(
              onPressed: () {
                // Navigator.push(
                //   context,
                //   MaterialPageRoute(builder: (context) => ProfileScreen()),
                // );
              },
              child: Row(
                children: [
                  SizedBox(width: 9),
                  Icon(Icons.settings, size: 30),
                  SizedBox(width: 3),
                  Text(' Settings ', style: TextStyle(fontSize: 21)),
                ],
              ),
            ),
            SizedBox(height: 18),

            TextButton(
              onPressed: () {},
              child: Row(
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TestPaymentScreen(),
                        ),
                      );
                    },
                    child: Row(
                      children: [
                        Icon(Icons.attach_money_outlined, size: 30),

                        Text('Payment Method ', style: TextStyle(fontSize: 21)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 18),

            TextButton(
              onPressed: () {
                // Handle Rate App button press
              },
              child: Row(
                children: [
                  SizedBox(width: 9),
                  Icon(Icons.star, size: 30),
                  SizedBox(width: 3),
                  Text(' Rate App ! ', style: TextStyle(fontSize: 21)),
                ],
              ),
            ),
            SizedBox(height: 18),
          ],
        ),
      ),
    );
  }
}
