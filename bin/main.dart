import 'dart:io';

import 'package:wit_app/wit_app.dart' as wit_app;

void main(List<String> arguments) async {
  while(true){
    print("What's your request?");
    var message = stdin.readLineSync();
    print('Loading...');
    await wit_app.parseRequestwithWit(message);
  }
}
