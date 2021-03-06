import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

const String base = 'https://api.wit.ai/message?v=20200626&q=';
const String authHeader = 'Bearer 7OMNNIJAZNU4JPCU2OBR6YEQA2RDQVEG';
const String API_KEY = '16af99bd1c012623ee0930bf9ebbb4b9';

void parseRequestwithWit(String message) async {
  var url = base + message;
  var response = await http
      .get(url, headers: {HttpHeaders.authorizationHeader: authHeader});

  var data = jsonDecode(response.body);

  var maxConf = 0.0;
  var intentName = '';

  for (var intent in data['intents']) {
    if (maxConf < intent['confidence']) {
      maxConf = intent['confidence'];
      intentName = intent['name'];
    }
  }

  // print(data);

  switch (intentName) {
    case 'weather':
      var locations = parseCities(data['entities']['wit\$location:location']);
      if (locations == null) {
        print('Locations does not found');
        return;
      }
      for (var location in locations) {
        if (location.hasFound) {
          var weather = await getWeatherInfo(location);
          if (weather == null) {
            print('No weather information is found');
          } else {
            print(weather.toString());
          }
        } else {
          print('Location ${location.name} was not found');
        }
      }
      break;
    case 'time':
      // print('Hello Time');
      var locations = parseCities(data['entities']['wit\$location:location']);
      if (locations == null) {
        print('Locations does not found');
        return;
      }
      for (var location in locations) {
        var time = await getTime(location);
        if (time == null) {
          print('No time information is found');
        } else {
          print("It's ${time} in ${location.name}");
        }
      }
      break;
    default:
      print('No action found');
      break;
  }
}

class City {
  String name;
  double long;
  double lat;
  String timezone;
  bool hasFound;

  City() {
    name = null;
    long = null;
    lat = null;
    hasFound = null;
  }

  @override
  String toString() {
    return '$name';
  }
}

class Weather {
  String city;
  String desc;
  num temp;
  bool isNow;
  DateTime date;

  Weather() : isNow = true;

  @override
  String toString() {
    return 'The weather in $city is $desc and the temperature is ${temp.toStringAsFixed(2)} Celcius right now';
  }
}

List<City> parseCities(dynamic locations) {
  var cities = <City>[];
  if (locations == null) {
    return null;
  }
  for (var entry in locations) {
    var city = City();
    if (entry['type'] == 'value') {
      city.name = entry['value'];
      city.hasFound = false;
    } else {
      // print(entry['resolved']['values'][0]['name']);
      city.name = entry['resolved']['values'][0]['name'];
      city.lat = entry['resolved']['values'][0]['coords']['lat'];
      city.long = entry['resolved']['values'][0]['coords']['long'];
      city.timezone = entry['resolved']['values'][0]['timezone'];
      city.hasFound = true;
    }

    cities.add(city);
  }

  return cities;
}

Future<Weather> getWeatherInfo(City city) async {
  if (!city.hasFound) {
    return null;
  }

  var url =
      'https://api.openweathermap.org/data/2.5/onecall?lat=${city.lat}&lon=${city.long}&units=metric&exclude=minutely,hourly&appid=${API_KEY}';
  var response = await http.get(url);

  var data = jsonDecode(response.body);
  if (data['cod'] == 400) {
    return null;
  }

  var weather = Weather();
  weather.city = city.name;
  weather.desc = data['current']['weather'][0]['description'];
  weather.temp = data['current']['temp'];
  return weather;
}

Future<String> getTime(City city) async {
  var url = 'http://worldtimeapi.org/api/timezone/${city.timezone}';

  var response = await http.get(url);
  var data = jsonDecode(response.body);
  if (data['cod'] == 400) {
    return null;
  }
  String time = data['datetime'];
  var index = time.indexOf('T');
  return time.substring(index + 1, index + 6);
}
