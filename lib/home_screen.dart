import 'package:flutter/material.dart';
import 'contact.dart'; //imports our contact screen
import 'package:image_picker/image_picker.dart'; //allows for use of images
import 'dart:io'; //allows for input/output file use

class HomeScreen extends StatefulWidget{
  const HomeScreen({Key? key}) : super(key : key);

  @override
  _HomeScreenState createState() => _HomeScreenState();

}  

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin{
  late TabController _tabController; //tab controller for switching windows
  final TextEditingController _heightController = TextEditingController(); //height input
  final TextEditingController _weightController = TextEditingController(); //weight input
  File? _image;
  final ImagePicker _picker = ImagePicker(); //image input

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  //image importing from user
  Future<void> _pickImage() async{
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null){
      setState((){
        _image = File(pickedFile.path);
      });
    }
  }

  @override
  void dispose(){
    _tabController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }
  //create widget for info input
  Widget _buildFittingRoomTab(){
    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextFormField(
              controller: _heightController,
              decoration: InputDecoration(
                labelText: 'Enter your height in inches',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextFormField(
              controller: _weightController,
              decoration: InputDecoration(
                labelText: 'Enter your weight in lbs',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ),
          SizedBox(height: 10),
          _image != null ? Image.file(_image!) : Text("Image not selected"),
          ElevatedButton(
            onPressed: _pickImage,
            child: Text('Pick Image'),
          ),
        ],
      ),
    );



  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Virtual Fitting Room',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.black,
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.blue,
          labelColor: Colors.blue,
          unselectedLabelColor: Colors.grey,
          tabs: [
            Tab(text: 'Fitting', icon: Icon(Icons.home)),
            Tab(text: 'Contact Us', icon: Icon(Icons.call)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFittingRoomTab(),
          ContactScreen(),
        ],
      ),
      backgroundColor: Colors.white,
    );
  }
}
