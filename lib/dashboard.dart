import 'dart:convert';
import 'dart:io';
import 'package:blurry_modal_progress_hud/blurry_modal_progress_hud.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:path/path.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class CameraScreen extends StatefulWidget {
  final CameraDescription camera;

  CameraScreen({required this.camera});

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  List<Data> dataList = [];
  List<Data> filteredList = [];
  Future<String> imageToBase64(String imagePath) async {
    final bytes = await File(imagePath).readAsBytes();
    return base64Encode(bytes);
  }

  Future<void> postImageAndNokar(
      String imagePath, String nokar, BuildContext context) async {
    final String apiUrl =
        'https://api.rsummi.co.id:1843/insertabsen3'; // Ganti dengan URL endpoint Anda

    String base64Image = await imageToBase64(imagePath);

    final response = await http.post(
      Uri.parse(apiUrl),
      body: {
        'image': base64Image,
        'nokar': nokar,
      },
    );

    if (response.statusCode == 200 &&
        jsonDecode(response.body)['metadata']['code'] == 200) {
      setState(() {
        isloading = false;
      });

      print(jsonDecode(response.body));
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      scaffoldMessenger.showSnackBar(
        SnackBar(
          backgroundColor: Colors.green[400],
          content: Padding(
            padding: EdgeInsets.symmetric(
                vertical: 10.0), // Atur sesuai kebutuhan untuk mengubah tinggi
            child: Text(
              'Sukses Absensi',
              style: TextStyle(fontSize: 14),
            ),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      setState(() {
        isloading = false;
      });
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      scaffoldMessenger.showSnackBar(
        SnackBar(
          backgroundColor: Colors.red[400],
          content: Padding(
            padding: EdgeInsets.symmetric(
                vertical: 10.0), // Atur sesuai kebutuhan untuk mengubah tinggi
            child: Text(
              'Wajah Tidak Dikenal',
              style: TextStyle(fontSize: 14),
            ),
          ),
          behavior: SnackBarBehavior.floating,
          // Mengatur ketinggian Snackbar dari atas
        ),
      );
    }
  }

  TextEditingController searchController = TextEditingController();
  Future<List<String>> fetchNokarTerdaftar() async {
    final response = await http
        .post(Uri.parse('https://api.rsummi.co.id:9192/nokarTerdaftar'));

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      List<dynamic> data = jsonResponse['data'];
      return data.map((item) => item['nokar'].toString()).toList();
    } else {
      print('Error fetching nokarTerdaftar from API: ${response.statusCode}');
      return [];
    }
  }

  Future<void> fetchDataFromAPI() async {
    List<String> nokarList = await fetchNokarTerdaftar();

    for (String nokar in nokarList) {
      final response = await http
          .post(Uri.parse('https://api.rsummi.co.id:9192/getnokar'), body: {
        'nokar': nokar,
      });

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        List<dynamic> data = jsonResponse['data'];

        setState(() {
          dataList.addAll(data
              .map((item) => Data(name: item['NAMA'], nokar: item['NOKAR']))
              .toList());
          print(dataList.length);
        });
      } else {
        print('Error fetching data for nokar $nokar: ${response.statusCode}');
      }
    }
    setState(() {
      filteredList.addAll(dataList);
    });
  }

  @override
  void initState() {
    super.initState();
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.medium,
    );

    _initializeControllerFuture = _controller.initialize();

    // Dummy data
    fetchDataFromAPI();

    filteredList.addAll(dataList);

    searchController.addListener(() {
      filterSearchResults(searchController.text);
    });
  }

  void filterSearchResults(String query) {
    List<Data> dummySearchList = [];

    if (query.isNotEmpty) {
      dataList.forEach((item) {
        if (item.name.toLowerCase().contains(query.toLowerCase())) {
          dummySearchList.add(item);
        }
      });
      setState(() {
        filteredList.clear();
        filteredList.addAll(dummySearchList);
      });
      return;
    } else {
      setState(() {
        filteredList.clear();
        filteredList.addAll(dataList);
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  XFile? tmpic;
  String data = '';
  bool isloading = false;
  Future<void> kirimGambarKeServer(BuildContext context) async {
    setState(() {
      isloading = true;
      print(data);
    });

    // Ganti URL sesuai dengan alamat server Anda
    final url = Uri.parse('https://api.rsummi.co.id:8000/login2?text=$data');

    try {
      var request = http.MultipartRequest('POST', url);

      // Ganti 'file' sesuai dengan nama field yang digunakan di server
      request.files.add(await http.MultipartFile.fromPath('file', tmpic!.path));

      var response = await request.send();
      var responseData = await response.stream.toBytes();
      var responseString = String.fromCharCodes(responseData);
      var jsonResponse = json.decode(responseString);
      print("resnya : $jsonResponse");
      // Lakukan sesuatu dengan respons dari server
      if (response.statusCode == 200 &&
          jsonResponse['metadata']['code'] == 200) {
        var image = '';
        var status2 = '';
        setState(() {
          image = jsonResponse['response']['imagresult'];
          status2 = jsonResponse['response']['status2'];
          postImageAndNokar(tmpic!.path, data, context);
        });
        print(image);
      } else {
        setState(() {
          isloading = false;
        });
        var image = '';
        var status2 = '';
        setState(() {
          image = jsonResponse['response']['imagresult'];
          status2 = jsonResponse['response']['status2'];
        });
        final scaffoldMessenger = ScaffoldMessenger.of(context);
        scaffoldMessenger.showSnackBar(
          SnackBar(
            backgroundColor: Colors.red[400],
            content: Padding(
              padding: EdgeInsets.symmetric(
                  vertical:
                      10.0), // Atur sesuai kebutuhan untuk mengubah tinggi
              child: Text(
                'Wajah Tidak Dikenal',
                style: TextStyle(fontSize: 14),
              ),
            ),
            behavior: SnackBarBehavior.floating,
            // Mengatur ketinggian Snackbar dari atas
          ),
        );
      }
    } catch (error) {
      setState(() {
        isloading = false;
      });
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('$error'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlurryModalProgressHUD(
      inAsyncCall: isloading,
      blurEffectIntensity: 4,
      progressIndicator: SpinKitFadingCircle(
        color: Colors.blue[900],
        size: 90.0,
      ),
      dismissible: false,
      opacity: 0.4,
      color: Colors.black54,
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      Expanded(
                        child: FutureBuilder<void>(
                          future: _initializeControllerFuture,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.done) {
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(
                                    16.0), // Anda bisa mengganti angka ini sesuai kebutuhan
                                child: CameraPreview(_controller),
                              );
                            } else {
                              return Center(child: CircularProgressIndicator());
                            }
                          },
                        ),
                      )
                    ],
                  ),
                ),
                SizedBox(
                  height: 16,
                ),
                Expanded(
                    child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextField(
                        controller: searchController,
                        decoration: InputDecoration(
                          labelText: "Cari",
                          hintText: "Cari Berdasarkan Nama",
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                                15.0), // Sesuaikan nilai ini sesuai keinginan
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide:
                                BorderSide(color: Colors.blue, width: 1.0),
                            borderRadius: BorderRadius.circular(
                                15.0), // Sesuaikan nilai ini sesuai keinginan
                          ),
                        ),
                        onChanged: (value) {
                          filterSearchResults(value);
                        },
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: filteredList.length,
                        itemBuilder: (context, index) {
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                data = filteredList[index].nokar;
                              });
                              takePicture(context);
                            },
                            child: ListTile(
                              title: Text(filteredList[index].name),
                              // subtitle: Text(filteredList[index].nokar),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ) // Gantikan 'your_image.png' dengan path gambar Anda
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future takePicture(BuildContext context) async {
    if (!_controller.value.isInitialized) {
      return null;
    }
    if (_controller.value.isTakingPicture) {
      return null;
    }
    try {
      await _controller.setFlashMode(FlashMode.off);
      XFile picture = await _controller.takePicture();
      setState(() {
        tmpic = picture;
      });
      print(picture.path);

      kirimGambarKeServer(context);
    } on CameraException catch (e) {
      debugPrint('Error occured while taking picture: $e');
      return null;
    }
  }
}

class Data {
  final String name;
  final String nokar;

  Data({required this.name, required this.nokar});
}
