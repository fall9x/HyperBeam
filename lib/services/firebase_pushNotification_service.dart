import 'dart:async';
import 'dart:io';
import 'package:HyperBeam/homePage.dart';
import 'package:HyperBeam/services/firebase_auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class PushNotificationService {
  User user;
  final FirebaseMessaging _fcm = FirebaseMessaging();
  StreamSubscription iosSubscription;
  BuildContext context;
  PushNotificationService({this.user, this.context});

  saveDeviceToken() async {
    user = Provider.of<User>(context);

    String fcmToken = await _fcm.getToken();

    if (fcmToken != null) {
      User newUser = User(
        id: user.id,
        name: user.name,
        email: user.email,
        ref: user.ref,
        createdAt: FieldValue.serverTimestamp(),
        platform: Platform.operatingSystem,
        token: fcmToken,
      );
      await user.getRepo().setDocByID(user.id, newUser.toJson());
    }
  }

  initialise() {
    user = Provider.of<User>(context);
    if (Platform.isIOS) {
      iosSubscription = _fcm.onIosSettingsRegistered.listen((event) {
        saveDeviceToken();
      });
      _fcm.requestNotificationPermissions(IosNotificationSettings());
    } else {
      saveDeviceToken();
    }
    FirebaseMessaging().getToken().then((value) => print("CURR TOKEN IS $value"));
    _fcm.configure(
      onMessage: (Map<String, dynamic> message) async {
        print("onMessage: $message");
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            content: ListTile(
              title: Text(message['notification']['title']),
              subtitle: Text(message['notification']['body']),
            ),
            actions: <Widget>[
              FlatButton(
                child: Text('Ok'),
                onPressed: () {
                  if(message.containsKey('data')){
                    print("DATA FOUND");
                    final dynamic data = message['data'];
                    print(data['link']);
                    obtainPDFfromLink(data['link']);
                  }
                  Navigator.of(context).pop();
                }
              ),
            ],
          ),
        );
      },
      onLaunch: (Map<String, dynamic> message) async {
        print("onLaunch: $message");
        //_serialiseAndNavigate(message);
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            content: ListTile(
              title: Text(message['notification']['title']),
              subtitle: Text(message['notification']['body']),
            ),
            actions: <Widget>[
              FlatButton(
                  child: Text('Okdddd'),
                  onPressed: () {
                    if(message.containsKey('data')){
                      print("DATA FOUND");
                      final dynamic data = message['data'];
                      print(data['link']);
                      obtainPDFfromLink(data['link']);
                    }
                    Navigator.of(context).pop();
                  }
              ),
            ],
          ),
        );
        },
      onResume: (Map<String, dynamic> message) async {
        print("onResume: $message");
        //_serialiseAndNavigate(message);
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            content: ListTile(
              title: Text(message['notification']['title']),
              subtitle: Text(message['notification']['body']),
            ),
            actions: <Widget>[
              FlatButton(
                  child: Text('Okresume'),
                  onPressed: () {
                    if(message.containsKey('data')){
                      print("DATA FOUND");
                      final dynamic data = message['data'];
                      print(data['link']);
                      obtainPDFfromLink(data['link']);
                    }
                    Navigator.of(context).pop();
                  }
              ),
            ],
          ),
        );
      },
    );
  }

  void obtainPDFfromLink(String uri) async {

    if (await canLaunch(uri.toString())) {
      await launch(uri.toString());
    } else {
      throw 'Could not launch $uri';
    }
  }

  void _serialiseAndNavigate(Map<String, dynamic> message) {
    var notificationData = message['data'];
    var view = notificationData['view'];
    Navigator.push(context, MaterialPageRoute(builder: (context) => HomePage()));
    if(notificationData != null) {
      final dynamic data = message['data'];
      obtainPDFfromLink(data['link']);
    }
    /*
    if (view != null) {
      // Navigate to the create post view
      if (view == 'create_post') {
        Navigator.push(context, MaterialPageRoute(builder: (context) => HomePage()));
      }
      // If there's no view it'll just open the app on the first view
    }
     */
  }
}