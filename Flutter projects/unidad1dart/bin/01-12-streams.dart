void main() {
 /*  emitNumbers().listen((value){
    print('Strema value: $value');
  }); */
  emitNumber().listen((value) {
    print('Stream value: $value');
  });
}

Stream<int> emitNumbers() {
  return Stream.periodic(const Duration(seconds: 1), (value) {
    print('desde Strem periodic: $value');
    return value;
  }).take(5);
}

Stream emitNumber() async* {
  final valuesToEmit =[1,3,5,7,9];
  for( int i in valuesToEmit){
    await Future.delayed(const Duration(seconds: 2));
    yield i;
  }
  }

