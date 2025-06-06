void main() {
  final mySquare = Square(side: 5.0);

  print('The area of the square is ${mySquare.area}');
}

class Square {
  double _side;

  Square({required double side})
    : assert(side >= 0, 'Side length must be positive'),
      _side = side;

  set side(double value) {
    if (value <= 0) {
      throw ArgumentError('Side length must be positive');
    }
    _side = value;
  }

  double get area => _side * _side;
}
