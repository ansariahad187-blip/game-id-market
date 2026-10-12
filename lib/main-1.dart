import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:video_player/video_player.dart';
import 'package:http/http.dart' as http;

// ─────────── CLOUDINARY CONFIG ───────────
// Apna Cloudinary cloud name aur unsigned upload preset yahan dalein
const String _cloudName = 'ml_default';
const String _uploadPreset = 'ml_default';

// ─────────── FIREBASE CONFIG ───────────
const firebaseOptions = FirebaseOptions(
  apiKey: 'AIzaSyAmR3BwFyYrl8dH-uM-vEkwpUIGdOjDsRA',
  appId: '1:637672446279:android:65f0968c1f8576acdd1462',
  messagingSenderId: '637672446279',
  projectId: 'id-marketing-d1ab9',
  authDomain: 'id-marketing-d1ab9.firebaseapp.com',
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: firebaseOptions);
  runApp(const GameIdApp());
}

class GameIdApp extends StatelessWidget {
  const GameIdApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Game ID Market',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF6B00),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const AuthGate(),
    );
  }
}

// ─────────── AUTH GATE ───────────
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snap.hasData) return const HomePage();
        return const LoginPage();
      },
    );
  }
}

// ─────────── LOGIN PAGE ───────────
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _phoneCtrl = TextEditingController();
  final _otpCtrl   = TextEditingController();
  String? _verificationId;
  bool _otpSent = false;
  bool _loading  = false;
  String _msg    = '';

  Future<void> _sendOtp() async {
    setState(() { _loading = true; _msg = ''; });
    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: '+91${_phoneCtrl.text.trim()}',
      verificationCompleted: (PhoneAuthCredential cred) async {
        await FirebaseAuth.instance.signInWithCredential(cred);
      },
      verificationFailed: (e) {
        setState(() { _msg = 'Error: ${e.message}'; _loading = false; });
      },
      codeSent: (vId, _) {
        setState(() { _verificationId = vId; _otpSent = true; _loading = false; _msg = 'OTP bheja gaya!'; });
      },
      codeAutoRetrievalTimeout: (_) {},
    );
  }

  Future<void> _verifyOtp() async {
    setState(() { _loading = true; _msg = ''; });
    try {
      final cred = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: _otpCtrl.text.trim(),
      );
      await FirebaseAuth.instance.signInWithCredential(cred);
    } catch (e) {
      setState(() { _msg = 'OTP galat hai'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1a1a2e), Color(0xFF16213e)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: Column(
                children: [
                  const Icon(Icons.sports_esports, size: 80, color: Color(0xFFFF6B00)),
                  const SizedBox(height: 12),
                  const Text(
                    'Game ID Market',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  const Text('Free Fire & BGMI IDs', style: TextStyle(color: Colors.white54)),
                  const SizedBox(height: 40),
                  if (!_otpSent) ...[
                    TextField(
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Mobile Number (10 digit)',
                        labelStyle: const TextStyle(color: Colors.white54),
                        prefixText: '+91 ',
                        prefixStyle: const TextStyle(color: Colors.white),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.white30),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _sendOtp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF6B00),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _loading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('OTP Bhejo', style: TextStyle(fontSize: 16, color: Colors.white)),
                      ),
                    ),
                  ] else ...[
                    TextField(
                      controller: _otpCtrl,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'OTP Daalo',
                        labelStyle: const TextStyle(color: Colors.white54),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.white30),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _verifyOtp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF6B00),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _loading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('Login', style: TextStyle(fontSize: 16, color: Colors.white)),
                      ),
                    ),
                  ],
                  if (_msg.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(_msg, style: const TextStyle(color: Colors.orangeAccent)),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────── HOME PAGE ───────────
class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Game ID Market', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1a1a2e),
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (val) {
              if (val == 'settings') {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsPage()));
              } else if (val == 'logout') {
                _logout();
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'settings', child: ListTile(leading: Icon(Icons.settings), title: Text('Settings'))),
              const PopupMenuItem(value: 'logout', child: ListTile(leading: Icon(Icons.logout), title: Text('Logout'))),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tab,
          indicatorColor: const Color(0xFFFF6B00),
          labelColor: const Color(0xFFFF6B00),
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(text: '🔥 Free Fire'),
            Tab(text: '🎮 BGMI'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: const [
          GameTab(game: 'freefire'),
          GameTab(game: 'bgmi'),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const SellPage()));
        },
        backgroundColor: const Color(0xFFFF6B00),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Becho', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}

// ─────────── GAME TAB (Firestore listings) ───────────
class GameTab extends StatelessWidget {
  final String game;
  const GameTab({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: game == 'freefire'
              ? [const Color(0xFF1a1a2e), const Color(0xFF2d1b00)]
              : [const Color(0xFF1a1a2e), const Color(0xFF001a2d)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('listings')
            .where('game', isEqualTo: game)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFFF6B00)));
          }
          if (!snap.hasData || snap.data!.docs.isEmpty) {
            return const Center(
              child: Text('Abhi koi listing nahi hai\nPehle "Becho" dabakar ID daalen!',
                  textAlign: TextAlign.center, style: TextStyle(color: Colors.white54, fontSize: 16)),
            );
          }
          final docs = snap.data!.docs;
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (ctx, i) {
              final d = docs[i].data() as Map<String, dynamic>;
              final isSold = d['status'] == 'sold';
              return Card(
                color: const Color(0xFF16213e),
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => ListingDetailPage(docId: docs[i].id, data: d),
                    ));
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // thumbnail
                      if ((d['photos'] as List?)?.isNotEmpty == true)
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                          child: Stack(
                            children: [
                              Image.network(
                                d['photos'][0],
                                height: 160,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  height: 160,
                                  color: Colors.grey[800],
                                  child: const Icon(Icons.image_not_supported, color: Colors.white30, size: 48),
                                ),
                              ),
                              if (isSold)
                                Positioned(
                                  top: 8, right: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Text('SOLD', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  d['title'] ?? 'No Title',
                                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                                Text(
                                  '₹${d['price'] ?? '0'}',
                                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFFFF6B00)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              d['description'] ?? '',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white54),
                            ),
                            if ((d['photos'] as List?)?.length != null && (d['photos'] as List).length > 1)
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  '📷 ${(d['photos'] as List).length} photos',
                                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ─────────── SELL PAGE ───────────
class SellPage extends StatefulWidget {
  const SellPage({super.key});
  @override
  State<SellPage> createState() => _SellPageState();
}

class _SellPageState extends State<SellPage> {
  final _titleCtrl   = TextEditingController();
  final _priceCtrl   = TextEditingController();
  final _descCtrl    = TextEditingController();
  final _phoneCtrl   = TextEditingController();
  String _selectedGame = 'freefire';
  List<XFile> _photos = [];
  XFile? _video;
  bool _uploading = false;
  String _status = '';

  // ── Cloudinary image upload
  Future<String?> _uploadToCloudinary(XFile file, {bool isVideo = false}) async {
    final url = Uri.parse(
      'https://api.cloudinary.com/v1_1/$_cloudName/${isVideo ? 'video' : 'image'}/upload',
    );
    final bytes = await file.readAsBytes();
    final req = http.MultipartRequest('POST', url)
      ..fields['upload_preset'] = _uploadPreset
      ..files.add(http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: file.name,
      ));
    final res = await req.send();
    if (res.statusCode == 200) {
      final body = await res.stream.bytesToString();
      final json = jsonDecode(body);
      return json['secure_url'] as String?;
    }
    return null;
  }

  Future<void> _pickPhotos() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(imageQuality: 70);
    if (picked.isNotEmpty) {
      setState(() {
        _photos = [..._photos, ...picked].take(10).toList();
      });
    }
  }

  Future<void> _pickVideo() async {
    final picker = ImagePicker();
    final picked = await picker.pickVideo(source: ImageSource.gallery, maxDuration: const Duration(seconds: 60));
    if (picked != null) setState(() => _video = picked);
  }

  Future<void> _submit() async {
    if (_titleCtrl.text.isEmpty || _priceCtrl.text.isEmpty || _phoneCtrl.text.isEmpty) {
      setState(() => _status = 'Title, price aur phone number zaroori hai!');
      return;
    }
    if (_cloudName == 'YOUR_CLOUD_NAME') {
      setState(() => _status = '⚠️ Pehle Cloudinary config set karein (cloud name + upload preset)');
      return;
    }
    setState(() { _uploading = true; _status = 'Upload ho raha hai...'; });

    try {
      // Upload photos
      List<String> photoUrls = [];
      for (int i = 0; i < _photos.length; i++) {
        setState(() => _status = 'Photo ${i+1}/${_photos.length} upload ho rahi hai...');
        final url = await _uploadToCloudinary(_photos[i]);
        if (url != null) photoUrls.add(url);
      }

      // Upload video
      String? videoUrl;
      if (_video != null) {
        setState(() => _status = 'Video upload ho rahi hai...');
        videoUrl = await _uploadToCloudinary(_video!, isVideo: true);
      }

      // Save to Firestore
      setState(() => _status = 'Firestore mein save ho raha hai...');
      final user = FirebaseAuth.instance.currentUser!;
      await FirebaseFirestore.instance.collection('listings').add({
        'game': _selectedGame,
        'title': _titleCtrl.text.trim(),
        'price': _priceCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'photos': photoUrls,
        'video': videoUrl,
        'status': 'available',
        'sellerId': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        setState(() { _uploading = false; _status = ''; });
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Listing add ho gayi! ✅'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      setState(() { _uploading = false; _status = 'Error: $e'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      appBar: AppBar(
        title: const Text('ID Becho', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF16213e),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Game select
            const Text('Game:', style: TextStyle(color: Colors.white70, fontSize: 14)),
            const SizedBox(height: 6),
            Row(
              children: [
                _gameBtn('freefire', '🔥 Free Fire'),
                const SizedBox(width: 12),
                _gameBtn('bgmi', '🎮 BGMI'),
              ],
            ),
            const SizedBox(height: 16),

            _field('Title (e.g. Level 72 Diamond Account)', _titleCtrl),
            const SizedBox(height: 12),
            _field('Price (₹)', _priceCtrl, number: true),
            const SizedBox(height: 12),
            _field('Description', _descCtrl, lines: 3),
            const SizedBox(height: 12),
            _field('Seller Phone Number', _phoneCtrl, number: true),
            const SizedBox(height: 20),

            // Photos
            const Text('Photos (max 10):', style: TextStyle(color: Colors.white70, fontSize: 14)),
            const SizedBox(height: 8),
            if (_photos.isNotEmpty)
              SizedBox(
                height: 100,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _photos.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (ctx, i) => Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: FutureBuilder<Uint8List>(
                          future: _photos[i].readAsBytes(),
                          builder: (_, s) => s.hasData
                              ? Image.memory(s.data!, width: 90, height: 90, fit: BoxFit.cover)
                              : const SizedBox(width: 90, height: 90),
                        ),
                      ),
                      Positioned(
                        top: 2, right: 2,
                        child: GestureDetector(
                          onTap: () => setState(() => _photos.removeAt(i)),
                          child: const CircleAvatar(
                            radius: 10, backgroundColor: Colors.red,
                            child: Icon(Icons.close, size: 14, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 8),
            if (_photos.length < 10)
              OutlinedButton.icon(
                onPressed: _pickPhotos,
                icon: const Icon(Icons.photo_library, color: Color(0xFFFF6B00)),
                label: Text(
                  _photos.isEmpty ? 'Photos Chuno' : 'Aur Photos Daalo',
                  style: const TextStyle(color: Color(0xFFFF6B00)),
                ),
                style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFFFF6B00))),
              ),

            const SizedBox(height: 16),

            // Video
            const Text('Video (optional, max 60 sec):', style: TextStyle(color: Colors.white70, fontSize: 14)),
            const SizedBox(height: 8),
            if (_video != null)
              Row(
                children: [
                  const Icon(Icons.videocam, color: Colors.green),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_video!.name, style: const TextStyle(color: Colors.white70), overflow: TextOverflow.ellipsis)),
                  IconButton(onPressed: () => setState(() => _video = null), icon: const Icon(Icons.delete, color: Colors.red)),
                ],
              ),
            if (_video == null)
              OutlinedButton.icon(
                onPressed: _pickVideo,
                icon: const Icon(Icons.video_library, color: Color(0xFFFF6B00)),
                label: const Text('Video Chuno', style: TextStyle(color: Color(0xFFFF6B00))),
                style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFFFF6B00))),
              ),

            const SizedBox(height: 24),

            if (_status.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(_status, style: const TextStyle(color: Colors.orangeAccent)),
              ),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _uploading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B00),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _uploading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Upload & Publish', style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _gameBtn(String val, String label) {
    final selected = _selectedGame == val;
    return Expanded(
      child: ElevatedButton(
        onPressed: () => setState(() => _selectedGame = val),
        style: ElevatedButton.styleFrom(
          backgroundColor: selected ? const Color(0xFFFF6B00) : const Color(0xFF16213e),
          side: BorderSide(color: selected ? const Color(0xFFFF6B00) : Colors.white24),
        ),
        child: Text(label, style: TextStyle(color: selected ? Colors.white : Colors.white54)),
      ),
    );
  }

  Widget _field(String hint, TextEditingController ctrl, {bool number = false, int lines = 1}) {
    return TextField(
      controller: ctrl,
      keyboardType: number ? TextInputType.number : TextInputType.text,
      maxLines: lines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: hint,
        labelStyle: const TextStyle(color: Colors.white54),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.white24),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFFF6B00)),
        ),
      ),
    );
  }
}

// ─────────── LISTING DETAIL PAGE ───────────
class ListingDetailPage extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> data;
  const ListingDetailPage({super.key, required this.docId, required this.data});
  @override
  State<ListingDetailPage> createState() => _ListingDetailPageState();
}

class _ListingDetailPageState extends State<ListingDetailPage> {
  late Map<String, dynamic> _data;
  bool _updatingStatus = false;

  @override
  void initState() {
    super.initState();
    _data = widget.data;
  }

  bool get _isOwner =>
      FirebaseAuth.instance.currentUser?.uid == _data['sellerId'];

  bool get _isSold => _data['status'] == 'sold';

  Future<void> _toggleStatus() async {
    setState(() => _updatingStatus = true);
    final newStatus = _isSold ? 'available' : 'sold';
    await FirebaseFirestore.instance
        .collection('listings')
        .doc(widget.docId)
        .update({'status': newStatus});
    setState(() {
      _data = {..._data, 'status': newStatus};
      _updatingStatus = false;
    });
  }

  Future<void> _call() async {
    final phone = _data['phone'] ?? '';
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _whatsapp() async {
    final phone = _data['phone'] ?? '';
    final msg = Uri.encodeComponent('Bhai, Game ID Market pe tumhari listing dekhi. Kya ID available hai?');
    final uri = Uri.parse('https://wa.me/91$phone?text=$msg');
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final photos = List<String>.from(_data['photos'] ?? []);
    final videoUrl = _data['video'] as String?;

    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      appBar: AppBar(
        title: Text(_data['title'] ?? '', style: const TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF16213e),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_isOwner)
            _updatingStatus
                ? const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : TextButton(
                    onPressed: _toggleStatus,
                    child: Text(
                      _isSold ? 'Available Karo' : 'Sold Karo',
                      style: TextStyle(color: _isSold ? Colors.green : Colors.red),
                    ),
                  ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo swiper
            if (photos.isNotEmpty)
              SizedBox(
                height: 260,
                child: PageView.builder(
                  itemCount: photos.length,
                  itemBuilder: (ctx, i) => Image.network(
                    photos[i],
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey[800],
                      child: const Icon(Icons.image_not_supported, color: Colors.white30, size: 60),
                    ),
                  ),
                ),
              )
            else
              Container(
                height: 200,
                color: const Color(0xFF16213e),
                child: const Center(child: Icon(Icons.image, color: Colors.white30, size: 60)),
              ),

            if (photos.length > 1)
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text('${photos.length} photos — swipe karo', style: const TextStyle(color: Colors.white38, fontSize: 12)),
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: _isSold ? Colors.red : Colors.green,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _isSold ? 'SOLD' : 'AVAILABLE',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          _data['title'] ?? '',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                      Text(
                        '₹${_data['price'] ?? '0'}',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFFFF6B00)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _data['description'] ?? '',
                    style: const TextStyle(color: Colors.white70, fontSize: 15, height: 1.5),
                  ),

                  // Video button
                  if (videoUrl != null && videoUrl.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(
                          builder: (_) => VideoPage(url: videoUrl),
                        ));
                      },
                      icon: const Icon(Icons.play_circle_fill),
                      label: const Text('Video Dekho'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF16213e),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),
                  const Divider(color: Colors.white12),
                  const SizedBox(height: 16),

                  if (!_isSold) ...[
                    const Text('Seller se contact karo:', style: TextStyle(color: Colors.white54, fontSize: 14)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _call,
                            icon: const Icon(Icons.call, color: Colors.white),
                            label: const Text('Call', style: TextStyle(color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _whatsapp,
                            icon: const Icon(Icons.chat, color: Colors.white),
                            label: const Text('WhatsApp', style: TextStyle(color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF25D366),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ] else
                    const Center(
                      child: Text(
                        'Ye ID Bik Chuki Hai 😔',
                        style: TextStyle(color: Colors.red, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────── VIDEO PLAYER PAGE ───────────
class VideoPage extends StatefulWidget {
  final String url;
  const VideoPage({super.key, required this.url});
  @override
  State<VideoPage> createState() => _VideoPageState();
}

class _VideoPageState extends State<VideoPage> {
  late VideoPlayerController _ctrl;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _ctrl = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize().then((_) {
        setState(() => _ready = true);
        _ctrl.play();
      });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black, iconTheme: const IconThemeData(color: Colors.white)),
      body: Center(
        child: _ready
            ? AspectRatio(
                aspectRatio: _ctrl.value.aspectRatio,
                child: VideoPlayer(_ctrl),
              )
            : const CircularProgressIndicator(color: Color(0xFFFF6B00)),
      ),
      floatingActionButton: _ready
          ? FloatingActionButton(
              onPressed: () => setState(() => _ctrl.value.isPlaying ? _ctrl.pause() : _ctrl.play()),
              backgroundColor: const Color(0xFFFF6B00),
              child: Icon(_ctrl.value.isPlaying ? Icons.pause : Icons.play_arrow),
            )
          : null,
    );
  }
}

// ─────────── SETTINGS PAGE ───────────
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF16213e),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            leading: const Icon(Icons.person, color: Color(0xFFFF6B00)),
            title: const Text('Account', style: TextStyle(color: Colors.white)),
            subtitle: Text(user?.phoneNumber ?? user?.email ?? 'Unknown', style: const TextStyle(color: Colors.white54)),
          ),
          const Divider(color: Colors.white12),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) Navigator.popUntil(context, (r) => r.isFirst);
            },
          ),
        ],
      ),
    );
  }
}
