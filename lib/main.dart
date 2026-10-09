import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';

const supabaseUrl = 'https://rqsyygahmvfmmehbenan.supabase.co';
const supabaseKey = 'sb_publishable_ec0ipH62eEDBdzxM04MKyQ_oKOdN8g5';

SupabaseClient get supabase => Supabase.instance.client;

final ValueNotifier<List<Map<String, dynamic>>> postsNotifier =
    ValueNotifier<List<Map<String, dynamic>>>([]);
final ValueNotifier<String?> postsError = ValueNotifier<String?>(null);

Future<void> loadPosts() async {
  try {
    final data = await supabase
        .from('posts')
        .select()
        .order('created_at', ascending: false)
        .limit(50);
    postsNotifier.value = List<Map<String, dynamic>>.from(data);
    postsError.value = null;
  } catch (e) {
    postsError.value = e.toString();
  }
}

Color colorFor(String key) {
  const palette = [
    Color(0xE6FF4FA3),
    Color(0xE6D6329C),
    Color(0xE6B026D6),
    Color(0xE68E2DE2),
    Color(0xE6E0407F),
    Color(0xE6C2185B),
  ];
  var h = 0;
  for (final c in key.codeUnits) {
    h = (h * 31 + c) & 0x7fffffff;
  }
  return palette[h % palette.length];
}

String currentUsername() {
  final email = supabase.auth.currentUser?.email ?? 'user';
  return email.split('@').first;
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseKey);
  runApp(const VibraXApp());
}

class VibraXApp extends StatelessWidget {
  const VibraXApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VibraX',
      debugShowCheckedModeBanner: false,
      builder: (context, child) => Stack(
          fit: StackFit.expand,
          children: [const LoginBackground(), if (child != null) child],
        ),
        theme: ThemeData(
        scaffoldBackgroundColor: Colors.transparent, // VIBRAX_INNER

        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF2D87),
          brightness: Brightness.dark,
        ),
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: supabase.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = supabase.auth.currentSession;
        return session == null ? const LoginScreen() : const MainShell();
      },
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  bool _remember = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _msg(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  Future<void> _submit(bool signUp) async {
    final email = _email.text.trim();
    final password = _password.text;
    if (email.isEmpty || password.length < 6) {
      _msg('Enter an email and a password of at least 6 characters');
      return;
    }
    setState(() => _loading = true);
    try {
      if (signUp) {
        final res =
            await supabase.auth.signUp(email: email, password: password);
        if (res.session == null) {
          _msg('Account created. Check your email to confirm, then log in.');
        }
      } else {
        await supabase.auth.signInWithPassword(email: email, password: password);
      }
    } on AuthException catch (e) {
      _msg(e.message);
    } catch (e) {
      _msg('Something went wrong: $e');
    }
    if (mounted) setState(() => _loading = false);
  }

  Widget _pill({
    required TextEditingController c,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? trailing,
    TextInputType? type,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0x99120414),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: kPink, width: 1.5),
      ),
      child: Row(
        children: [
          Icon(icon, color: kPink),
          Container(
            width: 1,
            height: 28,
            margin: const EdgeInsets.symmetric(horizontal: 14),
            color: Colors.white24,
          ),
          Expanded(
            child: TextField(
              controller: c,
              obscureText: obscure,
              keyboardType: type,
              style: const TextStyle(fontSize: 17),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: hint,
                hintStyle: const TextStyle(color: Colors.white60),
              ),
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  void _soon() => _msg('Coming soon');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const LoginBackground(),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 26, vertical: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const VibraLogo(),
                    const SizedBox(height: 28),
                    _pill(
                      c: _email,
                      hint: 'Email',
                      icon: Icons.mail_outline,
                      type: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 14),
                    _pill(
                      c: _password,
                      hint: 'Password',
                      icon: Icons.lock_outline,
                      obscure: _obscure,
                      trailing: IconButton(
                        icon: Icon(_obscure
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => setState(() => _remember = !_remember),
                          child: Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _remember ? kPink : Colors.transparent,
                              border: Border.all(color: kPink),
                            ),
                            child: _remember
                                ? const Icon(Icons.check,
                                    size: 18, color: Colors.white)
                                : null,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text('Remember me'),
                        const Spacer(),
                        GestureDetector(
                          onTap: _soon,
                          child: const Text(
                            'Forgot Password?',
                            style: TextStyle(
                                color: kPink, fontWeight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.favorite_border,
                            color: kPink, size: 20),
                      ],
                    ),
                    const SizedBox(height: 22),
                    if (_loading)
                      const Center(child: CircularProgressIndicator())
                    else
                      Container(
                        height: 58,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF4FA3), Color(0xFFB026D6)],
                          ),
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x88FF4FA3),
                              blurRadius: 22,
                              offset: Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(32),
                            onTap: () => _submit(false),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.favorite, color: Colors.white70),
                                SizedBox(width: 12),
                                Text(
                                  'Log In',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(width: 10),
                                Icon(Icons.arrow_forward, color: Colors.white),
                              ],
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Expanded(child: Container(height: 1, color: Colors.white24)),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Row(
                            children: [
                              Icon(Icons.favorite, size: 14, color: kPink),
                              SizedBox(width: 6),
                              Text('OR'),
                              SizedBox(width: 6),
                              Icon(Icons.favorite, size: 14, color: kPink),
                            ],
                          ),
                        ),
                        Expanded(child: Container(height: 1, color: Colors.white24)),
                      ],
                    ),
                    const SizedBox(height: 22),
                    Center(
                      child: FractionallySizedBox(
                        widthFactor: 0.78,
                        child: GestureDetector(
                          onTap: _soon,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 14),
                            decoration: BoxDecoration(
                              color: const Color(0x66120414),
                              borderRadius: BorderRadius.circular(32),
                              border: Border.all(color: kPink, width: 1.4),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.person_outline, color: kPink),
                                Container(
                                  width: 1,
                                  height: 26,
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 14),
                                  color: Colors.white24,
                                ),
                                const Text('Continue with Email',
                                    style: TextStyle(fontSize: 16)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Don't have an account?"),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => _submit(true),
                          child: const Text(
                            'Sign Up  →',
                            style: TextStyle(
                              color: kPink,
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  static const _pages = [
    HomeScreen(),
    DiscoverScreen(),
    CreateScreen(),
    LiveScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    loadPosts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NavigationBar(backgroundColor: const Color(0xE6120414), indicatorColor: const Color(0x66FF4FA3), 
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home'),
          NavigationDestination(
              icon: Icon(Icons.explore_outlined),
              selectedIcon: Icon(Icons.explore),
              label: 'Discover'),
          NavigationDestination(
              icon: Icon(Icons.add_circle_outline),
              selectedIcon: Icon(Icons.add_circle),
              label: 'Create'),
          NavigationDestination(icon: Icon(Icons.sensors), label: 'Live'),
          NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profile'),
        ],
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<Map<String, dynamic>>>(
      valueListenable: postsNotifier,
      builder: (context, posts, _) {
        if (posts.isEmpty) {
          return SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.video_library_outlined, size: 56),
                    const SizedBox(height: 12),
                    ValueListenableBuilder<String?>(
                      valueListenable: postsError,
                      builder: (_, err, __) => Text(
                        err == null
                            ? 'No posts yet. Tap Create to share the first one.'
                            : 'Could not load posts: $err',
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: loadPosts,
                      child: const Text('Refresh'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        return Stack(
          children: [
            PageView.builder(
              scrollDirection: Axis.vertical,
              itemCount: posts.length,
              itemBuilder: (_, i) => PostCard(post: posts[i]),
            ),
            SafeArea(
              child: Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: loadPosts,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class PostCard extends StatefulWidget {
  final Map<String, dynamic> post;
  const PostCard({super.key, required this.post});
  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  bool _liked = false;
  @override
  Widget build(BuildContext context) {
    final p = widget.post;
    final color = colorFor('${p['id']}');
    final url = p['media_url'] as String?;
    return Stack(fit: StackFit.expand, children: [
      if (url != null && url.isNotEmpty)
        Positioned.fill(
          child: Image.network(url, fit: BoxFit.cover,
              errorBuilder: (c, e, st) => const SizedBox()),
        ),
      Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0x00000000), Color(0xDD0B0310)]),
      ),
      padding: const EdgeInsets.all(20),
      child: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Align(
              alignment: Alignment.bottomLeft,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('@${p['username'] ?? 'user'}',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text('${p['caption']}'),
                ],
              ),
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: IconButton(
                iconSize: 36,
                onPressed: () => setState(() => _liked = !_liked),
                icon: Icon(
                  _liked ? Icons.favorite : Icons.favorite_border,
                  color: _liked ? Colors.redAccent : Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    )]);
  }
}

class DiscoverScreen extends StatelessWidget {
  const DiscoverScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, scrolledUnderElevation: 0, centerTitle: true, title: const Text('Discover')),
      body: ValueListenableBuilder<List<Map<String, dynamic>>>(
        valueListenable: postsNotifier,
        builder: (context, posts, _) {
          if (posts.isEmpty) {
            return const Center(child: Text('Nothing to discover yet'));
          }
          return GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 0.75,
            ),
            itemCount: posts.length,
            itemBuilder: (_, i) => Container(
              decoration: BoxDecoration(
                color: colorFor('${posts[i]['id']}'),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(10),
              alignment: Alignment.bottomLeft,
              child: Text(
                '@${posts[i]['username'] ?? 'user'}\n${posts[i]['caption']}',
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          );
        },
      ),
    );
  }
}

class CreateScreen extends StatefulWidget {
  const CreateScreen({super.key});
  @override
  State<CreateScreen> createState() => _CreateScreenState();
}

class _CreateScreenState extends State<CreateScreen> {
  final _controller = TextEditingController();
  bool _busy = false;
  Uint8List? _bytes; // VIBRAX_PHOTO

  Future<void> _pick() async {
    final x = await ImagePicker().pickImage(
        source: ImageSource.gallery, maxWidth: 1600, imageQuality: 85);
    if (x == null) return;
    final bytes = await x.readAsBytes();
    if (!mounted) return;
    setState(() => _bytes = bytes);
  }


  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _msg(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  Future<void> _post() async {
    final caption = _controller.text.trim();
    if (caption.isEmpty && _bytes == null) {
      _msg('Write a caption first');
      return;
    }
    setState(() => _busy = true);
    try {
      String? mediaUrl;
      if (_bytes != null) {
        final uid = supabase.auth.currentUser!.id;
        final name = '$uid/${DateTime.now().millisecondsSinceEpoch}.jpg';
        await supabase.storage.from('media').uploadBinary(name, _bytes!,
            fileOptions: const FileOptions(contentType: 'image/jpeg'));
        mediaUrl = supabase.storage.from('media').getPublicUrl(name);
      }
      await supabase
          .from('posts')
          .insert({'caption': caption, 'username': currentUsername(), 'media_url': mediaUrl});
      _controller.clear();
      setState(() => _bytes = null);
      await loadPosts();
      _msg('Posted!');
    } catch (e) {
      _msg('Could not post: $e');
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, scrolledUnderElevation: 0, centerTitle: true, title: const Text('Create')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Container(
              height: 220,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white24),
                borderRadius: BorderRadius.circular(12),
              ),
              child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _pick,
              child: _bytes == null
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add_photo_alternate_outlined,
                              size: 56, color: kPink),
                          SizedBox(height: 6),
                          Text('Tap to choose a photo'),
                        ],
                      ),
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.memory(_bytes!,
                          fit: BoxFit.cover, width: double.infinity),
                    ),
            ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Write a caption',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _busy ? null : _post,
              icon: const Icon(Icons.send),
              label: Text(_busy ? 'Posting...' : 'Post'),
            ),
          ],
        ),
      ),
    );
  }
}

class LiveScreen extends StatelessWidget {
  const LiveScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, scrolledUnderElevation: 0, centerTitle: true, title: const Text('Live now')),
      body: ListView.builder(
        itemCount: 8,
        itemBuilder: (_, i) => ListTile(
          leading: CircleAvatar(
            backgroundColor: colorFor('live$i'),
            child: Text('${i + 1}'),
          ),
          title: Text('@streamer${i + 1}'),
          subtitle: Text('${120 + i * 45} watching'),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text('LIVE',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ),
      ),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, scrolledUnderElevation: 0, centerTitle: true, 
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => supabase.auth.signOut(),
          ),
        ],
      ),
      body: ValueListenableBuilder<List<Map<String, dynamic>>>(
        valueListenable: postsNotifier,
        builder: (context, all, _) {
          final mine = all.where((p) => p['user_id'] == user?.id).toList();
          return Column(
            children: [
              const SizedBox(height: 16),
              const CircleAvatar(
                  radius: 40, child: Icon(Icons.person, size: 40)),
              const SizedBox(height: 8),
              Text('@${currentUsername()}',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              Text(user?.email ?? ''),
              const SizedBox(height: 12),
              Text('${mine.length} posts',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(4),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 4,
                    crossAxisSpacing: 4,
                  ),
                  itemCount: mine.length,
                  itemBuilder: (_, i) => Container(
                    color: colorFor('${mine[i]['id']}'),
                    padding: const EdgeInsets.all(6),
                    alignment: Alignment.bottomLeft,
                    child: Text(
                      '${mine[i]['caption']}',
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}


const kPink = Color(0xFFFF4FA3);

class LoginBackground extends StatelessWidget {
  const LoginBackground({super.key});

  static const List<List<double>> _hearts = [
    [-0.9, -0.92, 26, 0.55],
    [-0.55, -0.7, 14, 0.4],
    [0.85, -0.95, 18, 0.5],
    [-0.95, -0.35, 44, 0.25],
    [0.95, -0.2, 34, 0.3],
    [-0.8, 0.15, 20, 0.35],
    [0.9, 0.4, 46, 0.25],
    [-0.9, 0.7, 36, 0.3],
    [0.7, 0.85, 22, 0.4],
    [0.1, 0.95, 16, 0.35],
  ];

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFB0306A),
                Color(0xFF6A1B5C),
                Color(0xFF2A0A33),
                Color(0xFF0B0310),
              ],
              stops: [0.0, 0.3, 0.65, 1.0],
            ),
          ),
        ),
        Align(
          alignment: const Alignment(0.6, -0.6),
          child: Container(
            width: 300,
            height: 300,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [Color(0xAAFFB86C), Color(0x00FFB86C)],
              ),
            ),
          ),
        ),
        for (final h in _hearts)
          Align(
            alignment: Alignment(h[0], h[1]),
            child: Icon(
              Icons.favorite,
              size: h[2],
              color: kPink.withValues(alpha: h[3]),
            ),
          ),
        const Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 170,
          child: CustomPaint(painter: GlowWavePainter()),
        ),
      ],
    );
  }
}

class GlowWavePainter extends CustomPainter {
  const GlowWavePainter();

  @override
  void paint(Canvas canvas, Size size) {
    void wave(double base, double amp, double width, Color color, double blur) {
      final w = size.width;
      final h = size.height;
      final path = Path()
        ..moveTo(0, h * base)
        ..cubicTo(w * 0.25, h * (base - amp), w * 0.45, h * (base + amp),
            w * 0.65, h * base)
        ..cubicTo(w * 0.8, h * (base - amp * 0.8), w * 0.92,
            h * (base - amp * 0.5), w, h * (base - amp * 0.2));
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..color = color;
      if (blur > 0) {
        paint.maskFilter = MaskFilter.blur(BlurStyle.normal, blur);
      }
      canvas.drawPath(path, paint);
    }

    wave(0.62, 0.35, 6, const Color(0x99FF4FA3), 6);
    wave(0.62, 0.35, 1.5, const Color(0xFFFF7FC0), 0);
    wave(0.78, 0.30, 5, const Color(0x77B026D6), 5);
    wave(0.78, 0.30, 1.2, const Color(0xFFD070F0), 0);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class VibraLogo extends StatelessWidget {
  const VibraLogo({super.key});

  Widget _bar(double h) => Container(
        width: 8,
        height: h,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: kPink,
          borderRadius: BorderRadius.circular(6),
          boxShadow: const [BoxShadow(color: Color(0x88FF4FA3), blurRadius: 10)],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _bar(34),
            _bar(58),
            const SizedBox(width: 6),
            Stack(
              alignment: Alignment.center,
              children: [
                ShaderMask(
                  shaderCallback: (r) => const LinearGradient(
                    colors: [Color(0xFFFF4FA3), Color(0xFFB026D6)],
                  ).createShader(r),
                  child: const Icon(Icons.favorite_border,
                      size: 96, color: Colors.white),
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Icon(Icons.play_arrow_rounded, size: 40, color: kPink),
                ),
              ],
            ),
            const SizedBox(width: 6),
            _bar(58),
            _bar(34),
          ],
        ),
        const SizedBox(height: 6),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'Vibra',
                style: GoogleFonts.pacifico(fontSize: 52, color: Colors.white),
              ),
              TextSpan(
                text: 'X',
                style: GoogleFonts.pacifico(
                  fontSize: 52,
                  color: kPink,
                  shadows: const [
                    Shadow(color: Color(0xAAFF4FA3), blurRadius: 18),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Connect  ♥  Share  ♥  Love',
          style: GoogleFonts.dancingScript(fontSize: 20, color: Colors.white),
        ),
      ],
    );
  }
}
