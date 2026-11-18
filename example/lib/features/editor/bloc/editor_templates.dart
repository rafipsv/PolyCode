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
    PolyLanguage.rust: '''// PolyCode Rust Runner
fn main() {
    println!("Hello from PolyCode Rust!");
    let nums = vec![1, 2, 3, 4, 5];
    let sum: i32 = nums.iter().sum();
    println!("Sum of numbers: {}", sum);
}
''',
    PolyLanguage.go: '''// PolyCode Go Runner
package main

import "fmt"

func main() {
    fmt.Println("Hello from PolyCode Go!")
    nums := []int{1, 2, 3, 4, 5}
    sum := 0
    for _, n := range nums {
        sum += n
    }
    fmt.Printf("Sum of numbers: %d\\n", sum)
}
''',
    PolyLanguage.java: '''// PolyCode Java Runner
public class Main {
    public static void main(String[] args) {
        System.out.println("Hello from PolyCode Java!");
        int[] nums = {1, 2, 3, 4, 5};
        int sum = 0;
        for (int n : nums) {
            sum += n;
        }
        System.out.println("Sum of numbers: " + sum);
    }
}
''',
    PolyLanguage.kotlin: '''// PolyCode Kotlin Runner
fun main() {
    println("Hello from PolyCode Kotlin!")
    val nums = listOf(1, 2, 3, 4, 5)
    val sum = nums.sum()
    println("Sum of numbers: " + sum);
}
''',
  };
}
