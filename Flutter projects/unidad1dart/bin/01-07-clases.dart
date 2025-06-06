
void main() {
  final Hero wolverine = Hero(
    name: 'Wolverine',
    age: 200,
    power: 'Healing Factor',
  );

  print(wolverine.toString());

  final Map<String, dynamic> rawJson = {
    'name': 'Tony Stark',
    'age': 45,
    'power': 'Genius-level intellect and powered armor suit',
  };

  final ironman = Hero.fromJson(rawJson);

  print(ironman.toString());
}

class Hero {
  String name;
  int age;
  String power;

  Hero({
    required this.name,
    required this.age,
    required this.power,
  });

  Hero.fromJson(Map<String,dynamic> json)
    : name  = json['name'] ?? 'Unknown',
      age = json['age'] ?? 0,
      power = json['power'] ?? 'None';
  


/*   Hero(String name, String age, String power)
      : name = name,
        age = int.parse(age),
        power = power;  */

  void displayInfo() {
    print('Name: $name, Age: $age, Power: $power');
  }

  @override
  String toString() {
    return 'Hero(name: $name, age: $age, power: $power)';
  }
}

