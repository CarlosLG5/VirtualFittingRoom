import 'package:flutter/material.dart'; //basic flutter package
import 'contact.dart'; //imports our contact screen
import 'package:image_picker/image_picker.dart'; //allows for use of images
import 'dart:io'; //allows for input/output file use
import 'dart:typed_data'; // Add this import for Float32List
import 'package:camera/camera.dart'; //camera use
import 'package:image/image.dart' as img; //image use
import 'package:tflite_flutter/tflite_flutter.dart'; //tflite use for model integration

//for camera use
late List<CameraDescription> _cameras;

//create HomeScreen
class HomeScreen extends StatefulWidget{
  const HomeScreen({Key? key}) : super(key : key);

  @override
  _HomeScreenState createState() => _HomeScreenState();

}  

//Variables are initialized such as image, height, weight
class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin{
  late TabController _tabController; //tab controller for switching windows
  final TextEditingController _heightController = TextEditingController(); //height input
  final TextEditingController _weightController = TextEditingController(); //weight input
  File? _image;
  final ImagePicker _picker = ImagePicker(); //image input

String _suitSize=""; //store suit size
 bool _dataEntered = false; //track if data entered
 Interpreter? _interpreter;
 bool _isModelLoaded = false;

  //initial state, load tabcontroller and loadmodel
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadModel();
  }

  /*
  This loads the model we have saved
  Currently, the model is saved in the 'assets/VFRmodel.tflite' directory in the project files
  Make sure you add the model path to assets in the pubspec.yaml
  */
  Future<void> _loadModel() async {
    try {
      final modelPath = 'assets/VFRmodel.tflite';
      _interpreter = await Interpreter.fromAsset(modelPath);
      setState(() {
        _isModelLoaded = true;
      });
      print('Model loaded successfully');
    } catch (e) {
      print('Failed to load model: $e');
    }
  }

  /*
  This function encodes the BodyType variable as a numeric value once input
  This allows it to be used easily later on for feature scaling
  */
  int encodeBodyType(String bodyType) {
    const Map<String, int> bodyTypeMap = {
      'Skinny': 0,
      'Average': 1,
      'Athletic': 2,
      'Larger': 3
    };
    return bodyTypeMap[bodyType] ?? -1;
  }

  //same purpose as encodeBodyType, allows for easier use when feature scaling
  int encodeBodyShape(String bodyShape) {
    const Map<String, int> bodyShapeMap = {
      'Slim': 0,
      'Small Chest/Large Waist': 1,
      'Large Chest/Small Waist': 2,
      'Large Chest/Large Waist': 3
    };
    return bodyShapeMap[bodyShape] ?? -1;
  }

  //this extracts image features and turns the picture into numbers to work with
  Future<List<double>> extractImageFeatures(File? imageFile) async {
    if (imageFile == null) {
      return List<double>.filled(224 * 224 * 3, 0.0); // Return zeros if no image
    }

    //load and resize image to 224x224 (this size was determined by the expected input shape)
    img.Image image = img.decodeImage(await imageFile.readAsBytes())!;
    img.Image resized = img.copyResize(image, width: 224, height: 224);

    //create a buffer for the RGB values in the correct shape [1, 224, 224, 3]
    List<double> imageFeatures = List<double>.filled(224 * 224 * 3, 0.0);
    int index = 0;

    //process each pixel
    for (int y = 0; y < 224; y++) {
      for (int x = 0; x < 224; x++) {
        final pixel = resized.getPixel(x, y);
        
        //extract RGB values and normalize to [0,1]
        imageFeatures[index++] = img.getRed(pixel) / 255.0;   // R channel
        imageFeatures[index++] = img.getGreen(pixel) / 255.0; // G channel
        imageFeatures[index++] = img.getBlue(pixel) / 255.0;  // B channel
      }
    }

    return imageFeatures;
  }

  /*
  The model outputs a decimal value
  We must convert the decimal prediction to a proper suit size
  This is our feature scaling
  */
  String convertToSuitSize(double prediction, double height, double weight, String bodyType, String bodyShape) {
    //base scaling (20-60, 60 based off of highest jacket size recorded in current dataset)
    final baseScaledPrediction = (prediction * 40.0) + 20.0;
    
    //adjust based on height and weight
    final heightAdjustment = (height - 70.0) * 0.5; //adjust by 0.5 size per inch above/below 70"
    final weightAdjustment = (weight - 180.0) * 0.1; //adjust by 0.1 size per pound above/below 180lbs
    
    //adjust based on body type
    double bodyTypeAdjustment = 0.0;
    switch (bodyType) {
      case 'Skinny':
        bodyTypeAdjustment = -1.0; //smaller size for skinny body type
      case 'Average':
        bodyTypeAdjustment = 0.0; //no adjustment for average
      case 'Athletic':
        bodyTypeAdjustment = 0.5; //slightly larger for athletic build
      case 'Larger':
        bodyTypeAdjustment = 1.5; //larger size for larger body type
      default:
        bodyTypeAdjustment = 0.0;
    }

    //adjust based on body shape
    double bodyShapeAdjustment = 0.0;
    switch (bodyShape) {
      case 'Slim':
        bodyShapeAdjustment = -0.5; //smaller size for slim shape
      case 'Small Chest/Large Waist':
        bodyShapeAdjustment = 0.5; //slightly larger for this shape
      case 'Large Chest/Small Waist':
        bodyShapeAdjustment = 0.0; //no adjustment needed
      case 'Large Chest/Large Waist':
        bodyShapeAdjustment = 1.0; //larger size for this shape
      default:
        bodyShapeAdjustment = 0.0;
    }
    
    final adjustedPrediction = baseScaledPrediction + 
                             heightAdjustment + 
                             weightAdjustment + 
                             bodyTypeAdjustment + 
                             bodyShapeAdjustment;
    
    //round to nearest whole number, can't have a decimal jacket size
    final roundedSize = adjustedPrediction.round();
    
    print('Raw prediction: $prediction');
    print('Base scaled prediction: $baseScaledPrediction');
    print('Height adjustment: $heightAdjustment');
    print('Weight adjustment: $weightAdjustment');
    print('Body type adjustment: $bodyTypeAdjustment');
    print('Body shape adjustment: $bodyShapeAdjustment');
    print('Final adjusted prediction: $adjustedPrediction');
    print('Rounded size: $roundedSize');

    //this attaches a letter to the number for the jacket size
    String sizeLetter;
    if (adjustedPrediction < 37) {
      sizeLetter = 'S';
    } else if (adjustedPrediction < 43) {
      sizeLetter = 'M';
    } else if (adjustedPrediction < 47) {
      sizeLetter = 'L';
    } else {
      sizeLetter = 'XL';
    }

    //return the value of (size)(letter)
    return '$roundedSize$sizeLetter';
  }

  /*
  This is the function that gets called when the 'Enter Data' button is pressed
  Gets all input variables
  Gives us our output
  */
  Future<String?> predictSize() async {
    if (!_isModelLoaded || _interpreter == null) {
      return 'Model not loaded';
    }

    try {
      //get model input and output details
      final inputTensor = _interpreter!.getInputTensor(0);
      final outputTensor = _interpreter!.getOutputTensor(0);
      print('Input shape: ${inputTensor.shape}');
      print('Output shape: ${outputTensor.shape}');

      final double height = double.parse(_heightController.text); //take the input text and save it as a double
      final double weight = double.parse(_weightController.text); //take the input text and save it as a double
      final imageFeatures = await extractImageFeatures(_image); //get workable numbers from the image

      //create input buffer with the correct shape [1, 224, 224, 3]. This can change based on the model used
      final inputBuffer = Float32List.fromList(imageFeatures);

      //create output buffer
      final outputBuffer = Float32List(1); //output shape is [1, 1] with the current model. Can also change based on the model

      //run the model
      _interpreter!.run(inputBuffer.buffer, outputBuffer.buffer);

      //process output
      final prediction = outputBuffer[0];
      
      //convert the prediction to a suit size category with all adjustments
      final suitSize = convertToSuitSize(prediction, height, weight, selectedBodyType, selectedBodyShape);
      return suitSize;
    } catch (e) {
      print('Error predicting size: $e');
      print('Stack trace: ${StackTrace.current}');
      return 'Error predicting size';
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
    final PickedFile = await _picker.pickImage(source: ImageSource.camera);

    setState(() {
      _image = File(PickedFile!.path);
    });

  }

  



  @override
  void dispose(){
    _interpreter?.close();
    _tabController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }
  //create widget for info input
  Widget _buildFittingRoomTab() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if(!_dataEntered) ...[
              Text(
                'Welcome to the Virtual Fitting Room!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
              ),
              SizedBox(height: 20),
              Text(
                'Enter your data to get started',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
              ),
              SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: TextFormField(
                  controller: _heightController,
                  decoration: InputDecoration(
                    labelText: 'Enter your height in inches',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: TextFormField(
                  controller: _weightController,
                  decoration: InputDecoration(
                    labelText: 'Enter your weight in lbs',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),

              //body Type Selection Buttons
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Column(
                  children: [
                    Text(
                      "Select Body Type",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                    Wrap(
                      spacing: 8,
                      children: ['Skinny', 'Average', 'Athletic', 'Larger']
                          .map((type) => ChoiceChip(
                                label: Text(type, style: TextStyle(color: selectedBodyType == type ? Colors.white : Colors.black)),
                                selected: selectedBodyType == type,
                                onSelected: (selected) {
                                  setState(() {
                                    selectedBodyType = selected ? type: '';
                                  });
                                },
                                backgroundColor: Colors.grey[200],
                                selectedColor: Colors.black,
                              ))
                          .toList(),
                    ),
                  ],
                ),
              ),

              //body Shape Selection Buttons
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      "Select Body Shape",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                    SizedBox(height: 8),
                    Column(
                      children: ['Slim', 'Small Chest/Large Waist', 'Large Chest/Small Waist', 'Large Chest/Large Waist']
                          .map((shape) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4.0),
                                child: ChoiceChip(
                                  label: Text(shape, style: TextStyle(color: selectedBodyShape == shape ? Colors.white : Colors.black)),
                                  selected: selectedBodyShape == shape,
                                  onSelected: (selected) {
                                    setState(() {
                                      selectedBodyShape = selected ? shape: '';
                                    });
                                  },
                                  backgroundColor: Colors.grey[200],
                                  selectedColor: Colors.black,
                                ),
                              ))
                          .toList(),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 10),
              Text(
                'Select or Take Picture',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
              ),
              SizedBox(height: 10),
              _image != null 
                ? Image.file(_image!, width: 150, height: 150, fit: BoxFit.cover) 
                : Text("Image not selected",
                style: TextStyle(color:Colors.black)),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: _pickImage,
                child: Text('Pick Image',
                style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: _captureImageFromCamera,
                child: Text('Camera',
                style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Get Your Size',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: () async {
                  String? suitSize = (await predictSize()) as String?;
                  setState(() {
                    _suitSize = suitSize!;
                    _dataEntered = true;
                  });
                },
                child: Text('Enter Data',
                style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
              ),
            ],

            //when data is entered, display the results
            if (_dataEntered) 
              Column(
                children: [
                  SizedBox(height: 10),
                  Text(
                    'Height: ${_heightController.text} inches',
                    style: TextStyle(fontSize: 16, color: Colors.black),
                  ),
                  Text(
                    'Weight: ${_weightController.text} lbs',
                    style: TextStyle(fontSize: 16, color: Colors.black),
                  ),
                  Text('Body Type: $selectedBodyType', style: TextStyle(fontSize: 16, color: Colors.black)),
                  Text('Body Shape: $selectedBodyShape', style: TextStyle(fontSize: 16, color: Colors.black)),
                  SizedBox(height: 10),
                  _suitSize.isNotEmpty
                      ? Text(
                          'Predicted Jacket Size: $_suitSize',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                        )
                      : SizedBox.shrink(),
                  SizedBox(height: 10),
                  _image != null
                      ? Image.file(
                          _image!,
                          width: 150, //make image smaller
                          height: 150, //make image smaller
                          fit: BoxFit.cover,
                        )
                      : Text("No image selected", style: TextStyle(color: Colors.black)),
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
                    child: Text('Enter New Data', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
  //buttons for body type
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
      body: Column(
        children: [
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildFittingRoomTab(),
                ContactScreen(),
              ],
            ),
          ),
        ],
      ),
      backgroundColor: Colors.white,
    );
  }
}
