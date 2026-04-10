import 'package:vector_math/vector_math_64.dart';

void main() {
  final m = Matrix4.identity();
  print('Probando translateByDouble...');
  m.translateByDouble(1.0, 1.0, 1.0);
  print('translateByDouble(3 args) OK');
  
  print('Probando scaleByDouble...');
  m.scaleByDouble(1.0, 1.0, 1.0, 1.0);
  print('scaleByDouble(4 args) OK');
}
