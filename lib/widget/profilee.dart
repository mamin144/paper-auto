import 'dart:io';

import 'package:flutter/material.dart';

class SettingsFragment extends StatelessWidget {
  const SettingsFragment({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Divider(color: Colors.grey, thickness: 1),

            // first category
            SizedBox(height: 25),
            Text(
              ' Settings ',
              style: TextStyle(fontSize: 27, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 25),

            Row(
              children: [
                Icon(Icons.account_circle, size: 25),
                SizedBox(width: 5),
                Text(' Personal information ', style: TextStyle(fontSize: 17)),
                Spacer(flex: 1),
                Icon(Icons.arrow_forward_ios, size: 18),
              ],
            ),
            SizedBox(height: 6),
            Divider(color: Colors.grey, thickness: 1),
            SizedBox(height: 6),

            Row(
              children: [
                Icon(Icons.security, size: 25),
                SizedBox(width: 5),
                Text(' Login & security ', style: TextStyle(fontSize: 17)),
                Spacer(flex: 1),
                Icon(Icons.arrow_forward_ios, size: 18),
              ],
            ),
            SizedBox(height: 6),
            Divider(color: Colors.grey, thickness: 1),
            SizedBox(height: 6),

            Row(
              children: [
                Icon(Icons.payments, size: 25),
                SizedBox(width: 5),
                Text(' Payments and payouts ', style: TextStyle(fontSize: 17)),
                Spacer(flex: 1),
                Icon(Icons.arrow_forward_ios, size: 18),
              ],
            ),
            SizedBox(height: 6),
            Divider(color: Colors.grey, thickness: 1),
            SizedBox(height: 6),

            Row(
              children: [
                Icon(Icons.settings_applications_outlined, size: 25),
                SizedBox(width: 5),
                Text(' Accessibility ', style: TextStyle(fontSize: 17)),
                Spacer(flex: 1),
                Icon(Icons.arrow_forward_ios, size: 18),
              ],
            ),
            SizedBox(height: 6),
            Divider(color: Colors.grey, thickness: 1),
            SizedBox(height: 6),

            Row(
              children: [
                Icon(Icons.text_snippet, size: 25),
                SizedBox(width: 5),
                Text(' Taxes ', style: TextStyle(fontSize: 17)),
                Spacer(flex: 1),
                Icon(Icons.arrow_forward_ios, size: 18),
              ],
            ),
            SizedBox(height: 6),
            Divider(color: Colors.grey, thickness: 1),
            SizedBox(height: 6),

            Row(
              children: [
                Icon(Icons.translate, size: 25),
                SizedBox(width: 5),
                Text(' Translation ', style: TextStyle(fontSize: 17)),
                Spacer(flex: 1),
                Icon(Icons.arrow_forward_ios, size: 18),
              ],
            ),
            SizedBox(height: 6),
            Divider(color: Colors.grey, thickness: 1),
            SizedBox(height: 6),

            Row(
              children: [
                Icon(Icons.notifications, size: 25),
                SizedBox(width: 5),
                Text(' Notifications ', style: TextStyle(fontSize: 17)),
                Spacer(flex: 1),
                Icon(Icons.arrow_forward_ios, size: 18),
              ],
            ),
            SizedBox(height: 6),
            Divider(color: Colors.grey, thickness: 1),
            SizedBox(height: 6),

            Row(
              children: [
                Icon(Icons.lock, size: 25),
                SizedBox(width: 5),
                Text(' Privacy and sharing ', style: TextStyle(fontSize: 17)),
                Spacer(flex: 1),
                Icon(Icons.arrow_forward_ios, size: 18),
              ],
            ),
            SizedBox(height: 6),
            Divider(color: Colors.grey, thickness: 1),
            SizedBox(height: 6),

            // second category
            SizedBox(height: 25),
            Text(
              ' Hosting ',
              style: TextStyle(fontSize: 27, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 25),

            Row(
              children: [
                Icon(Icons.add_home, size: 25),
                SizedBox(width: 5),
                Text(' List your space  ', style: TextStyle(fontSize: 17)),
                Spacer(flex: 1),
                Icon(Icons.arrow_forward_ios, size: 18),
              ],
            ),
            SizedBox(height: 6),
            Divider(color: Colors.grey, thickness: 1),
            SizedBox(height: 6),

            Row(
              children: [
                Icon(Icons.home_filled, size: 25),
                SizedBox(width: 5),
                Text(' Learn about hosting  ', style: TextStyle(fontSize: 17)),
                Spacer(flex: 1),
                Icon(Icons.arrow_forward_ios, size: 18),
              ],
            ),
            SizedBox(height: 6),
            Divider(color: Colors.grey, thickness: 1),
            SizedBox(height: 6),

            // third category
            SizedBox(height: 25),
            Text(
              ' Referrals & Credits ',
              style: TextStyle(fontSize: 27, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 25),

            Row(
              children: [
                Icon(Icons.card_giftcard, size: 25),
                SizedBox(width: 5),
                Text(' Refer a Host  ', style: TextStyle(fontSize: 17)),
                Spacer(flex: 1),
                Icon(Icons.arrow_forward_ios, size: 18),
              ],
            ),
            SizedBox(height: 6),
            Divider(color: Colors.grey, thickness: 1),
            SizedBox(height: 6),

            // fourth category
            SizedBox(height: 25),
            Text(
              'Support',
              style: TextStyle(fontSize: 27, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 25),

            InkWell(
              onTap: () {
                // Navigator.push(context,
                //     MaterialPageRoute(builder: (context) => LoginPage()));
              },
              child: Row(
                children: [
                  Icon(Icons.help, size: 25),
                  SizedBox(width: 5),
                  Text(' Technical Support  ', style: TextStyle(fontSize: 17)),
                  Spacer(flex: 1),
                  Icon(Icons.arrow_forward_ios, size: 18),
                ],
              ),
            ),
            SizedBox(height: 25),

            InkWell(
              onTap: () {
                // Navigator.push(context,
                //     MaterialPageRoute(builder: (context) => AddCard()));
              },
              child: Row(
                children: [
                  Icon(Icons.verified_outlined, size: 25),
                  SizedBox(width: 5),
                  Text('  Verification  ', style: TextStyle(fontSize: 17)),
                  Spacer(flex: 1),
                  Icon(Icons.verified, size: 18),
                ],
              ),
            ),
            SizedBox(height: 6),
            Divider(color: Colors.grey, thickness: 1),
            SizedBox(height: 6),

            Row(
              children: [
                Icon(Icons.headphones_outlined, size: 25),
                SizedBox(width: 5),
                Text(
                  ' Report a neighborhood concern  ',
                  style: TextStyle(fontSize: 17),
                ),
                Spacer(flex: 1),
                Icon(Icons.arrow_forward_ios, size: 18),
              ],
            ),
            SizedBox(height: 6),
            Divider(color: Colors.grey, thickness: 1),
            SizedBox(height: 6),

            Row(
              children: [
                Icon(Icons.safety_check, size: 25),
                SizedBox(width: 5),
                Text(
                  ' Get help with a safety issue  ',
                  style: TextStyle(fontSize: 17),
                ),
                Spacer(flex: 1),
                Icon(Icons.arrow_forward_ios, size: 18),
              ],
            ),
            SizedBox(height: 6),
            Divider(color: Colors.grey, thickness: 1),
            SizedBox(height: 6),

            Row(
              children: [
                Icon(Icons.edit, size: 25),
                SizedBox(width: 5),
                Text(' Give us feedback  ', style: TextStyle(fontSize: 17)),
                Spacer(flex: 1),
                Icon(Icons.arrow_forward_ios, size: 18),
              ],
            ),
            SizedBox(height: 6),
            Divider(color: Colors.grey, thickness: 1),
            SizedBox(height: 6),

            // fifth category
            SizedBox(height: 25),
            Text(
              'Legal',
              style: TextStyle(fontSize: 27, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 25),

            Row(
              children: [
                Icon(Icons.policy, size: 25),
                SizedBox(width: 5),
                Text(' Terms of Service  ', style: TextStyle(fontSize: 17)),
                Spacer(flex: 1),
                Icon(Icons.arrow_forward_ios, size: 18),
              ],
            ),
            SizedBox(height: 6),
            Divider(color: Colors.grey, thickness: 1),
            SizedBox(height: 6),

            Row(
              children: [
                Icon(Icons.policy, size: 25),
                SizedBox(width: 5),
                Text(' Privacy Policy  ', style: TextStyle(fontSize: 17)),
                Spacer(flex: 1),
                Icon(Icons.arrow_forward_ios, size: 18),
              ],
            ),
            SizedBox(height: 6),
            Divider(color: Colors.grey, thickness: 1),
            SizedBox(height: 6),

            Row(
              children: [
                Icon(Icons.policy, size: 25),
                SizedBox(width: 5),
                Text(' Open source licenses  ', style: TextStyle(fontSize: 17)),
                Spacer(flex: 1),
                Icon(Icons.arrow_forward_ios, size: 18),
              ],
            ),
            SizedBox(height: 6),
            Divider(color: Colors.grey, thickness: 1),
            SizedBox(height: 6),

            // sixth category
            TextButton(
              onPressed: () {
                Navigator.popAndPushNamed(context, exit(hashCode));
              },
              child: Row(
                children: [
                  Icon(Icons.logout, size: 25),
                  SizedBox(width: 5),
                  Text(' Log out  ', style: TextStyle(fontSize: 22)),
                  Spacer(flex: 1),
                  Icon(Icons.arrow_forward_ios, size: 18),
                ],
              ),
            ),
            SizedBox(height: 6),
            Divider(color: Colors.grey, thickness: 1),
            SizedBox(height: 6),
          ],
        ),
      ),
    );
  }
}
