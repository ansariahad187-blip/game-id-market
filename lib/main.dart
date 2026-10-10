import 'dart:convert';
import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

const ffB64 = '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';
const bgmiB64 = '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';

final listings = ValueNotifier<List<Map<String, dynamic>>>([
  {'game': 'ff', 'title': 'Elite Pass + 12 skins', 'level': '72', 'price': 1500, 'desc': 'Diamond rank, rare bundles'},
  {'game': 'ff', 'title': 'Old account, rare emotes', 'level': '65', 'price': 900, 'desc': 'Heroic, 3 gun skins'},
  {'game': 'bgmi', 'title': 'Conqueror, Mythic outfits', 'level': '80', 'price': 4500, 'desc': 'Rare gun skins, 40+ outfits'},
  {'game': 'bgmi', 'title': 'Ace rank account', 'level': '60', 'price': 2200, 'desc': 'Season rewards, UC spent'},
]);

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

  Future<void> googleLogin() async {
    setState(() => loading = true);
    try {
      if (kIsWeb) {
        await auth.signInWithPopup(GoogleAuthProvider());
      } else {
        await auth.signInWithProvider(GoogleAuthProvider());
      }
    } on FirebaseAuthException catch (e) {
      if (e.code != 'canceled' && e.code != 'popup-closed-by-user') {
        _msg(e.message ?? 'Google login fail');
      }
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
                  const SizedBox(height: 20),
                  const Center(child: Text('ya')),
                  const SizedBox(height: 20),
                  OutlinedButton(
                    onPressed: loading ? null : googleLogin,
                    style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black87,
                        padding: const EdgeInsets.symmetric(vertical: 14)),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.g_mobiledata, size: 30, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Google se Sign in karo'),
                      ],
                    ),
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
        ValueListenableBuilder<List<Map<String, dynamic>>>(
          valueListenable: listings,
          builder: (_, all, __) {
            final items = all.where((e) => e['game'] == game).toList();
            if (items.isEmpty) {
              return const Center(child: Text('Abhi koi ID nahi hai.'));
            }
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
              itemCount: items.length,
              itemBuilder: (_, i) {
                final d = items[i];
                return Card(
                  color: kDeep.withOpacity(0.75),
                  child: ListTile(
                    title: Text('${d['title']}'),
                    subtitle: Text('Level ${d['level']}  |  ${d['desc']}'),
                    trailing: Text('₹${d['price']}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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

  void save() {
    final p = int.tryParse(price.text.trim());
    if (title.text.trim().isEmpty || p == null) return;
    listings.value = [
      {'game': game, 'title': title.text.trim(), 'level': level.text.trim(), 'price': p, 'desc': desc.text.trim()},
      ...listings.value,
    ];
    Navigator.pop(context);
  }

  Widget field(String label, TextEditingController c, {bool number = false, int lines = 1}) {
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
          field('Details (skins, rank, etc.)', desc, lines: 3),
          const Text('ID ka password yahan mat likho. Ye payment ke baad chat mein dena hai.',
              style: TextStyle(fontSize: 12)),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: save,
            style: FilledButton.styleFrom(
                backgroundColor: kPurple, padding: const EdgeInsets.symmetric(vertical: 16)),
            child: const Text('Listing daalo'),
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
