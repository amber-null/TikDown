import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // Theme state: Starts by matching the user's phone dark/light settings
  ThemeMode _themeMode = ThemeMode.system;

  @override
  Widget build(BuildContext context) {
    const accentYellow = Color(0xFFFFDF00);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.white,
        colorScheme: const ColorScheme.light(primary: accentYellow),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        colorScheme: const ColorScheme.dark(primary: accentYellow),
      ),
      home: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: DownloaderWidget(
              themeMode: _themeMode,
              onThemeChanged: (mode) => setState(() => _themeMode = mode),
            ),
          ),
        ),
      ),
    );
  }
}

class DownloaderWidget extends StatefulWidget {
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeChanged;

  const DownloaderWidget({
    super.key,
    required this.themeMode,
    required this.onThemeChanged,
  });

  @override
  State<DownloaderWidget> createState() => _DownloaderWidgetState();
}

class _DownloaderWidgetState extends State<DownloaderWidget> {
  // Controllers and State Variables (They hold the values on your screen)
  final _urlController = TextEditingController();
  bool _loading = false;
  String? _error;
  String? _downloadUrl;
  String? _videoTitle;
  String? _videoCover;

  // IMPORTANT: Paste your actual backend URL and user tags here:
  final String _backendUrl = 'https://your-vercel-domain.vercel.app/api/download';
  final String _telegram = '@your_telegram';
  final String _discord = 'your_discord#0000';

  // 1. Paste link from phone's clipboard
  void _paste() async {
    final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
    if (clipboardData?.text != null) {
      setState(() => _urlController.text = clipboardData!.text!);
    }
  }

  // 2. Network call to fetch the video
  void _download() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      setState(() => _error = 'Please enter a link first.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _downloadUrl = null;
    });

    try {
      final res = await http.post(
        Uri.parse(_backendUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'url': url}),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true) {
          setState(() {
            _downloadUrl = data['download_url'];
            _videoTitle = data['title'];
            _videoCover = data['cover'];
          });
        } else {
          setState(() => _error = data['error'] ?? 'Check the video link.');
        }
      } else {
        setState(() => _error = 'Server error. Code: ${res.statusCode}');
      }
    } catch (e) {
      setState(() => _error = 'Cannot connect to backend.');
    } finally {
      setState(() => _loading = false);
    }
  }

  // 3. Reset and clear everything for a new download
  void _clearAll() {
    setState(() {
      _urlController.clear();
      _downloadUrl = null;
      _videoTitle = null;
      _videoCover = null;
      _error = null;
    });
  }

  // 4. Open external download link in standard browser
  void _openLink(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open download link.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ================= TOP NAVIGATION HEADER =================
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // LEFT: Theme Dropdown Switcher
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: DropdownButton<ThemeMode>(
                  value: widget.themeMode,
                  icon: const Icon(Icons.palette, color: Color(0xFFFFDF00)),
                  underline: const SizedBox(),
                  onChanged: (mode) => widget.onThemeChanged(mode!),
                  items: const [
                    DropdownMenuItem(value: ThemeMode.system, child: Text('Follow system')),
                    DropdownMenuItem(value: ThemeMode.light, child: Text('Light Mode')),
                    DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark Mode')),
                  ],
                ),
              ),
            ),
            // CENTER: Donate Section (Scales text down on small screens to fit)
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  children: [
                    const Text('Donate Me:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 2),
                    Text('$_telegram | $_discord', style: const TextStyle(color: Color(0xFFFFDF00), fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
              ),
            ),
            // RIGHT: Web Logo and Web Name
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: const [
                  Icon(Icons.cloud_download, color: Color(0xFFFFDF00), size: 22),
                  SizedBox(width: 6),
                  Text('TikDown', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 60),

        // ================= MAIN INTERFACE CARD =================
        Container(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Column(
            children: [
              const Text('TikTok Video Downloader', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Download watermark-free videos instantly.', style: TextStyle(color: Theme.of(context).hintColor)),
              const SizedBox(height: 40),

              // A. Text Input Box (Yellow borders, Paste button on the right)
              TextField(
                controller: _urlController,
                decoration: InputDecoration(
                  hintText: 'Paste TikTok link here...',
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Color(0xFFFFDF00), width: 1.8),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Color(0xFFFFDF00), width: 2.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.paste, color: Color(0xFFFFDF00)),
                    onPressed: _paste,
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // B. "Download" Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFDF00),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _loading ? null : _download,
                  child: _loading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                      : const Text('Download', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 10),

              // C. "Download More" Button
              SizedBox(
                width: double.infinity,
                height: 46,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFFFDF00), width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _clearAll,
                  child: const Text('Download More', style: TextStyle(color: Color(0xFFFFDF00), fontWeight: FontWeight.bold)),
                ),
              ),

              // D. Error message section
              if (_error != null) ...[
                const SizedBox(height: 20),
                Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
              ],

              // E. Download results card (appears only when download succeeds)
              if (_downloadUrl != null) ...[
                const SizedBox(height: 30),
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        if (_videoCover != null) ...[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(_videoCover!, height: 160, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.movie)),
                          ),
                          const SizedBox(height: 12),
                        ],
                        if (_videoTitle != null) ...[
                          Text(_videoTitle!, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                          const SizedBox(height: 16),
                        ],
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 45),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () => _openLink(_downloadUrl!),
                          icon: const Icon(Icons.download),
                          label: const Text('Save Video File'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
