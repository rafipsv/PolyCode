import 'package:polycode/polycode.dart';

abstract final class EditorTemplates {
  static const Map<PolyLanguage, String> defaults = {
    PolyLanguage.javascript: '''// PolyCode JavaScript Runner
console.log("Hello from PolyCode Web JavaScript!");
const numbers = [1, 2, 3, 4, 5];
const doubled = numbers.map(x => x * 2);
console.log("Doubled numbers:", doubled);
''',
    PolyLanguage.python: '''# PolyCode Python Runner
def greet(name):
    return f"Hello, {name}! Welcome to PolyCode."

print(greet("Developer"))
total = sum([x**2 for x in range(1, 6)])
print("Sum of squares:", total)
''',
    PolyLanguage.c: '''#include <stdio.h>

int main() {
    printf("Hello from PolyCode C!\\n");
    int a = 10, b = 20;
    printf("Result: %d + %d = %d\\n", a, b, a + b);
    return 0;
}
''',
    PolyLanguage.cpp: '''#include <iostream>
#include <vector>
#include <numeric>

int main() {
    std::cout << "Hello from PolyCode C++!" << std::endl;
    std::vector<int> nums = {1, 2, 3, 4, 5};
    int total = std::accumulate(nums.begin(), nums.end(), 0);
    std::cout << "Sum of vector elements: " << total << std::endl;
    return 0;
}
''',
  };
}
