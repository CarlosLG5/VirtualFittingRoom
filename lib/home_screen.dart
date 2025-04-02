import 'package:flutter/material.dart';
import 'contact.dart'; //imports our contact screen
import 'package:image_picker/image_picker.dart'; //allows for use of images
import 'dart:io'; //allows for input/output file use
import 'package:camera/camera.dart';

late List<CameraDescription> _cameras;


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

String _suitSize=""; //store suit size
 bool _dataEntered = false; //track if data entered

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

  //image camera utility
  Future<void> _captureImageFromCamera() async{
    final PickedFile = await _picker.pickImage(source: ImageSource.camera);

    setState(() {
      _image = File(PickedFile!.path);
    });

  }

  //method to calculate suit size(for algorithm)
  String _calculateSuitSize(double height, double weight){
    if(height<160){
      return 'Small';
    }else if (height>=160&&height<175){
      return 'Medium';
    }else{
      return 'Large';
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
  Widget _buildFittingRoomTab() {
  return SingleChildScrollView(
    child: Column(
      children: [
      if(!_dataEntered) ...[
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

        // Body Type Selection Buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Column(
              children: [
                Text(
                  "Select Body Type:",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Wrap(
                  spacing: 8,
                  children: ['Skinny', 'Average', 'Athletic', 'Larger']
                      .map((type) => ChoiceChip(
                            label: Text(type, style: TextStyle(color: Colors.black)),
                            selected: selectedBodyType == type,
                            onSelected: (selected) {
                              setState(() {
                                selectedBodyType = selected ? type: '';
                              });
                            },
                          ))
                      .toList(),
                ),
              ],
            ),
          ),

          // Body Shape Selection Buttons
Padding(
  padding: const EdgeInsets.symmetric(horizontal: 8.0),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        "Select Body Shape:",
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      SizedBox(height: 8), // optional spacing
      Column(
        children: ['Slim', 
          'Small Chest/Large Waist', 
          'Large Chest/Small Waist', 
          'Large Chest/Large Waist']
            .map((type) => Padding(
              //Buttons are wrapped vertically for better presentation
                  padding: const EdgeInsets.symmetric(vertical: 4.0), 
                  child: ChoiceChip(
                    label: Text(type, style: TextStyle(color: Colors.black)),
                    selected: selectedBodyShape == type,
                    onSelected: (selected) {
                      setState(() {
                        selectedBodyShape = selected ? type : '';
                      });
                    },
                  ),
                ))
            .toList(),
      ),
    ],
  ),
),




        SizedBox(height: 10),
        _image != null 
          ? Image.file(_image!) 
          : Text("Image not selected",
          style: TextStyle(color:Colors.black)),
        ElevatedButton(
          onPressed: _pickImage,
          child: Text('Pick Image',
          style: TextStyle(color: Colors.black)), 
        ),
        ElevatedButton(
          onPressed: _captureImageFromCamera,
          child: Text('Camera',
          style: TextStyle(color: Colors.black)),
        ),
        ElevatedButton(
          onPressed: () {
            double height = double.tryParse(_heightController.text) ?? 0;
            double weight = double.tryParse(_weightController.text) ?? 0;
            String calculatedSuitSize = _calculateSuitSize(height, weight);
            setState(() {
              _suitSize = calculatedSuitSize;
              _dataEntered = true;
            });
          },
          child: Text('Enter Data',
          style: TextStyle(color: Colors.black)),
        ),
      ],

        // When data is entered, display the results
        if (_dataEntered) 
          Column(
            children: [
              SizedBox(height: 10),
              Text(
                'Height: ${_heightController.text} inches',
                style: TextStyle(fontSize: 16),
              ),
              Text(
                'Weight: ${_weightController.text} lbs',
                style: TextStyle(fontSize: 16),
              ),
              Text('Body Type: $selectedBodyType', style: TextStyle(fontSize: 16)),
              Text('Body Shape: $selectedBodyShape', style: TextStyle(fontSize: 16)),
              SizedBox(height: 10),
              _suitSize.isNotEmpty
                  ? Text(
                      'Predicted Suit Size: $_suitSize',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    )
                  : SizedBox.shrink(),
              SizedBox(height: 10),
              _image != null
                  ? Image.file(
                      _image!,
                      width: 150, // Make image smaller
                      height: 150, // Make image smaller
                      fit: BoxFit.cover,
                    )
                  : Text("No image selected"),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _dataEntered = false;
                    _heightController.clear();
                    _weightController.clear();
                    _suitSize = "";
                    _image = null;
                    selectedBodyType = '';
                    selectedBodyShape = '';
                  });
                },
                child: Text('Enter New Data'),
              ),
            ],
          ),
      ],
    ),
  );
}
  // Buttons for body type
  String selectedBodyType = '';
  String selectedBodyShape= '';

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
