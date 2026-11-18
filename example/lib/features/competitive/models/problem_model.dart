import 'package:polycode/polycode.dart';
import 'test_case_model.dart';

class ProblemModel {
  const ProblemModel({
    required this.id,
    required this.title,
    required this.difficulty,
    required this.description,
    required this.constraints,
    required this.sampleInput,
    required this.sampleOutput,
    required this.starterTemplates,
    required this.testCases,
  });

  final String id;
  final String title;
  final String difficulty;
  final String description;
  final List<String> constraints;
  final String sampleInput;
  final String sampleOutput;
  final Map<PolyLanguage, String> starterTemplates;
  final List<TestCase> testCases;

  static const List<ProblemModel> sampleProblems = [
    ProblemModel(
      id: 'sum-of-array',
      title: 'Sum of Array Elements',
      difficulty: 'Easy',
      description:
          'Given an integer N followed by N space-separated integers, compute and print the total sum of all elements.',
      constraints: [
        '1 <= N <= 10^5',
        '-10^9 <= A[i] <= 10^9',
      ],
      sampleInput: '5\n1 2 3 4 5',
      sampleOutput: '15',
      starterTemplates: {
        PolyLanguage.python: '''import sys

def solve():
    lines = sys.stdin.read().split()
    if not lines:
        return
    n = int(lines[0])
    nums = [int(x) for x in lines[1:n+1]]
    print(sum(nums))

solve()
''',
        PolyLanguage.javascript: '''const fs = require('fs');
// In browser Web Worker, readline() is available
const lines = readline().trim().split(/\\s+/);
if (lines.length > 0 && lines[0] !== '') {
    const n = parseInt(lines[0], 10);
    let sum = 0;
    for (let i = 1; i <= n; i++) {
        sum += parseInt(lines[i], 10);
    }
    console.log(sum);
}
''',
        PolyLanguage.c: '''#include <stdio.h>

int main() {
    int n;
    if (scanf("%d", &n) != 1) return 0;
    long long sum = 0;
    for (int i = 0; i < n; i++) {
        long long val;
        scanf("%lld", &val);
        sum += val;
    }
    printf("%lld\\n", sum);
    return 0;
}
''',
        PolyLanguage.cpp: '''#include <iostream>
#include <vector>
#include <numeric>

int main() {
    int n;
    if (!(std::cin >> n)) return 0;
    long long sum = 0;
    for (int i = 0; i < n; i++) {
        long long val;
        std::cin >> val;
        sum += val;
    }
    std::cout << sum << std::endl;
    return 0;
}
''',
      },
      testCases: [
        TestCase(
          id: 'case-1',
          input: '5\n1 2 3 4 5',
          expectedOutput: '15',
        ),
        TestCase(
          id: 'case-2',
          input: '3\n10 20 30',
          expectedOutput: '60',
        ),
        TestCase(
          id: 'case-3',
          input: '4\n-5 5 -10 10',
          expectedOutput: '0',
        ),
      ],
    ),
    ProblemModel(
      id: 'reverse-words',
      title: 'Reverse Words in String',
      difficulty: 'Easy',
      description:
          'Given a line of text, reverse the order of characters in each word while preserving word boundaries.',
      constraints: [
        '1 <= Length of string <= 1000',
        'Consists of printable ASCII characters',
      ],
      sampleInput: 'Hello PolyCode World',
      sampleOutput: 'olleH edoCyloP dlroW',
      starterTemplates: {
        PolyLanguage.python: '''import sys

line = sys.stdin.readline().strip()
words = line.split(' ')
reversed_words = [w[::-1] for w in words]
print(' '.join(reversed_words))
''',
        PolyLanguage.javascript: '''const input = readline().trim();
const words = input.split(' ');
const res = words.map(w => w.split('').reverse().join(''));
console.log(res.join(' '));
''',
        PolyLanguage.c: '''#include <stdio.h>
#include <string.h>

void rev(char *s, int len) {
    for (int i = 0; i < len / 2; i++) {
        char t = s[i];
        s[i] = s[len - 1 - i];
        s[len - 1 - i] = t;
    }
}

int main() {
    char word[256];
    int first = 1;
    while (scanf("%s", word) == 1) {
        if (!first) printf(" ");
        rev(word, strlen(word));
        printf("%s", word);
        first = 0;
    }
    printf("\\n");
    return 0;
}
''',
        PolyLanguage.cpp: '''#include <iostream>
#include <string>
#include <sstream>
#include <algorithm>

int main() {
    std::string line;
    if (std::getline(std::cin, line)) {
        std::istringstream iss(line);
        std::string word;
        bool first = true;
        while (iss >> word) {
            if (!first) std::cout << " ";
            std::reverse(word.begin(), word.end());
            std::cout << word;
            first = false;
        }
        std::cout << std::endl;
    }
    return 0;
}
''',
      },
      testCases: [
        TestCase(
          id: 'case-1',
          input: 'Hello PolyCode World',
          expectedOutput: 'olleH edoCyloP dlroW',
        ),
        TestCase(
          id: 'case-2',
          input: 'Dart Flutter Fast',
          expectedOutput: 'traD rettulF tsaF',
        ),
      ],
    ),
  ];
}
