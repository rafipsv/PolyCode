import 'package:flutter_test/flutter_test.dart';
import 'package:polycode/polycode.dart';

void main() {
  group('Comprehensive Language Accuracy & Complexity Benchmark', () {
    late PolyCode polycode;

    setUp(() {
      polycode = PolyCode();
    });

    tearDown(() async {
      await polycode.dispose();
    });

    test('JavaScript: QuickSort, DP Fibonacci, and Array Reduction', () async {
      const jsCode = '''
function quickSort(arr) {
  if (arr.length <= 1) return arr;
  const pivot = arr[arr.length - 1];
  const left = [];
  const right = [];
  for (let i = 0; i < arr.length - 1; i++) {
    if (arr[i] < pivot) left.push(arr[i]);
    else right.push(arr[i]);
  }
  return [...quickSort(left), pivot, ...quickSort(right)];
}

function fibonacci(n, memo = {}) {
  if (n in memo) return memo[n];
  if (n <= 1) return n;
  memo[n] = fibonacci(n - 1, memo) + fibonacci(n - 2, memo);
  return memo[n];
}

const numbers = [64, 34, 25, 12, 22, 11, 90];
const sorted = quickSort(numbers);
const sum = sorted.reduce((acc, val) => acc + val, 0);
const fib10 = fibonacci(10);

console.log("JS_SORTED: " + sorted.join(", "));
console.log("JS_SUM: " + sum);
console.log("JS_FIB: " + fib10);
''';

      final result = await polycode.execute(
        const ExecutionRequest(
          language: PolyLanguage.javascript,
          source: jsCode,
        ),
      );

      expect(result.isSuccess, isTrue);
      expect(result.exitCode, equals(0));
      expect(result.stdout, contains('JS_SORTED: 11, 12, 22, 25, 34, 64, 90'));
      expect(result.stdout, contains('JS_SUM: 258'));
      expect(result.stdout, contains('JS_FIB: 55'));
    });

    test('Python: BST Traversal, Matrix Multiplication, and Prime Sieve', () async {
      const pyCode = '''
class Node:
    def __init__(self, val):
        self.val = val
        self.left = None
        self.right = None

def insert(root, val):
    if not root:
        return Node(val)
    if val < root.val:
        root.left = insert(root.left, val)
    else:
        root.right = insert(root.right, val)
    return root

def inorder(root, res):
    if root:
        inorder(root.left, res)
        res.append(root.val)
        inorder(root.right, res)
    return res

# Sieve of Eratosthenes
def sieve(n):
    primes = [True] * (n + 1)
    p = 2
    while p * p <= n:
        if primes[p]:
            for i in range(p * p, n + 1, p):
                primes[i] = False
        p += 1
    return [p for p in range(2, n + 1) if primes[p]]

# 2x2 Matrix Multiplication
def matmul(A, B):
    return [
        [A[0][0]*B[0][0] + A[0][1]*B[1][0], A[0][0]*B[0][1] + A[0][1]*B[1][1]],
        [A[1][0]*B[0][0] + A[1][1]*B[1][0], A[1][0]*B[0][1] + A[1][1]*B[1][1]]
    ]

root = None
for v in [20, 10, 30, 5, 15, 25]:
    root = insert(root, v)

bst_res = inorder(root, [])
primes = sieve(20)
prod = matmul([[1, 2], [3, 4]], [[5, 6], [7, 8]])

print("PY_BST:", bst_res)
print("PY_PRIMES:", primes)
print("PY_MATMUL:", prod)
''';

      final result = await polycode.execute(
        const ExecutionRequest(
          language: PolyLanguage.python,
          source: pyCode,
        ),
      );

      expect(result.isSuccess, isTrue);
      expect(result.exitCode, equals(0));
      expect(result.stdout, contains('PY_BST: [5, 10, 15, 20, 25, 30]'));
      expect(result.stdout, contains('PY_PRIMES: [2, 3, 5, 7, 11, 13, 17, 19]'));
      expect(result.stdout, contains('PY_MATMUL: [[19, 22], [43, 50]]'));
    });

    test('C: Dynamic Memory, Linked List Reversal, and QuickSort', () async {
      const cCode = '''
#include <stdio.h>
#include <stdlib.h>

struct Node {
    int data;
    struct Node* next;
};

struct Node* createNode(int data) {
    struct Node* n = (struct Node*)malloc(sizeof(struct Node));
    n->data = data;
    n->next = NULL;
    return n;
}

struct Node* reverseList(struct Node* head) {
    struct Node* prev = NULL;
    struct Node* curr = head;
    struct Node* next = NULL;
    while (curr != NULL) {
        next = curr->next;
        curr->next = prev;
        prev = curr;
        curr = next;
    }
    return prev;
}

int fibonacci(int n) {
    if (n <= 1) return n;
    return fibonacci(n - 1) + fibonacci(n - 2);
}

int main() {
    struct Node* head = createNode(10);
    head->next = createNode(20);
    head->next->next = createNode(30);

    head = reverseList(head);

    printf("C_REVERSED: ");
    struct Node* curr = head;
    while (curr != NULL) {
        printf("%d ", curr->data);
        struct Node* temp = curr;
        curr = curr->next;
        free(temp);
    }
    printf("\\n");

    printf("C_FIB: %d\\n", fibonacci(10));
    return 0;
}
''';

      final result = await polycode.execute(
        const ExecutionRequest(
          language: PolyLanguage.c,
          source: cCode,
        ),
      );

      expect(result.isSuccess, isTrue);
      expect(result.exitCode, equals(0));
      expect(result.stdout, contains('C_REVERSED: 30 20 10'));
      expect(result.stdout, contains('C_FIB: 55'));
    });

    test('C++: Modern Vector, Lambdas, std::sort, and Tower of Hanoi', () async {
      const cppCode = '''
#include <iostream>
#include <vector>
#include <numeric>
#include <algorithm>

int hanoiMoves(int n) {
    if (n <= 0) return 0;
    return 2 * hanoiMoves(n - 1) + 1;
}

int fibonacci(int n) {
    if (n <= 1) return n;
    return fibonacci(n - 1) + fibonacci(n - 2);
}

int main() {
    std::vector<int> numbers = {64, 34, 25, 12, 22, 11, 90};
    std::sort(numbers.begin(), numbers.end(), [](int a, int b) {
        return a < b;
    });

    int sum = std::accumulate(numbers.begin(), numbers.end(), 0);

    std::cout << "CPP_SORTED: ";
    for (int n : numbers) {
        std::cout << n << " ";
    }
    std::cout << std::endl;

    std::cout << "CPP_SUM: " << sum << std::endl;
    std::cout << "CPP_HANOI: " << hanoiMoves(5) << std::endl;
    std::cout << "CPP_FIB: " << fibonacci(10) << std::endl;
    return 0;
}
''';

      final result = await polycode.execute(
        const ExecutionRequest(
          language: PolyLanguage.cpp,
          source: cppCode,
        ),
      );

      expect(result.isSuccess, isTrue);
      expect(result.exitCode, equals(0));
      expect(result.stdout, contains('CPP_SORTED: 11 12 22 25 34 64 90'));
      expect(result.stdout, contains('CPP_SUM: 258'));
      expect(result.stdout, contains('CPP_HANOI: 31'));
      expect(result.stdout, contains('CPP_FIB: 55'));
    });

    test('Java: Generics, ArrayList Sorting, GCD, and Recursion', () async {
      const javaCode = '''
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

public class Main {
    public static int gcd(int a, int b) {
        return b == 0 ? a : gcd(b, a % b);
    }

    public static int fibonacci(int n) {
        if (n <= 1) return n;
        return fibonacci(n - 1) + fibonacci(n - 2);
    }

    public static void main(String[] args) {
        List<Integer> list = new ArrayList<>();
        list.add(64);
        list.add(34);
        list.add(25);
        list.add(12);
        list.add(22);
        list.add(11);
        list.add(90);

        Collections.sort(list);

        int sum = 0;
        for (int n : list) {
            sum += n;
        }

        System.out.println("JAVA_SORTED: " + list);
        System.out.println("JAVA_SUM: " + sum);
        System.out.println("JAVA_GCD: " + gcd(48, 18));
        System.out.println("JAVA_FIB: " + fibonacci(10));
    }
}
''';

      final result = await polycode.execute(
        const ExecutionRequest(
          language: PolyLanguage.java,
          source: javaCode,
        ),
      );

      expect(result.isSuccess, isTrue);
      expect(result.exitCode, equals(0));
      expect(result.stdout, contains('JAVA_SORTED: [11, 12, 22, 25, 34, 64, 90]'));
      expect(result.stdout, contains('JAVA_SUM: 258'));
      expect(result.stdout, contains('JAVA_GCD: 6'));
      expect(result.stdout, contains('JAVA_FIB: 55'));
    });

    test('Dart: Higher-Order Functions, QuickSort, and Map Reduction', () async {
      const dartCode = '''
List<int> quickSort(List<int> list) {
  if (list.length <= 1) return list;
  final pivot = list.last;
  final left = <int>[];
  final right = <int>[];
  for (var i = 0; i < list.length - 1; i++) {
    if (list[i] < pivot) {
      left.add(list[i]);
    } else {
      right.add(list[i]);
    }
  }
  return [...quickSort(left), pivot, ...quickSort(right)];
}

int fibonacci(int n) {
  if (n <= 1) return n;
  return fibonacci(n - 1) + fibonacci(n - 2);
}

void main() {
  final numbers = [64, 34, 25, 12, 22, 11, 90];
  final sorted = quickSort(numbers);
  final sum = sorted.reduce((a, b) => a + b);
  final fib10 = fibonacci(10);

  print('DART_SORTED: \${sorted.join(", ")}');
  print('DART_SUM: \$sum');
  print('DART_FIB: \$fib10');
}
''';

      final result = await polycode.execute(
        const ExecutionRequest(
          language: PolyLanguage.dart,
          source: dartCode,
        ),
      );

      expect(result.isSuccess, isTrue);
      expect(result.exitCode, equals(0));
      expect(result.stdout, contains('DART_SORTED: 11, 12, 22, 25, 34, 64, 90'));
      expect(result.stdout, contains('DART_SUM: 258'));
      expect(result.stdout, contains('DART_FIB: 55'));
    });

    test('Rust: Vector Sort, Recursive Fibonacci, and Array Iteration', () async {
      const rustCode = '''
fn fibonacci(n: i32) -> i32 {
    if n <= 1 {
        return n;
    }
    return fibonacci(n - 1) + fibonacci(n - 2);
}

fn main() {
    let mut numbers = vec![64, 34, 25, 12, 22, 11, 90];
    numbers.sort();
    let fib = fibonacci(10);
    println!("RUST_SORTED: {:?}", numbers);
    println!("RUST_FIB: {}", fib);
}
''';

      final result = await polycode.execute(
        const ExecutionRequest(
          language: PolyLanguage.rust,
          source: rustCode,
        ),
      );

      expect(result.isSuccess, isTrue);
      expect(result.exitCode, equals(0));
      expect(result.stdout.replaceAll(' ', ''), contains('11,12,22,25,34,64,90'));
      expect(result.stdout, contains('RUST_FIB: 55'));
    });

    test('Go: In-place Bubble Sort and Recursive Fibonacci', () async {
      const goCode = '''
package main
import "fmt"

func fibonacci(n int) int {
    if n <= 1 {
        return n
    }
    return fibonacci(n-1) + fibonacci(n-2)
}

func main() {
    nums := []int{64, 34, 25, 12, 22, 11, 90}
    for i := 0; i < len(nums); i++ {
        for j := i + 1; j < len(nums); j++ {
            if nums[i] > nums[j] {
                temp := nums[i]
                nums[i] = nums[j]
                nums[j] = temp
            }
        }
    }
    fib := fibonacci(10)
    fmt.Println("GO_SORTED:", nums)
    fmt.Println("GO_FIB:", fib)
}
''';

      final result = await polycode.execute(
        const ExecutionRequest(
          language: PolyLanguage.go,
          source: goCode,
        ),
      );

      expect(result.isSuccess, isTrue);
      expect(result.exitCode, equals(0));
      expect(result.stdout, contains('11'));
      expect(result.stdout, contains('90'));
      expect(result.stdout, contains('GO_FIB: 55'));
    });

    test('Kotlin: In-place Sort and Recursive Fibonacci', () async {
      const ktCode = '''
fun fibonacci(n: Int): Int {
    if (n <= 1) {
        return n
    }
    return fibonacci(n - 1) + fibonacci(n - 2)
}

fun main() {
    val nums = mutableListOf(64, 34, 25, 12, 22, 11, 90)
    for (i in 0 until nums.size) {
        for (j in i + 1 until nums.size) {
            if (nums[i] > nums[j]) {
                val temp = nums[i]
                nums[i] = nums[j]
                nums[j] = temp
            }
        }
    }
    val fib = fibonacci(10)
    println("KT_SORTED: \$nums")
    println("KT_FIB: \$fib")
}
''';

      final result = await polycode.execute(
        const ExecutionRequest(
          language: PolyLanguage.kotlin,
          source: ktCode,
        ),
      );

      expect(result.isSuccess, isTrue);
      expect(result.exitCode, equals(0));
      expect(result.stdout.replaceAll(' ', ''), contains('11,12,22,25,34,64,90'));
      expect(result.stdout, contains('KT_FIB: 55'));
    });
  });
}
