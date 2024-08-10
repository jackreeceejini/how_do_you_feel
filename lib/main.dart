import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Emotion Analyzer',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const EmotionAnalyzerPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class EmotionAnalyzerPage extends StatefulWidget {
  const EmotionAnalyzerPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _EmotionAnalyzerPageState createState() => _EmotionAnalyzerPageState();
}

class _EmotionAnalyzerPageState extends State<EmotionAnalyzerPage> {
  final TextEditingController _feelingsController = TextEditingController();
  String? _analysisResult;
  bool _isLoading = false;

  Future<void> _analyzeEmotions() async {
    setState(() {
      _isLoading = true;
      _analysisResult = null;
    });

    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null) {
      setState(() {
        _isLoading = false;
        _analysisResult = 'Error: No API key found';
      });
      return;
    }

    final model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        temperature: 1,
        topK: 64,
        topP: 0.95,
        maxOutputTokens: 8192,
      ),
    );

    final chat = model.startChat(history: [
      Content.multi([
        TextPart('''
Analyze the following feelings and emotions: "${_feelingsController.text}"

1. Extract and list the key emotions expressed.
2. Provide a brief summary of the emotional state, refer to the user in first person tone.
3. Offer a short, supportive message based on these emotions.
4. Respond in a personal tone.
5. Remove asterisks from response.
6. Include emojis as needed.

Format the response as follows:
Emotions: [list of emotions]
Summary: [brief summary]
Supportive message: [supportive message]
'''),
      ]),
    ]);

    try {
      final content = Content.text(_feelingsController.text);
      final response = await chat.sendMessage(content);
      setState(() {
        _analysisResult = response.text;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _analysisResult = 'Error: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emotion Analyzer'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _feelingsController,
              decoration: const InputDecoration(
                labelText: 'How do you feel?',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _analyzeEmotions,
              child: const Text('Analyze My Emotions'),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _analysisResult != null
                      ? SingleChildScrollView(
                          child: Text(
                            _analysisResult!,
                            style: const TextStyle(fontSize: 16),
                          ),
                        )
                      : const Center(
                          child: Text(
                              'Express your feelings and tap "Analyze My Emotions"')),
            ),
          ],
        ),
      ),
    );
  }
}
