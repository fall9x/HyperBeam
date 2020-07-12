import 'package:HyperBeam/objectClasses.dart';
import 'package:HyperBeam/quizResultPage.dart';
import 'package:HyperBeam/services/firebase_module_service.dart';
import 'package:HyperBeam/services/firebase_quizAttempt_service.dart';
import 'package:HyperBeam/services/firebase_quiz_service.dart';
import 'package:HyperBeam/widgets/designConstants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:HyperBeam/quizHandler.dart';
import 'package:HyperBeam/routing_constants.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';

class AttemptQuiz extends StatefulWidget {
  DocumentSnapshot snapshot;
  Module module;
  AttemptQuiz({this.snapshot, this.module});

  @override
  State<StatefulWidget> createState() => _AttemptQuizState(quiz: Quiz.fromSnapshot(snapshot));
}

class _AttemptQuizState extends State<AttemptQuiz> {
  Quiz quiz;
  List<String> _givenAnswers = new List(10);
  int index = 0;
  _AttemptQuizState({this.quiz});

  Widget _buildRow(int ind) {
    if(quiz.questions[ind] == null) {
      return new Form(
        child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Padding(
                padding: EdgeInsets.only(top: 80),
                child: RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: TextStyle(color: Colors.black, fontSize: kExtraBigText),
                      text: "You have reached the end of quiz",
                    )
                ),
              ),
              Padding(
                padding: EdgeInsets.only(top: 24),
                child: RaisedButton(
                  child: Text("Submit"),
                  color: kAccentColor,
                  onPressed: () async {
                    final quizRepository = Provider.of<FirebaseQuizService>(context).getRepo();
                    final quizAttemptRepository = Provider.of<FirebaseQuizAttemptService>(context).getRepo();
                    int fullScore = 0;
                    int quizScore = 0;
                    for(int i = 0; i < 10; i++) {
                      if(quiz.questions[i] != null) {
                        fullScore++;
                        if(quiz.answers[i] == _givenAnswers[i]){
                          quizScore++;
                        }
                      }
                    }
                    quiz.score = quizScore;
                    QuizAttempt currAttempt = QuizAttempt(
                      date: DateTime.now(),
                      givenAnswers: _givenAnswers,
                      quiz: quiz,
                      score: quizScore,
                    );
                    DocumentReference currAttemptRef = await quizAttemptRepository.addDoc(currAttempt);
                    print(quiz.attempts);
                    var quizAttempts = quiz.attempts == null ? null:List.from(quiz.attempts);
                    quizAttempts == null ?
                    quizAttempts = List.from([currAttemptRef]) : quizAttempts.add(currAttemptRef);
                    print("ATTEMPT IS $currAttemptRef");
                    quiz.attempts = quizAttempts;
                    quizRepository.updateDoc(quiz);
                    Navigator.push(context,
                      MaterialPageRoute(builder: (context) {
                        return QuizResultPage(
                          quiz: quiz,
                          givenAnswers: _givenAnswers,
                          fullScore: fullScore,
                          quizScore: quizScore,
                          module: widget.module,
                        );
                      }),
                    );
                  },
                ),
              ),
            ],
        ),
      );
    } else {
      var controller1 = TextEditingController();
      return new Form(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Padding(
                  padding: EdgeInsets.only(top:24, left: 16),
                  child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                          style: Theme.of(context).textTheme.headline4,
                          children: [
                            TextSpan(text: "Question "),
                            TextSpan(text: "${index+1}\n", style: TextStyle(fontWeight: FontWeight.bold)),
                          ]
                      )
                  ),
              ),
              Padding(
                padding: EdgeInsets.only(top:24, left: 16),
                child: RichText(
                    textAlign: TextAlign.left,
                    text: TextSpan(
                        style: Theme.of(context).textTheme.headline5,
                        children: [
                          TextSpan(text: quiz.questions[ind]),
                        ]
                    )
                ),
              ),
              SizedBox(height: 30,),
              Padding(
                padding: EdgeInsets.only(top:24, left: 64),
                child: TextFormField(
                  autofocus: true,
                  controller: controller1,
                  decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: (ind+1).toString() + '   Enter your answer here'
                  ),
                  onChanged: (val) => _givenAnswers[ind] = val,
                ),
              ),
              SizedBox(height: 48),
              RaisedButton(
                color: kAccentColor,
                child: Text("Next Question"),
                onPressed: () {
                  setState(() {
                    index++;
                    controller1.clear();
                  });
                },
              ),
            ]
          ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pushNamed(
          context,
          ModuleDetailsRoute,
          arguments: widget.module,
        );
        return true;
      },
      child: Scaffold(
        body: Stack(
          children: [
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage("assets/images/bg1.jpg"),
                  fit: BoxFit.fill,
                ),
              ),
            ),
            Column(
              children: <Widget>[
                _buildRow(index),
              ],
            ),
          ]
        ),
      ),
    );
  }
}