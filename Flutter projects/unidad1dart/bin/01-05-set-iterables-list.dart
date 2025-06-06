
void main(){
  final numbers = <int>[1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
  final reversedNumbers = numbers.reversed;

  print('numbers: $numbers');
  print('reversedNumbers: $reversedNumbers');
  print('reversedNumbers is iterable: ${reversedNumbers is Iterable}');
  print('List: ${reversedNumbers.toList()}');
  print('set: 4${reversedNumbers.toSet()}');

  final numbersGreaterThanFive = numbers.where((number) => number > 5);
  print('numbersGreaterThanFive: $numbersGreaterThanFive');
} 