import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; //for url launching, change dependencies in pubspec.yaml as well

class ContactScreen extends StatelessWidget{
  const ContactScreen({super.key});

  /*this is used to launch the url if pressed. go into the AndroidManifest xml to add internet permissions
  void _launchURL(Uri url) async{
    if(await canLaunchUrl(url)){
      await launchUrl(url);
    }else{
      throw 'Unable to launch $url';
    }
  }
  */

  @override
  Widget build(BuildContext context){
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text('Merian Brothers', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              Text('Call us at: (508) 612-2688', style: TextStyle(fontSize: 18)),
              SizedBox(height: 10),
              //GestureDetector(
                //onTap: () => _launchURL(Uri.parse('https://www.merianbrothers.com/')),
                //child: Text('Check out our Website!', style: TextStyle(fontSize: 18, color: Colors.blue, decoration: TextDecoration.underline)),
              //),
            ],
          ),
        ),
      ),
      backgroundColor: Colors.white,
    );
  }
}