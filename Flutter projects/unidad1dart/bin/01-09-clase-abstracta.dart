
void main(){
  final windPlant = WindPlant(initialEnergy: 100.0);
  final nuclearPlant = NuclearPlant(energyLeft: 200.0, type: PlantType.nuclear);

  print ('Wind: ${windPlant.energyLeft} kWh');
}

double chargePhone (EnergyPlant plant, double amount) {
  if (plant.energyLeft < amount) {
    throw Exception('Not enough energy left in the plant');
  }
  plant.consumeEnergy(amount);
  return amount;
}

enum PlantType {
  solar,
  wind,
  hydro,
  nuclear
} 

abstract class EnergyPlant {
  double energyLeft;
  PlantType type;

  EnergyPlant({
    required this.energyLeft,
    required this.type
  });

  void consumeEnergy( double amount);
}


// Extends is used to define a class that inherits from an abstract class, allowing it to use its properties and methods.
class WindPlant extends EnergyPlant {
 WindPlant({required double initialEnergy})
  :super(energyLeft:initialEnergy, type: PlantType.wind);
  
  @override
  void consumeEnergy(double amount) {
    // TODO: implement consumeEnergy
  }
} 

// Implements is used to define a class that must implement all methods and properties of an abstract class.
class NuclearPlant implements EnergyPlant {
  @override
  double energyLeft;

  @override
  PlantType type = PlantType.nuclear;

  NuclearPlant({required this.energyLeft, required this.type});

  @override
  void consumeEnergy(double amount) {
    // TODO: implement consumeEnergy
  }

}