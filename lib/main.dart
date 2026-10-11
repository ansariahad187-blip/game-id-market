import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

const kPurple = Color(0xFF7B2FF7);
const kDeep = Color(0xFF1A0533);

// Firebase console > Project settings > Your apps se ye 5 values yahan paste karo.
const firebaseOptions = FirebaseOptions(
  apiKey: 'AIzaSyAmR3BwFyYrl8dH-uM-vEkwpUIGdOjDsRA',
  appId: '1:637672446279:android:65f0968c1f8576acdd1462',
  messagingSenderId: '637672446279',
  projectId: 'id-marketing-d1ab9',
  authDomain: 'id-marketing-d1ab9.firebaseapp.com',
);

// Cloudinary (photo/video ke liye). Dono value yahan daalo.
const cloudName = 'xhnin5ln';
const uploadPreset = 'ml_default';
const mediaReady = true;
const maxVideoBytes = 100 * 1024 * 1024; // Cloudinary free plan: video max 100MB

String statusLabel(String s) => s == 'sold' ? 'Sold' : (s == 'pending' ? 'Pending' : 'Available');
Color statusColor(String s) => s == 'sold'
    ? const Color(0xFFC0392B)
    : (s == 'pending' ? const Color(0xFFD9A400) : const Color(0xFF2E9E5B));

class StatusBadge extends StatelessWidget {
  final String status;
  const StatusBadge(this.status, {super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: statusColor(status), borderRadius: BorderRadius.circular(10)),
      child: Text(statusLabel(status),
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
    );
  }
}

Future<String> uploadMedia(String path, bool isVideo) async {
  final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/${isVideo ? 'video' : 'image'}/upload');
  final req = http.MultipartRequest('POST', uri)
    ..fields['upload_preset'] = uploadPreset
    ..fields['public_id'] =
        '${FirebaseAuth.instance.currentUser?.uid ?? 'u'}_${DateTime.now().microsecondsSinceEpoch}'
    ..files.add(await http.MultipartFile.fromPath('file', path));
  final res = await http.Response.fromStream(await req.send());
  final j = jsonDecode(res.body) as Map<String, dynamic>;
  final url = j['secure_url'];
  if (url is String) return url;
  final err = j['error'];
  throw Exception(err is Map ? '${err['message']}' : 'Upload fail');
}

const ffB64 = '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';
const bgmiB64 = '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';


Future<void> main() async {
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
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: kPurple, brightness: Brightness.dark),
        scaffoldBackgroundColor: kDeep,
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        return snap.hasData ? const HomePage() : const LoginPage();
      },
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final auth = FirebaseAuth.instance;
  final phone = TextEditingController();
  final otp = TextEditingController();
  String? verificationId;
  ConfirmationResult? webConfirm;
  bool otpSent = false;
  bool loading = false;

  void _msg(String t) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));
  }

  Future<void> sendOtp() async {
    final n = phone.text.trim();
    if (n.length != 10) {
      _msg('10 digit ka mobile number daalo');
      return;
    }
    final number = '+91$n';
    setState(() => loading = true);
    try {
      if (kIsWeb) {
        webConfirm = await auth.signInWithPhoneNumber(number);
        if (mounted) setState(() { otpSent = true; loading = false; });
      } else {
        await auth.verifyPhoneNumber(
          phoneNumber: number,
          timeout: const Duration(seconds: 60),
          verificationCompleted: (cred) async {
            try { await auth.signInWithCredential(cred); } catch (_) {}
          },
          verificationFailed: (e) {
            _msg(e.message ?? 'OTP nahi gaya');
            if (mounted) setState(() => loading = false);
          },
          codeSent: (id, _) {
            verificationId = id;
            if (mounted) setState(() { otpSent = true; loading = false; });
          },
          codeAutoRetrievalTimeout: (id) => verificationId = id,
        );
      }
    } catch (e) {
      _msg('Error: $e');
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> verifyOtp() async {
    final code = otp.text.trim();
    if (code.length != 6) {
      _msg('6 digit ka OTP daalo');
      return;
    }
    setState(() => loading = true);
    try {
      if (kIsWeb) {
        await webConfirm!.confirm(code);
      } else {
        final cred = PhoneAuthProvider.credential(
            verificationId: verificationId!, smsCode: code);
        await auth.signInWithCredential(cred);
      }
    } on FirebaseAuthException catch (e) {
      _msg(e.code == 'invalid-verification-code' ? 'OTP galat hai' : (e.message ?? 'Login fail'));
    } catch (e) {
      _msg('Error: $e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [kDeep, Color(0xFF4B1A99)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Game ID Market',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  const Text('Free Fire aur BGMI ID kharido ya becho', textAlign: TextAlign.center),
                  const SizedBox(height: 36),
                  TextField(
                    controller: phone,
                    enabled: !otpSent,
                    maxLength: 10,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                        prefixText: '+91  ',
                        labelText: 'Mobile number',
                        counterText: '',
                        border: OutlineInputBorder()),
                  ),
                  if (otpSent) ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: otp,
                      maxLength: 6,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          labelText: 'OTP', counterText: '', border: OutlineInputBorder()),
                    ),
                  ],
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: loading ? null : (otpSent ? verifyOtp : sendOtp),
                    style: FilledButton.styleFrom(
                        backgroundColor: kPurple, padding: const EdgeInsets.symmetric(vertical: 16)),
                    child: loading
                        ? const SizedBox(
                            height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(otpSent ? 'OTP verify karo' : 'OTP bhejo'),
                  ),
                  if (otpSent)
                    TextButton(
                      onPressed: loading
                          ? null
                          : () => setState(() { otpSent = false; otp.clear(); }),
                      child: const Text('Number badlo'),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kDeep,
        title: const Text('Game ID Market'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'settings') {
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const SettingsPage()));
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'settings', child: Text('Settings')),
            ],
          ),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: index,
          children: const [
            GameTab(game: 'ff', image: ffB64, colors: [Color(0xFFFF6A00), Color(0xFF8E0E00)]),
            GameTab(game: 'bgmi', image: bgmiB64, colors: [Color(0xFF1E88E5), Color(0xFF0D2B45)]),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: kDeep,
        indicatorColor: kPurple,
        selectedIndex: index,
        onDestinationSelected: (i) => setState(() => index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.local_fire_department), label: 'Free Fire'),
          NavigationDestination(icon: Icon(Icons.shield), label: 'BGMI'),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: kPurple,
        icon: const Icon(Icons.add),
        label: const Text('ID becho'),
        onPressed: () =>
            Navigator.push(context, MaterialPageRoute(builder: (_) => const SellPage())),
      ),
    );
  }
}

class GameTab extends StatelessWidget {
  final String game;
  final String image;
  final List<Color> colors;
  const GameTab({super.key, required this.game, required this.image, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
            child: Image.memory(base64Decode(image), fit: BoxFit.cover),
          ),
        ),
        Positioned.fill(child: Container(color: kDeep.withOpacity(0.45))),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('listings')
              .where('game', isEqualTo: game)
              .snapshots(),
          builder: (_, snap) {
            if (snap.hasError) {
              return Center(
                  child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text('Error: ${snap.error}'),
              ));
            }
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final docs = snap.data!.docs.toList();
            int stamp(QueryDocumentSnapshot<Map<String, dynamic>> d) {
              final t = d.data()['createdAt'];
              return t is Timestamp ? t.millisecondsSinceEpoch : 99999999999999;
            }
            docs.sort((a, b) => stamp(b).compareTo(stamp(a)));
            if (docs.isEmpty) {
              return const Center(child: Text('Abhi koi ID nahi hai.'));
            }
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
              itemCount: docs.length,
              itemBuilder: (_, i) {
                final d = docs[i].data();
                final photos = List<String>.from(d['photos'] ?? const []);
                final status = (d['status'] ?? 'available') as String;
                return Card(
                  color: kDeep.withOpacity(0.75),
                  child: ListTile(
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => DetailPage(id: docs[i].id))),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: 56,
                        height: 56,
                        child: photos.isEmpty
                            ? Container(color: const Color(0xFF3B1A6B))
                            : Image.network(photos[0],
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    Container(color: const Color(0xFF3B1A6B))),
                      ),
                    ),
                    title: Text('${d['title']}'),
                    subtitle: Text('Level ${d['level']}'),
                    trailing: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('₹${d['price']}',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        StatusBadge(status),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}

class DetailPage extends StatelessWidget {
  final String id;
  const DetailPage({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    final ref = FirebaseFirestore.instance.collection('listings').doc(id);
    return Scaffold(
      appBar: AppBar(title: const Text('ID ki detail'), backgroundColor: kDeep),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: ref.snapshots(),
        builder: (_, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final d = snap.data!.data();
          if (d == null) {
            return const Center(child: Text('Ye ID hata di gayi hai.'));
          }
          final photos = List<String>.from(d['photos'] ?? const []);
          final video = (d['video'] ?? '') as String;
          final status = (d['status'] ?? 'available') as String;
          final mine = d['sellerId'] == FirebaseAuth.instance.currentUser?.uid;
          return ListView(
            children: [
              if (photos.isNotEmpty) ...[
                SizedBox(
                  height: 280,
                  child: PageView(
                    children: photos
                        .map((u) => Image.network(u,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const Center(child: Icon(Icons.broken_image))))
                        .toList(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Center(child: Text('${photos.length} photo (swipe karo)')),
                ),
              ],
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${d['title']}',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    Row(children: [
                      Text('₹${d['price']}',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                      const SizedBox(width: 10),
                      StatusBadge(status),
                    ]),
                    const SizedBox(height: 8),
                    Text('${d['game'] == 'ff' ? 'Free Fire' : 'BGMI'} | Level ${d['level']}'),
                    if ('${d['desc'] ?? ''}'.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text('${d['desc']}'),
                    ],
                    if ('${d['contact'] ?? ''}'.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      SelectableText('Seller ka number: ${d['contact']}'),
                    ],
                    if (video.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: () => launchUrl(Uri.parse(video),
                            mode: LaunchMode.externalApplication),
                        style: FilledButton.styleFrom(
                            backgroundColor: kPurple,
                            padding: const EdgeInsets.symmetric(vertical: 14)),
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Video dekho'),
                      ),
                    ],
                    if (mine) ...[
                      const SizedBox(height: 22),
                      const Text('Status badlo:'),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: ['available', 'pending', 'sold']
                            .map((k) => ChoiceChip(
                                  label: Text(statusLabel(k)),
                                  selected: status == k,
                                  selectedColor: statusColor(k),
                                  onSelected: (_) => ref.update({'status': k}),
                                ))
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class SellPage extends StatefulWidget {
  const SellPage({super.key});
  @override
  State<SellPage> createState() => _SellPageState();
}

class _SellPageState extends State<SellPage> {
  String game = 'ff';
  final title = TextEditingController();
  final level = TextEditingController();
  final price = TextEditingController();
  final desc = TextEditingController();
  late final TextEditingController contact;
  List<String> photos = [];
  String video = '';
  bool busy = false;
  String progress = '';

  @override
  void initState() {
    super.initState();
    final p = FirebaseAuth.instance.currentUser?.phoneNumber ?? '';
    contact = TextEditingController(text: p.startsWith('+91') ? p.substring(3) : p);
  }

  void _msg(String t) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));
  }

  Future<void> pickPhotos() async {
    final left = 10 - photos.length;
    if (left <= 0) {
      _msg('Maximum 10 photo');
      return;
    }
    final got = await ImagePicker().pickMultiImage(imageQuality: 70);
    if (got.isEmpty) return;
    setState(() => photos = [...photos, ...got.map((x) => x.path)].take(10).toList());
  }

  Future<void> pickVideo() async {
    final x = await ImagePicker().pickVideo(source: ImageSource.gallery);
    if (x == null) return;
    final size = await File(x.path).length();
    if (size > maxVideoBytes) {
      _msg('Video 100MB se badi hai (free limit). Chhoti video chuno.');
      return;
    }
    setState(() => video = x.path);
  }

  Future<void> save() async {
    final p = int.tryParse(price.text.trim());
    if (title.text.trim().isEmpty || p == null) {
      _msg('Title aur price sahi daalo');
      return;
    }
    setState(() {
      busy = true;
      progress = 'Listing ban rahi hai...';
    });
    try {
      final urls = <String>[];
      var videoUrl = '';
      if (mediaReady) {
        for (var i = 0; i < photos.length; i++) {
          if (mounted) setState(() => progress = 'Photo ${i + 1}/${photos.length} upload ho rahi hai...');
          urls.add(await uploadMedia(photos[i], false));
        }
        if (video.isNotEmpty) {
          if (mounted) setState(() => progress = 'Video upload ho rahi hai (thoda time lagega)...');
          videoUrl = await uploadMedia(video, true);
        }
      } else if (photos.isNotEmpty || video.isNotEmpty) {
        _msg('Photo/video upload abhi band hai (Cloudinary setup baaki). ID bina photo ke ja rahi hai.');
      }
      await FirebaseFirestore.instance.collection('listings').add({
        'game': game,
        'title': title.text.trim(),
        'level': level.text.trim(),
        'price': p,
        'desc': desc.text.trim(),
        'contact': contact.text.trim(),
        'photos': urls,
        'video': videoUrl,
        'status': 'available',
        'sellerId': FirebaseAuth.instance.currentUser?.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _msg('Upload fail: $e');
      if (mounted) setState(() => busy = false);
    }
  }

  Widget field(String label, TextEditingController c,
      {bool number = false, int lines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: c,
        maxLines: lines,
        keyboardType: number ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ID becho'), backgroundColor: kDeep),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'ff', label: Text('Free Fire')),
              ButtonSegment(value: 'bgmi', label: Text('BGMI')),
            ],
            selected: {game},
            onSelectionChanged: (s) => setState(() => game = s.first),
          ),
          const SizedBox(height: 16),
          field('Title (jaise: Elite Pass + 10 skins)', title),
          field('Level', level, number: true),
          field('Price (₹)', price, number: true),
          field('Aapka contact number', contact, number: true),
          field('Details (skins, rank, etc.)', desc, lines: 3),
          Text('Photo (${photos.length}/10)'),
          const SizedBox(height: 8),
          if (photos.isNotEmpty)
            SizedBox(
              height: 78,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (var i = 0; i < photos.length; i++)
                    GestureDetector(
                      onTap: () => setState(() => photos.removeAt(i)),
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(File(photos[i]), width: 78, height: 78, fit: BoxFit.cover),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          if (photos.isNotEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 4, bottom: 4),
              child: Text('Photo hatane ke liye usko dabao.', style: TextStyle(fontSize: 12)),
            ),
          OutlinedButton.icon(
            onPressed: busy ? null : pickPhotos,
            icon: const Icon(Icons.add_a_photo),
            label: const Text('Photo chuno (max 10)'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: busy ? null : pickVideo,
            icon: const Icon(Icons.videocam),
            label: Text(video.isEmpty ? 'Video chuno' : 'Video chuni gayi (badalne ke liye dabao)'),
          ),
          const SizedBox(height: 14),
          const Text('ID ka password yahan mat likho. Ye payment ke baad chat mein dena hai.',
              style: TextStyle(fontSize: 12)),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: busy ? null : save,
            style: FilledButton.styleFrom(
                backgroundColor: kPurple, padding: const EdgeInsets.symmetric(vertical: 16)),
            child: Text(busy ? progress : 'Listing daalo'),
          ),
        ],
      ),
    );
  }
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  void _logout(BuildContext context) {
    final nav = Navigator.of(context);
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Kya aap logout karna chahte ho?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Nahi'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogCtx);
              await FirebaseAuth.instance.signOut();
              nav.popUntil((r) => r.isFirst);
            },
            child: const Text('Haan, logout'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final who = user?.phoneNumber?.isNotEmpty == true
        ? user!.phoneNumber!
        : (user?.email ?? '');
    return Scaffold(
      appBar: AppBar(title: const Text('Settings'), backgroundColor: kDeep),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Account'),
            subtitle: Text(who),
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text('Logout'),
            onTap: () => _logout(context),
          ),
        ],
      ),
    );
  }
}
