import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; //for url launching, change dependencies in pubspec.yaml as well

class ContactScreen extends StatelessWidget{
  const ContactScreen({super.key});

  //this is used to launch the url if pressed. Permissions already added in the AndroidManifest xml
  void _launchURL(Uri url) async{
    if(await canLaunchUrl(url)){
      await launchUrl(url);
    }else{
      throw 'Unable to launch $url';
    }
  }
  /*
  Nothing too crazy happens in the contact.dart
  Mainly formatting boxes and text
  Handling a urlLauncher for an onTap detection
  Image used can be found in 'assets' directory in project files
  */
  Widget _buildContactBox({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 155,
        height: 120,
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 5,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 32, color: Colors.black),
            SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                color: Color(0xFFF5F5F5),
                padding: EdgeInsets.symmetric(vertical: 6),
                child: Center(
                  child: Text(
                    'Contact Us',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Final Fitting',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Once you have your predicted size, please reach out to schedule your final fitting.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildContactBox(
                    icon: Icons.phone,
                    title: 'Call us',
                    subtitle: '(508) 612-2688',
                    onTap: () => launchUrl(Uri.parse('tel:5086122688')),
                  ),
                  SizedBox(width: 16),
                  _buildContactBox(
                    icon: Icons.web,
                    title: 'Visit Website',
                    subtitle: 'merianbrothers.com',
                    onTap: () => _launchURL(Uri.parse('https://www.merianbrothers.com/')),
                  ),
                ],
              ),
              SizedBox(height: 40),
              Container(
                height: 200,
                width: double.infinity,
                child: Image.asset(
                  'assets/MerianBrothersTuxWeddingParty.jpg',
                  fit: BoxFit.cover,
                ),
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}