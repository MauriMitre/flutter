Future<void> main() async {
  // Example of using a Future to simulate an asynchronous operation
  print('Starting HTTP GET request...');

  try {
    final value = await httpGet('https://api.example.com/data');
    print(value);
  } on Exception catch (e) {
    print('Tenemos un error $e');
  } catch (error) {
    print('Error occurred: $error');
  } finally {
    print('HTTP GET request completed.');
  }

  /* httpGet('https://api.example.com/data')
      .then((response) {
        print('Response received: $response');
      })
      .catchError((error) {
        print('Error occurred: $error');
      });
  print('HTTP GET request initiated, waiting for response...');
 */
}

Future<String> httpGet(String url) async {
  await Future.delayed(Duration(seconds: 2));
  // throw 'Error: Simulated network error';
  throw Exception('No parameter provided');
  return 'Response from $url';

  // Simulate an HTTP GET request
  //print('GET request to $url');
  //return Future.delayed(Duration(seconds: 2), () {
  //  throw 'Error';
  //return 'Response from $url';
  // });
}
