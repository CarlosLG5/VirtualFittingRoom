import 'package:flutter/material.dart';
import 'contact.dart'; //imports our contact screen
import 'package:image_picker/image_picker.dart'; //allows for use of images
import 'dart:io'; //allows for input/output file use
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

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
  Interpreter? _interpreter; //interpreter for our model

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    loadModel();
  }

  //load model, return the result
  void loadModel() async{
    try{
      _interpreter = await Interpreter.fromAsset('assets/VFRmodel.tflite');
      print("model loaded successfully");
      var inputTensors = _interpreter!.getInputTensors();
      for (var i = 0; i < inputTensors.length; i++) {
        print("Input tensor $i: shape: ${inputTensors[i].shape}, type: ${inputTensors[i].type}");
      }
    }catch(e){
      print("failed to load model");
    }
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
    final pickedFile = await _picker.pickImage(source: ImageSource.camera);
    if(pickedFile != null){
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  //preprocess the image
  Future<img.Image?> preprocessImage(File image) async{
    img.Image imageTemp = img.decodeImage(image.readAsBytesSync())!;
    img.Image resizedImg = img.copyResize(imageTemp, width: 220, height: 220);//change values as needed
    return resizedImg;
  }

  //putting the model to use hopefully
  void predictSuitSize() async{
    if(_image != null && _heightController.text.isNotEmpty && _weightController.text.isNotEmpty){
      double height = double.parse(_heightController.text); //parse to get height
      double weight = double.parse(_weightController.text); //parse to get weight
      var imageInput = await preprocessImage(_image!); //image use
      
      if(imageInput != null){
        List<double> imageList = imageInput.data.map((pixel) => (img.getRed(pixel) + img.getGreen(pixel) + img.getBlue(pixel)) / 3.0 / 255.0).toList();
        var input = [height, weight] + imageList;
        var output = List.filled(1, 0.0);

        _interpreter?.run(input, output); //when button is pressed to display output, this gives an error. states it failed prerequisite checks.
        String result = output[0].toString();

        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text("Predicted Suit Size"),
            content: Text(result),
          )
        );
      }else{
        print("image is null");
      }
    }else{
      print("image or else is null");
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
          ElevatedButton(onPressed: _pickImage,child: Text('Pick Image'),),
          ElevatedButton(onPressed: _captureImageFromCamera , child: Text('Camera'),),
          ElevatedButton(onPressed: predictSuitSize, child: Text("Predict Size"),) //runs the model
        ],
      ),
    );



  }

  //appbar at the top
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
