
// This Dart program demonstrates the use of variables, including different types and how to print them.

void main() {

  final String pokemon = 'Ditto';
  final ability = <String>['Transform', 'Imposter'];
  dynamic abilityType = 'Normal'; // Dynamic type can hold any type of value, including null


print("""
$pokemon
$ability
$abilityType
This is a simple Dart program that demonstrates the use of variables, including different types and how to print them.
""");

  // Variables
  String name = 'John Doe';
  int age = 30;
  double height = 5.9;
  bool isEmployed = true;

  // Printing variables
  print('Name: $name');
  print('Age: $age');
  print('Height: $height');
  print('Employed: $isEmployed');

  // Changing variable values
  age = 31;
  isEmployed = false;

  // Printing updated variables
  print('Updated Age: $age');
  print('Updated Employed Status: $isEmployed');
}