import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_html/flutter_html.dart';

class GetUserName extends StatelessWidget {
  final String documentId;
  final FirebaseFirestore db = FirebaseFirestore.instance;

  GetUserName(this.documentId);

  Future<DocumentSnapshot> _getUser() {
    return db.collection('users').doc(documentId).get();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: _getUser(),
      builder:
          (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
        // ...
        if (snapshot.connectionState == ConnectionState.done) {
          Map<String, dynamic> data = snapshot.data.data();
          return Text('Full Name: ${data['first_name']} ${data['last_name']}');
        }
        return CircularProgressIndicator();
      },
    );
  }
}

class GetAllUsers extends StatelessWidget {
  final FirebaseFirestore db = FirebaseFirestore.instance;

  Future<List<QueryDocumentSnapshot>> _getAllUsers() {
    return db.collection('users').get().then(
        (value) => value.docs); // Map the query result to the list of documents
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<QueryDocumentSnapshot>>(
      future: _getAllUsers(),
      builder: (BuildContext context,
          AsyncSnapshot<List<QueryDocumentSnapshot>> snapshot) {
        // ...
        if (snapshot.connectionState == ConnectionState.done) {
          List<QueryDocumentSnapshot> data = snapshot.data;
          print(data);
          return SizedBox(
            height: 200.0,
            child: ListView.separated(
                itemBuilder: (context, index) {
                  final Map<String, dynamic> item = data[index].data();
                  return ListTile(
                    title: Text(
                        '${item['first_name']} ${item['last_name']}, ${item['occupation']}'),
                  );
                },
                separatorBuilder: (_, __) => Divider(),
                itemCount: data.length),
          );
        }
        return CircularProgressIndicator();
      },
    );
  }
}

class GetUserNameRealtime extends StatelessWidget {
  final String documentId;
  final FirebaseFirestore db = FirebaseFirestore.instance;

  GetUserNameRealtime(this.documentId);

  Stream<DocumentSnapshot> _getUser() {
    return db.collection('users').doc(documentId).snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: _getUser(),
      builder:
          (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
        // ...
        if (snapshot.hasData) {
          Map<String, dynamic> data = snapshot.data.data();
          return Text('Full Name: ${data['first_name']} ${data['last_name']}');
        }
        return CircularProgressIndicator();
      },
    );
  }
}

class GetAllUsersRealtime extends StatelessWidget {
  final FirebaseFirestore db = FirebaseFirestore.instance;

  Stream<List<QueryDocumentSnapshot>> _getAllUsers() {
    return db.collection('users').snapshots().map(
        (value) => value.docs); // Map the query result to the list of documents
  }

  Future<void> _deleteUser(String userId) {
    return db.collection('users').doc(userId).delete();
  }

  Future<void> _updateUserOccupation(String userId, String newOccupation) {
    return db
        .collection('users')
        .doc(userId)
        .update({'occupation': newOccupation});
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<QueryDocumentSnapshot>>(
      stream: _getAllUsers(),
      builder: (BuildContext context,
          AsyncSnapshot<List<QueryDocumentSnapshot>> snapshot) {
        // ...
        if (snapshot.hasData) {
          final List<QueryDocumentSnapshot> data = snapshot.data;
          return SizedBox(
            height: 200.0,
            child: ListView.separated(
                itemBuilder: (context, index) {
                  final Map<String, dynamic> item = data[index].data();
                  final userId = data[index].id;
                  return ListTile(
                    title: Text(
                        '${item['first_name']} ${item['last_name']}, ${item['occupation']}'),
                    leading: IconButton(
                      icon: Icon(Icons.thumb_down),
                      onPressed: () {
                        _updateUserOccupation(userId, 'Unemployed');
                      },
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.delete_outline),
                      onPressed: () {
                        _deleteUser(userId);
                      },
                    ),
                  );
                },
                separatorBuilder: (_, __) => Divider(),
                itemCount: data.length),
          );
        }
        return CircularProgressIndicator();
      },
    );
  }
}

class CloudStorageUploader extends StatefulWidget {
  @override
  _CloudStorageUploaderState createState() => _CloudStorageUploaderState();
}

class _CloudStorageUploaderState extends State<CloudStorageUploader> {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  static const FILE_NAME = 'avatar.png';

  String _imageUrl;

  Future<String> _getImageUrl(String name) {
    return _storage.ref('images').child(name).getDownloadURL();
  }

  Future<String> _uploadNewImage(File file, String name) {
    return _storage
        .ref('images')
        .child(name)
        .putFile(file)
        .then((snapshot) => snapshot.ref.getDownloadURL());
  }

  @override
  void initState() {
    super.initState();
    _getImageUrl(FILE_NAME).then((value) => setState(() {
          _imageUrl = value;
        }));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _imageUrl == null
                    ? SizedBox(
                        width: 60.0,
                        height: 60.0,
                        child: Center(child: CircularProgressIndicator()))
                    : Image.network(
                        _imageUrl,
                        height: 60.0,
                        width: 60.0,
                      ),
                VerticalDivider(),
                RaisedButton.icon(
                  icon: Icon(Icons.cloud_upload),
                  label: Text('Upload new'),
                  onPressed: () async {
                    // Pick an image with the file_picker library
                    FilePickerResult result = await FilePicker.platform
                        .pickFiles(type: FileType.image);

                    if (result != null) {
                      File file = File(result.files.single.path);
                      setState(() {
                        _imageUrl = null;
                      });
                      _imageUrl = await _uploadNewImage(file, FILE_NAME);
                      setState(() {});
                    }
                  },
                )
              ],
            ),
            SizedBox(
              height: 30,
            ),
            Html(
                data:
                    'Icons made by <a href="https://www.flaticon.com/authors/freepik" title="Freepik">Freepik</a> from <a href="https://www.flaticon.com/" title="Flaticon"> www.flaticon.com</a>'),
          ],
        ),
      ),
    );
  }
}
