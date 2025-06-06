void main() {
  final flipper = Delfin();
  flipper.volar();
  final batman = Murcielago();
  batman.volar();
}

abstract class Animal {}

abstract class Mamifero extends Animal with volador {}

abstract class Aves extends Animal {}

abstract class Peces extends Animal {}

class Delfin extends Mamifero with Nadador {
  @override
  String toString() => 'Delfín';
}

class Murcielago extends Mamifero with volador {
  @override
  String toString() => 'Murciélago';
}

class Gato extends Mamifero with Caminante {
  @override
  String toString() => 'Gato';
}

class Pato extends Aves with volador, Nadador, Caminante {
  @override
  String toString() => 'Pato';
}

class PezVolador extends Peces with volador, Nadador {
  @override
  String toString() => 'Pez Volador';
}

mixin volador {
  void volar() => print('Estoy volando');
}

mixin Nadador {
  void volar() => print('Estoy nadando');
}

mixin Caminante {
  void volar() => print('Estoy caminando');
}
