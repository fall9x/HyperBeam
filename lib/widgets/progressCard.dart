import 'dart:convert';
import 'package:HyperBeam/moduleDetails.dart';
import 'package:HyperBeam/objectClasses.dart';
import 'package:HyperBeam/progressChart.dart';
import 'package:HyperBeam/quizHandler.dart';
import 'package:HyperBeam/services/firebase_module_service.dart';
import 'package:HyperBeam/services/firebase_task_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:HyperBeam/widgets/designConstants.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../objectClasses.dart';
import '../routing_constants.dart';

class ProgressCard extends StatelessWidget {
  final String moduleCode;
  final String title;
  final int score;
  final int fullScore;
  final List<Quiz> quizList;
  final Size size;
  final List<Task> taskList;
  final Function pressCreateQuiz;
  final Function pressCreateTask;
  final DocumentSnapshot snapshot;

  const ProgressCard({
    Key key,
    this.moduleCode,
    this.title,
    this.score,
    this.fullScore,
    this.quizList,
    this.size,
    this.taskList,
    this.pressCreateQuiz,
    this.pressCreateTask,
    this.snapshot,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    int quizCount = snapshot.data['quizzes'].length;
    int taskCount = snapshot.data['tasks'].length;

    return GestureDetector(
      onTap: () async {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) {
            return ModuleDetails(moduleCode);
          })
        );
      },
      child: Container(
        margin: EdgeInsets.only(left: 8, bottom: 40, right: 8),
        height: 304,
        width: 0.6*size.width,
        child: Stack(
          children: <Widget>[
            Positioned(
              child: Container(
                height: 304,
                decoration: BoxDecoration(
                  color: Color(0xFFFFFFFF),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      offset: Offset(0, 10),
                      blurRadius: 16,
                      color: kShadowColor,
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              right: 10,
              top: 10,
              child: GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text("WARNING"),
                          content: Text("Delete this module and all of its contents permanently?"),
                          actions: <Widget>[
                            FlatButton(
                                child: Text("Cancel"),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                }
                            ),
                            FlatButton(
                                child: Text("Delete"),
                                onPressed: () async{
                                  final moduleRepository = Provider.of<FirebaseModuleService>(context).getRepo();
                                  moduleRepository.delete(snapshot);
                                  Navigator.of(context).pop();
                                  CollectionReference reminderRepo = Firestore.instance.collection("Reminders");
                                  CollectionReference taskReminderRepo = Firestore.instance.collection("TaskReminders");
                                  List<DocumentSnapshot> lst = await reminderRepo.where("moduleName", isEqualTo: moduleCode)
                                      .getDocuments().then((value) => value.documents);
                                  for(DocumentSnapshot doc in lst) {
                                    reminderRepo.document(doc.documentID).delete();
                                  }
                                  List<DocumentSnapshot> lst2 = await taskReminderRepo.where("moduleCode", isEqualTo: moduleCode)
                                      .getDocuments().then((value) => value.documents);
                                  for(DocumentSnapshot doc in lst2) {
                                    taskReminderRepo.document(doc.documentID).delete();
                                  }
                                }
                            )
                          ],
                        );
                      }
                    );
                  },
                  child: Icon(Icons.brightness_1, color: Colors.red),
              ),
            ),
            Positioned(
              top: 30,
              child: Container(
                width: size.width*0.6,
                height: 274,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Padding(
                      padding: EdgeInsets.only(left: 24),
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(color: Colors.black),
                          children: [
                            TextSpan(
                              text: "$moduleCode\n",
                              style: TextStyle(
                                fontSize: kBigText,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ]
                        )
                      )
                    ),
                    Padding(
                        padding: EdgeInsets.only(left: 24,),
                        child: RichText(
                            text: TextSpan(
                                style: TextStyle(color: Colors.black),
                                children: [
                                  TextSpan(
                                    text: "$title\n",
                                    style: TextStyle(
                                      fontSize: kMediumText,
                                    ),
                                  ),
                                ]
                            )
                        )
                    ),
                    Spacer(),
                    Row(
                      children: [
                        Padding(
                            padding: EdgeInsets.only(left: 24),
                            child: RichText(
                                text: TextSpan(
                                    style: TextStyle(color: Colors.black),
                                    children: [
                                      TextSpan(
                                        text: "Tasks:",
                                        style: TextStyle(
                                          fontSize: kSmallText,
                                        ),
                                      ),
                                    ]
                                )
                            )
                        ),
                        Spacer(),
                        Padding(
                            padding: EdgeInsets.only(right: 24),
                            child: Text("$taskCount"),
                        ),
                      ]
                    ),
                    Spacer(),
                    Row(
                      children: [
                        Padding(
                            padding: EdgeInsets.only(left: 24),
                            child: RichText(
                                text: TextSpan(
                                    style: TextStyle(color: Colors.black),
                                    children: [
                                      TextSpan(
                                        text: "Quizzes:", //todo: uncompleted quiz
                                        style: TextStyle(
                                          fontSize: kSmallText,
                                        ),
                                      ),
                                    ]
                                )
                            )
                        ),
                        Spacer(),
                        Padding(
                            padding: EdgeInsets.only(right: 24),
                            child: Text("$quizCount"),
                        ),
                      ],
                    ),
                    Spacer(),
                    Row(
                      children: <Widget>[
                        Expanded(
                            child: LeftTwoSideRoundedButton(text:"Create task", press: pressCreateTask)
                        ),
                        Expanded(
                            child: RightTwoSideRoundedButton(text:"Create quiz", press: pressCreateQuiz)
                        ),
                      ],
                    )
                  ],
                )
              )
            )
          ],
        ),
      ),
    );
  }
}


class ProgressAdditionCard extends StatefulWidget {
  final Size size;
  const ProgressAdditionCard({
    this.size,
  });

  @override
  State<StatefulWidget> createState() => _ProgressAdditionCardState();
}

class _ProgressAdditionCardState extends State<ProgressAdditionCard> {
  String moduleName;
  final moduleFormKey = new GlobalKey<FormState>();
  DocumentSnapshot moduleCodes;
  bool validateAndSave() {
    final form = moduleFormKey.currentState;
    if(form.validate()) {
      form.save();
      return true;
    } else {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        return showDialog(
          context: context,
          builder: (BuildContext context) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius:  BorderRadius.circular(20.0)
              ),
              backgroundColor: kSecondaryColor,
              child: Container(
                height: 300,
                child: Column(
                  children: [
                    Spacer(),
                    RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: TextStyle(color: Colors.black, fontSize: kExtraBigText),
                          text: "Add a new module",
                        )
                    ),
                    Spacer(),
                    Form(
                      key: moduleFormKey,
                      autovalidate: true,
                      child: Container(
                        width: 200,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: <Widget>[
                            TextFormField(
                              validator: (val) {
                                return !NUS_MODULES.containsCode(val)? "Module not found": null;
                              },
                              autofocus: true,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(),
                                hintText: "Enter a module code",
                              ),
                              onSaved: (text) {
                                setState(() {
                                  moduleName = text;
                                });
                              },
                            ),
                            SizedBox(height: 64),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                FlatButton(
                                    child: Text("Cancel"),
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    }
                                ),
                                RaisedButton(
                                  child: Text("Add"),
                                  color: kAccentColor,
                                  onPressed: () {
                                    if(validateAndSave()){
                                      final moduleRepository = Provider.of<FirebaseModuleService>(context).getRepo();
                                      Module newModule = NUS_MODULES.getModule(moduleName);
                                      Navigator.of(context).pop();
                                      moduleRepository.addDocByID(newModule.moduleCode, newModule);
                                    }
                                  },
                                )
                              ],
                            ),
                            SizedBox(height: 10),
                          ],
                        ),
                      )
                    ),
                  ]
                ),
              ),
            );
          },
        );
      },
      child: Container(
        margin: EdgeInsets.only(left: 8, bottom: 40, right: 8),
        height: 304,
        width: 0.6*widget.size.width,
        child: Stack(
          children: <Widget>[
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                child: Center(
                  child: Icon(Icons.add),
                ),
                height: 288,
                decoration: BoxDecoration(
                  color: Color(0xFFFFFFFF),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      offset: Offset(0, 8),
                      blurRadius: 8,
                      color: kShadowColor,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RightTwoSideRoundedButton extends StatelessWidget {
  final String text;
  final double radius;
  final Function press;
  const RightTwoSideRoundedButton({
    Key key,
    this.text,
    this.radius = 24,
    this.press,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: press,
      child: Container(
        alignment: Alignment.center,
        padding: EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: kAccentColor,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(radius),
            bottomRight: Radius.circular(radius),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(color: Colors.black),
        ),
      ),
    );
  }
}
class LeftTwoSideRoundedButton extends StatelessWidget {
  final String text;
  final double radius;
  final Function press;
  const LeftTwoSideRoundedButton({
    Key key,
    this.text,
    this.radius = 24,
    this.press,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: press,
      child: Container(
        alignment: Alignment.center,
        padding: EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: kSecondaryColor,
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(radius),
            bottomLeft: Radius.circular(radius),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(color: Colors.black),
        ),
      ),
    );
  }
}

class Args{
  List<dynamic> quizList;
  List<dynamic> taskList;
  DocumentSnapshot moduleSnapshot;

  Args({this.quizList,this.taskList,this.moduleSnapshot});
  @override
  toString() {
    return "${quizList.length} and  ${taskList.length} and ${moduleSnapshot.toString}";
  }
}
