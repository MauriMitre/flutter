

void main() {
  final Map<String, dynamic> pokemon = {
    'name': 'Ditto',
    'hp': 48,
    'isAlive': true,
    'sprites':{
      'front': 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/132.png',
      'back': 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/back/132.png'
    }
  };// Map is a collection of key-value pairs, where keys are unique and values can be of any type

  print('Back: ${pokemon['sprites']['front']}'); // Accessing a value using its key
}