import 'package:HyperBeam/createQuiz.dart';
import 'package:HyperBeam/explorePage.dart';
import 'package:HyperBeam/quizHandler.dart';
import 'package:HyperBeam/widgets/atAGlance.dart';
import 'package:HyperBeam/widgets/designConstants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:HyperBeam/progressChart.dart';
import 'package:HyperBeam/fileHandler.dart';
import 'package:provider/provider.dart';
import 'package:HyperBeam/services/firebase_auth_service.dart';
import 'package:flutter/services.dart';

class HomePage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  PageController _controller = PageController(
    initialPage: 0,
  );

  void _signOut(BuildContext context) async {
    try {
      final auth = Provider.of<FirebaseAuthService>(context);
      await auth.signOut();
    } catch (err) {
      print(err);
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIOverlays([SystemUiOverlay.bottom]);//hides the app bar above
    var size = MediaQuery.of(context).size;
    final user = Provider.of<User>(context, listen: false);
    return WillPopScope(
      onWillPop: () async => false,
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/images/bg2.jpg"),
                fit: BoxFit.fill,
              ),
            ),
          ),
          PageView(
              scrollDirection: Axis.vertical,
              controller: _controller,
              children: [
                Scaffold(
                    backgroundColor: Colors.transparent,
                    body: SingleChildScrollView(
                        padding: EdgeInsets.only(left: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: <Widget>[
                                /*
                                Padding(
                                  padding: const EdgeInsets.only(top:10, left:12),
                                  child: RichText(
                                      textAlign: TextAlign.left,
                                      text: TextSpan(
                                          style: Theme.of(context).textTheme.headline5,
                                          children: [
                                            TextSpan(text: "Hi, ", style: TextStyle(fontSize: kExtraBigText)),
                                            TextSpan(text: "${user.lastName ?? ""}", style: TextStyle(fontSize: kExtraBigText,fontWeight: FontWeight.bold))
                                          ]
                                      )
                                  ),
                                ),*/
                                Spacer(),
                                FlatButton(
                                  child: new Text('Logout'),
                                  onPressed: () => _signOut(context),
                                ),
                              ],
                            ),
                            Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 24),
                                child: RichText(
                                    textAlign: TextAlign.left,
                                    text: TextSpan(
                                        style: Theme.of(context).textTheme.headline5,
                                        children: [
                                          TextSpan(text: "What are you \ndoing "),
                                          TextSpan(text: "today?", style: TextStyle(fontWeight: FontWeight.bold))
                                        ]
                                    )
                                )
                            ),
                            SizedBox(height: size.height * .02),
                            ProgressChart(),
                            SizedBox(height: size.height * .01),
                            Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 24),
                                child: RichText(
                                    textAlign: TextAlign.left,
                                    text: TextSpan(
                                        style: Theme.of(context).textTheme.headline5,
                                        children: [
                                          TextSpan(text: "At a "),
                                          TextSpan(text: "glance...", style: TextStyle(fontWeight: FontWeight.bold))
                                        ]
                                    )
                                )
                            ),
                            AtAGlance(screenHeight: size.height, screenWidth: size.width),
                            SizedBox(height: size.height * .02),
                          ],
                        )
                    )
                ),
                ExplorePage(),
              ]
          ),
        ]
      ),
    );
  }
}