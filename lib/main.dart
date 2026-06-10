import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // Sets "Follow system" as default
  ThemeMode _themeMode = ThemeMode.system;

  void _changeTheme(ThemeMode mode) {
    setState(() {
      _themeMode = mode;
    });
  }

  @override
  Widget build(BuildContext context) {
    const accentColor = Color(0xFFFFDF00);

    return MaterialApp(
      title: 'TikDown - No Watermark TikTok Downloader',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.white,
        colorScheme: const ColorScheme.light(
          primary: accentColor,
          secondary: accentColor,
          surface: Colors.white,
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        colorScheme: const ColorScheme.dark(
          primary: accentColor,
          secondary: accentColor,
          surface: Color(0xFF1E1E1E),
        ),
      ),
      home: DownloaderHome(
        currentThemeMode: _themeMode,
        onThemeChanged: _changeTheme,
      ),
    );
  }
}

class DownloaderHome extends StatefulWidget {
  final ThemeMode currentThemeMode;
  final ValueChanged<ThemeMode> onThemeChanged;

  const DownloaderHome({
    super.key,
    required this.currentThemeMode,
    required this.onThemeChanged,
  });

  @override
  State<DownloaderHome> createState() => _DownloaderHomeState();
}

class _DownloaderHomeState extends State<DownloaderHome> {
  final TextEditingController _urlController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  String? _downloadUrl;
  String? _videoTitle;
  String? _videoCover;

  // IMPORTANT: Replace this with your actual Vercel back-end production link!
  final String _backendUrl = 'https://your-vercel-domain.vercel.app/api/download';

  // Customize with your usernames here
  final String _telegramUsername = '@your_telegram';
  final String _discordUsername = 'your_discord#0000';

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  // Quick clipboard paste action
  Future<void> _pasteFromClipboard() async {
    try {
      ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
      if (data != null && data.text != null) {
        setState(() {
          _urlController.text = data.text!;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not access system clipboard.')),
      );
    }
  }

  // Handle Backend API Calling
  Future<void> _downloadVideo() async {
    final inputUrl = _urlController.text.trim();
    if (inputUrl.isEmpty) {
      setState(() {
        _errorMessage = 'Please input a valid TikTok URL.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _downloadUrl = null;
      _videoTitle = null;
      _videoCover = null;
    });

    try {
      final response = await http.post(
        Uri.parse(_backendUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'url': inputUrl}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            _downloadUrl = data['download_url'];
            _videoTitle = data['title'];
            _videoCover = data['cover'];
          });
        } else {
          setState(() {
            _errorMessage = data['error'] ?? 'Parsing error occurred.';
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Server response error. Status: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to connect to backend: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Clears out previous download state for new items
  void _downloadMore() {
    setState(() {
      _urlController.clear();
      _downloadUrl = null;
      _videoTitle = null;
      _videoCover = null;
      _errorMessage = null;
    });
  }

  // Opens the clean download URL in a new web browser tab
  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open download URL.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 680;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            children: [
              // --- TOP RESPONSIVE NAVIGATION HEADER ---
              isMobile
                  ? Column(
                      children: [
                        _buildHeaderLogo(),
                        const SizedBox(height: 12),
                        _buildDonateSection(),
                        const SizedBox(height: 12),
                        _buildThemeSwitcher(),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: _buildThemeSwitcher(),
                          ),
                        ),
                        Expanded(
                          child: Center(
                            child: _buildDonateSection(),
                          ),
                        ),
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: _buildHeaderLogo(),
                          ),
                        ),
                      ],
                    ),

              const SizedBox(height: 60),

              // --- MAIN DOWNLOADING WORKSPACE ---
              Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 550),
                  child: Column(
                    children: [
                      const Text(
                        'TikTok Video Downloader',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Download any TikTok video without standard watermarks instantly.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context).hintColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 35),

                      // Insert Box (TextField) with accent borders & paste button inside
                      TextField(
                        controller: _urlController,
                        decoration: InputDecoration(
                          hintText: 'Paste link here...',
                          hintStyle: const TextStyle(fontSize: 14),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          enabledBorder: OutlineInputBorder(
                            borderSide: const BorderSide(
                              color: Color(0xFFFFDF00),
                              width: 1.8,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(
                              color: Color(0xFFFFDF00),
                              width: 2.2,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          suffixIcon: Tooltip(
                            message: 'Paste Clipboard',
                            child: IconButton(
                              icon: const Icon(Icons.paste_rounded, color: Color(0xFFFFDF00)),
                              onPressed: _pasteFromClipboard,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // "Download" Button
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFDF00),
                            foregroundColor: Colors.black, // Dark text/icons on bright Yellow
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 1,
                          ),
                          onPressed: _isLoading ? null : _downloadVideo,
                          child: _isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.black,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : const Text(
                                  'Download',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // "Download More" Button
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFFFDF00), width: 1.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: _downloadMore,
                          child: const Text(
                            'Download More',
                            style: TextStyle(
                              color: Color(0xFFFFDF00),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),

                      // --- STATE DISPLAY (ERROR OR SUCCESS) ---
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 20),
                        Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red, fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                      ],

                      if (_downloadUrl != null) ...[
                        const SizedBox(height: 30),
                        Card(
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                if (_videoCover != null) ...[
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      _videoCover!,
                                      height: 180,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) =>
                                          const Icon(Icons.movie_rounded, size: 60),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                ],
                                if (_videoTitle != null) ...[
                                  Text(
                                    _videoTitle!,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 16),
                                ],
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    minimumSize: const Size(double.infinity, 45),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  onPressed: () => _launchUrl(_downloadUrl!),
                                  icon: const Icon(Icons.download_rounded),
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Header Component: Dropdown Theme Selector
  Widget _buildThemeSwitcher() {
    return DropdownButton<ThemeMode>(
      value: widget.currentThemeMode,
      icon: const Icon(Icons.dark_mode_outlined, color: Color(0xFFFFDF00), size: 20),
      underline: const SizedBox(),
      onChanged: (ThemeMode? val) {
        if (val != null) {
          widget.onThemeChanged(val);
        }
      },
      items: const [
        DropdownMenuItem(
          value: ThemeMode.system,
          child: Text('Follow system', style: TextStyle(fontSize: 13)),
        ),
        DropdownMenuItem(
          value: ThemeMode.light,
          child: Text('Light Mode', style: TextStyle(fontSize: 13)),
        ),
        DropdownMenuItem(
          value: ThemeMode.dark,
          child: Text('Dark Mode', style: TextStyle(fontSize: 13)),
        ),
      ],
    );
  }

  // Header Component: Middle Donate Me Section
  Widget _buildDonateSection() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Donate Me:',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        const SizedBox(height: 2),
        Text(
          '$_telegramUsername | $_discordUsername',
          style: const TextStyle(
            color: Color(0xFFFFDF00),
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  // Header Component: Web Logo & Name
  Widget _buildHeaderLogo() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.cloud_download, color: Color(0xFFFFDF00), size: 24),
        const SizedBox(width: 8),
        const Text(
          'TikDown',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
