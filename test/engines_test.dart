import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:yolo_app/data/repository.dart';

void main() {
  test('decision selection accepts boundaries and returns an option', () {
    expect(['a','b'].contains(chooseOption(['a','b'],random:Random(2))),isTrue);
    expect(chooseOption(List.generate(12,(i)=>'$i'),random:Random(1)),isNotEmpty);
  });
  test('decision selection rejects fewer than 2 and more than 12', () {
    expect(()=>chooseOption(['only']),throwsArgumentError);
    expect(()=>chooseOption(List.generate(13,(i)=>'$i')),throwsArgumentError);
  });
  test('recommendations enforce time, budget and environment hard constraints', () {
    final result=recommendMission(missions,mood:'Happy',minutes:15,budget:0,environment:'Indoor',category:'Creative',random:Random(1));
    expect(result.duration,lessThanOrEqualTo(15));
    expect(result.budget,0);
    expect(['Indoor','Both'].contains(result.environment),isTrue);
  });
  test('mood, preference and weighted compatibility rank expected mission first', () {
    final a=missions.firstWhere((m)=>m.id=='m01');
    final selected=recommendMission([a,missions.firstWhere((m)=>m.id=='m02')],mood:'Creative',minutes:15,budget:0,environment:'Indoor',category:'Creative',random:Random(0));
    expect(selected.id,'m01');
  });
  test('throws a useful state error when no mission fits hard constraints', () {
    expect(()=>recommendMission(missions,mood:'Lazy',minutes:5,budget:0,environment:'Indoor',category:'Fitness',random:Random(1)),returnsNormally);
    expect(()=>recommendMission([missions.firstWhere((m)=>m.id=='m02')],mood:'Happy',minutes:5,budget:0,environment:'Indoor',category:'Creative'),throwsStateError);
  });
}
