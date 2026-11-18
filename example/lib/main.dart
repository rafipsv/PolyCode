import 'package:flutter/material.dart';
import 'package:polycode/polycode.dart';

void main() {
  runApp(const PolyCodeExampleApp());
}

class PolyCodeExampleApp extends StatelessWidget {
  const PolyCodeExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PolyCode Playground',
      theme: ThemeData.dark(useMaterial3: true),
      home: const PolyCodeHomeScreen(),
    );
  }
}

class PolyCodeHomeScreen extends StatefulWidget {
  const PolyCodeHomeScreen({super.key});

  @override
  State<PolyCodeHomeScreen> createState() => _PolyCodeHomeScreenState();
}

class _PolyCodeHomeScreenState extends State<PolyCodeHomeScreen> {
  late final PolyCode _polycode;
  PolyLanguage _selectedLanguage = PolyLanguage.python;
  String _sourceCode = 'print("Hello from PolyCode!")';
  String _output = 'Ready to execute code locally.';

  @override
  void initState() {
    super.initState();
    _polycode = PolyCode();
  }

  @override
  void dispose() {
    _polycode.dispose();
    super.dispose();
  }

  void _runCode() async {
    setState(() {
      _output = 'Checking engine availability...';
    });

    if (!_polycode.isEngineAvailable(_selectedLanguage)) {
      final info = _polycode.getLanguageInfo(_selectedLanguage);
      setState(() {
        _output = 'Status: ${info?.status.name.toUpperCase()}\n'
            'Notice: ${info?.statusReason ?? "No active local engine registered yet."}\n'
            'Phase 1 complete: Core engine contracts and SDK foundation ready.';
      });
      return;
    }

    try {
      final result = await _polycode.execute(
        ExecutionRequest(
          language: _selectedLanguage,
          source: _sourceCode,
        ),
      );
      setState(() {
        _output = 'STDOUT:\n${result.stdout}\n'
            '${result.stderr.isNotEmpty ? "STDERR:\n${result.stderr}\n" : ""}'
            'Duration: ${result.duration.inMilliseconds}ms';
      });
    } catch (e) {
      setState(() {
        _output = 'Execution Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final capabilities = _polycode.getPlatformCapabilities();

    return Scaffold(
      appBar: AppBar(
        title: const Text('PolyCode Local Compiler'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: Text(
                'Platform: ${capabilities.platform.name.toUpperCase()}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                DropdownButton<PolyLanguage>(
                  value: _selectedLanguage,
                  items: PolyLanguage.values.map((lang) {
                    final info = capabilities.getInfo(lang);
                    return DropdownMenuItem(
                      value: lang,
                      child: Text('${lang.displayName} (${info?.status.name})'),
                    );
                  }).toList(),
                  onChanged: (lang) {
                    if (lang != null) {
                      setState(() => _selectedLanguage = lang);
                    }
                  },
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _runCode,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Run Code'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              flex: 2,
              child: TextField(
                controller: TextEditingController(text: _sourceCode),
                onChanged: (val) => _sourceCode = val,
                maxLines: null,
                expands: true,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Source Code',
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              flex: 1,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white24),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _output,
                    style:
                        const TextStyle(fontFamily: 'monospace', fontSize: 13),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
