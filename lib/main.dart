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
    LiveScreen(),
    MessageScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    loadPosts();
  }

  Widget _footer() {
    const labels = ['Home', 'Discover', 'Live', 'Message', 'Profile'];
    const icons = [
      Icons.home_outlined,
      Icons.explore_outlined,
      Icons.videocam,
      Icons.chat_bubble_outline,
      Icons.person_outline,
    ];
    const selIcons = [
      Icons.home,
      Icons.explore,
      Icons.videocam,
      Icons.chat_bubble,
      Icons.person,
    ];
    return Container(
      color: const Color(0xE6120414),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 72,
          child: Row(children: [
            for (var i = 0; i < 5; i++)
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => _index = i),
                  child: i == 2
                      ? Center(
                          child: Transform.translate(
                            offset: const Offset(0, -6),
                            child: Container(
                              width: 68,
                              height: 52,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                    colors: [Color(0xFF8E2DE2), kPink]),
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(
                                      color: kPink.withValues(alpha: 0.5),
                                      blurRadius: 14)
                                ],
                              ),
                              child: Icon(Icons.videocam,
                                  color: Colors.white,
                                  size: _index == 2 ? 34 : 30),
                            ),
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
Container(
  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
  decoration: BoxDecoration(
    color: _index == i ? const Color(0x66FF4FA3) : Colors.transparent,
    borderRadius: BorderRadius.circular(20)),
  child:                             Icon(_index == i ? selIcons[i] : icons[i],
                                color:
                                    _index == i ? Colors.white : Colors.white70)),
                            const SizedBox(height: 4),
                            Text(labels[i],
                                style: TextStyle(
                                    fontSize: 12,
                                    color: _index == i ? Colors.white : Colors.white70)),
                          ],
                        ),
                ),
              ),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: _footer(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 1;
  int _chip = 0;
  static const _tabs = ['Video Chat', 'Featured', 'Party', 'Global', 'Nearby'];
  static const _chipNames = ['Recommend', 'Head2Head', 'Singing', 'Chat'];
  static const _chipIcons = [
    Icons.local_fire_department,
    Icons.sports_mma,
    Icons.mic,
    Icons.chat_bubble_outline,
  ];

  Color get _glass => Colors.white.withValues(alpha: 0.14);

  void _open(Map<String, dynamic> p) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: PostCard(post: p),
      ),
    ));
  }

  Widget _topTabs() => Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
        child: Row(children: [
          IconButton(
              icon: const Icon(Icons.search),
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Search - coming soon')))),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(_tabs.length, (i) {
                  final sel = i == _tab;
                  return GestureDetector(
                    onTap: () => setState(() => _tab = i),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Text(_tabs[i],
                            style: TextStyle(
                                fontSize: sel ? 22 : 18,
                                fontWeight:
                                    sel ? FontWeight.bold : FontWeight.w400,
                                color: sel ? Colors.white : Colors.white54)),
                        const SizedBox(height: 3),
                        Container(
                          height: 4,
                          width: sel ? 36 : 0,
                          decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                  colors: [Color(0xFF8E2DE2), kPink]),
                              borderRadius: BorderRadius.circular(4)),
                        ),
                      ]),
                    ),
                  );
                }),
              ),
            ),
          ),
          IconButton(
              icon: const Icon(Icons.emoji_events_outlined, color: kPink),
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Ranking - coming soon')))),
        ]),
      );

  Widget _chipRow() => Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
        child: Row(children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(_chipNames.length, (i) {
                  final sel = i == _chip;
                  return GestureDetector(
                    onTap: () => setState(() => _chip = i),
                    child: Container(
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                          gradient: sel
                              ? const LinearGradient(
                                  colors: [Color(0xFF8E2DE2), kPink])
                              : null,
                          color: sel ? null : _glass,
                          borderRadius: BorderRadius.circular(30)),
                      child: Row(children: [
                        Icon(_chipIcons[i], size: 22, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(_chipNames[i],
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500)),
                      ]),
                    ),
                  );
                }),
              ),
            ),
          ),
          IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Filter - coming soon')))),
        ]),
      );

  Widget _ranking(List<Map<String, dynamic>> posts) {
    final top = posts.take(3).toList();
    return GestureDetector(
      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Diamond Ranking - coming soon'))),
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 4, 12, 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Color(0xFF5B2BD1), Color(0xFF8E2DE2), kPink]),
            borderRadius: BorderRadius.circular(22)),
        child: Row(children: [
          const Text('Diamond Ranking',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
                color: Colors.white24, borderRadius: BorderRadius.circular(6)),
            child: const Text('Day',
                style: TextStyle(color: Colors.white, fontSize: 12)),
          ),
          const Spacer(),
          SizedBox(
            width: 90,
            height: 36,
            child: Stack(children: [
              for (var i = 0; i < top.length; i++)
                Positioned(
                  left: i * 24.0,
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.white,
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: colorFor('${top[i]['id']}'),
                      child: Text(
                          '${top[i]['username'] ?? 'u'}'
                              .substring(0, 1)
                              .toUpperCase(),
                          style: const TextStyle(color: Colors.white)),
                    ),
                  ),
                ),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _card(Map<String, dynamic> p) {
    final url = p['media_url'] as String?;
    return GestureDetector(
      onTap: () => _open(p),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(fit: StackFit.expand, children: [
          Container(color: colorFor('${p['id']}')),
          if (url != null && url.isNotEmpty)
            Image.network(url,
                fit: BoxFit.cover, errorBuilder: (c, e, st) => const SizedBox()),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.7)
                  ],
                  stops: const [0.45, 1.0],
                ),
              ),
            ),
          ),
          Positioned(
            left: 10,
            right: 10,
            bottom: 10,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.equalizer, size: 16, color: Colors.white),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text('${p['caption'] ?? ''}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12)),
                  ),
                ]),
                const SizedBox(height: 2),
                Row(children: [
                  Expanded(
                    child: Text('${p['username'] ?? 'user'}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.bold)),
                  ),
                  const Icon(Icons.local_fire_department,
                      size: 16, color: kPink),
                  const SizedBox(width: 2),
                  Text('${p['likes'] ?? 0}',
                      style: const TextStyle(color: Colors.white70)),
                ]),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: ValueListenableBuilder<List<Map<String, dynamic>>>(
          valueListenable: postsNotifier,
          builder: (context, posts, _) {
            return CustomScrollView(slivers: [
              SliverToBoxAdapter(child: _topTabs()),
              SliverToBoxAdapter(child: _chipRow()),
              SliverToBoxAdapter(child: _ranking(posts)),
              if (posts.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                      child: Text('No posts yet. Tap Create to share the first one.')),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 110),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 1,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => _card(posts[i]),
                      childCount: posts.length,
                    ),
                  ),
                ),
            ]);
          },
        ),
      ),
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

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});
  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  int _tab = 0;
  int _mchip = 0;

  void _soon(String t) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text('$t - coming soon')));

  void _open(Map<String, dynamic> p) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: PostCard(post: p),
      ),
    ));
  }

  Widget _header() {
    const names = ['Live', 'Moments'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(children: [
        for (var i = 0; i < names.length; i++)
          GestureDetector(
            onTap: () => setState(() => _tab = i),
            child: Padding(
              padding: const EdgeInsets.only(right: 20),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(names[i],
                    style: TextStyle(
                        fontSize: _tab == i ? 28 : 24,
                        fontWeight:
                            _tab == i ? FontWeight.bold : FontWeight.w400,
                        color: _tab == i ? Colors.white : Colors.white54)),
                const SizedBox(height: 3),
                Container(
                  height: 4,
                  width: _tab == i ? 30 : 0,
                  decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [Color(0xFF8E2DE2), kPink]),
                      borderRadius: BorderRadius.circular(4)),
                ),
              ]),
            ),
          ),
        const Spacer(),
        IconButton(
            icon: const Icon(Icons.notifications_none, size: 30),
            onPressed: () => _soon('Notifications')),
        const SizedBox(width: 4),
        GestureDetector(
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => Scaffold(
                    appBar: AppBar(
                        backgroundColor: Colors.transparent, elevation: 0),
                    body: const CreateScreen(),
                  ))),
          child: Container(
            width: 70,
            height: 46,
            decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFF8E2DE2), kPink]),
                borderRadius: BorderRadius.circular(24)),
            child: const Icon(Icons.send_outlined, color: Colors.white),
          ),
        ),
      ]),
    );
  }

  Widget _card(Map<String, dynamic> p) {
    final url = p['media_url'] as String?;
    return GestureDetector(
      onTap: () => _open(p),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(fit: StackFit.expand, children: [
          Container(color: colorFor('${p['id']}')),
          if (url != null && url.isNotEmpty)
            Image.network(url,
                fit: BoxFit.cover,
                errorBuilder: (c, e, st) => const SizedBox()),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.7)
                  ],
                  stops: const [0.55, 1.0],
                ),
              ),
            ),
          ),
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: Row(children: [
              Expanded(
                child: Text('${p['username'] ?? 'user'}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
              ),
              const Icon(Icons.local_fire_department,
                  size: 16, color: Colors.white54),
              const SizedBox(width: 2),
              Text('${p['likes'] ?? 0}',
                  style: const TextStyle(color: Colors.white54)),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _momentChips() {
    const names = ['Trending', 'Video', 'Paid', 'Following'];
    return SizedBox(
      height: 56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        itemCount: names.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (c, i) {
          final sel = i == _mchip;
          return GestureDetector(
            onTap: () => setState(() => _mchip = i),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                  gradient: sel
                      ? const LinearGradient(
                          colors: [Color(0xFF8E2DE2), kPink])
                      : null,
                  color: sel ? null : Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(30)),
              child: Row(children: [
                if (i == 0) ...[
                  const Icon(Icons.local_fire_department,
                      size: 18, color: Colors.white),
                  const SizedBox(width: 4),
                ],
                Text(names[i],
                    style: TextStyle(
                        color: sel ? Colors.white : Colors.white70,
                        fontSize: 16,
                        fontWeight: FontWeight.w500)),
              ]),
            ),
          );
        },
      ),
    );
  }

  Widget _momentTile(Map<String, dynamic> p) {
    final url = p['media_url'] as String?;
    return GestureDetector(
      onTap: () => _open(p),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(18)),
        child: Row(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              width: 70,
              height: 70,
              child: Stack(fit: StackFit.expand, children: [
                Container(color: colorFor('${p['id']}')),
                if (url != null && url.isNotEmpty)
                  Image.network(url,
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, st) => const SizedBox()),
              ]),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${p['username'] ?? 'user'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('${p['caption'] ?? ''}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white70)),
                ]),
          ),
          const Icon(Icons.local_fire_department, size: 18, color: kPink),
          const SizedBox(width: 2),
          Text('${p['likes'] ?? 0}',
              style: const TextStyle(color: Colors.white70)),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: ValueListenableBuilder<List<Map<String, dynamic>>>(
          valueListenable: postsNotifier,
          builder: (context, posts, _) {
            return CustomScrollView(slivers: [
              SliverToBoxAdapter(child: _header()),
              if (_tab == 1) SliverToBoxAdapter(child: _momentChips()),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 12),
                  child: Text(_tab == 0 ? 'Recommended' : 'Latest moments',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w600)),
                ),
              ),
              if (posts.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: Text('No posts yet.')),
                )
              else if (_tab == 0)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 110),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 1,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => _card(posts[i]),
                      childCount: posts.length,
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 110),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => _momentTile(posts[i]),
                      childCount: posts.length,
                    ),
                  ),
                ),
            ]);
          },
        ),
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
              border: Border.all(color: kPink, width: 1.5),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(color: kPink.withValues(alpha: 0.35), blurRadius: 18, spreadRadius: 1),
              ],
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
                borderRadius: BorderRadius.circular(22),
                      child: Image.memory(_bytes!,
                          fit: BoxFit.cover, width: double.infinity),
                    ),
            ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: kPink.withOpacity(0.35), blurRadius: 18, spreadRadius: 1),
                ],
              ),
              child: TextField(
                controller: _controller,
                maxLines: 3,
                style: const TextStyle(color: Colors.white),
                cursorColor: kPink,
                decoration: InputDecoration(
                  labelText: 'Write a caption',
                  labelStyle: const TextStyle(color: Colors.white70),
                  floatingLabelStyle: TextStyle(color: kPink),
                  filled: true,
                  fillColor: Colors.black.withOpacity(0.25),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: kPink, width: 1.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: kPink, width: 2.5),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(color: kPink.withOpacity(0.6), blurRadius: 22, spreadRadius: 1),
                ],
              ),
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: kPink,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(56),
                  shape: const StadiumBorder(),
                ),
                onPressed: _busy ? null : _post,
                icon: const Icon(Icons.send),
                label: Text(
                  _busy ? 'Posting...' : 'Post',
                  style: const TextStyle(fontWeight: FontWeight.w600, letterSpacing: 1),
                ),
              ),
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

  void _soon(BuildContext c, String t) => ScaffoldMessenger.of(c)
      .showSnackBar(SnackBar(content: Text('$t - coming soon')));

  Color get _glass => Colors.white.withValues(alpha: 0.12);

  Widget _badge(String t, IconData i, Color c) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration:
            BoxDecoration(color: c, borderRadius: BorderRadius.circular(10)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(i, size: 12, color: Colors.white),
          const SizedBox(width: 3),
          Text(t, style: const TextStyle(color: Colors.white, fontSize: 11)),
        ]),
      );

  Widget _stat(BuildContext c, String label, int v) => Expanded(
        child: GestureDetector(
          onTap: () => _soon(c, label),
          child: Column(children: [
            Text('$v',
                style: const TextStyle(
                    fontSize: 26, fontWeight: FontWeight.bold)),
            Text(label, style: const TextStyle(color: Colors.white70)),
          ]),
        ),
      );

  Widget _bigCard(BuildContext c, String t, IconData i, List<Color> g) =>
      Expanded(
        child: GestureDetector(
          onTap: () => _soon(c, t),
          child: Container(
            height: 80,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                gradient: LinearGradient(colors: g),
                borderRadius: BorderRadius.circular(16)),
            child: Stack(children: [
              Text(t,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              Align(
                  alignment: Alignment.bottomRight,
                  child: Icon(i, color: Colors.white70, size: 32)),
            ]),
          ),
        ),
      );

  Widget _group(BuildContext c, List<_ProfItem> items) => Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        decoration: BoxDecoration(
            color: _glass, borderRadius: BorderRadius.circular(16)),
        child: Column(
          children: items
              .map((e) => ListTile(
                    onTap: () => _soon(c, e.title),
                    leading: Icon(e.icon, color: Colors.white),
                    title: Text(e.title),
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                      if (e.tag != null)
                        Text(e.tag!,
                            style: const TextStyle(
                                color: kPink,
                                fontStyle: FontStyle.italic,
                                fontWeight: FontWeight.bold)),
                      const Icon(Icons.chevron_right, color: Colors.white54),
                    ]),
                  ))
              .toList(),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;
    final uid = user?.id ?? '';
    final shortId = uid.length >= 9 ? uid.substring(0, 9) : uid;
    const grid = [
      _ProfItem('Transaction History', Icons.receipt_long),
      _ProfItem('VIP Center', Icons.diamond_outlined),
      _ProfItem('Level', Icons.leaderboard),
      _ProfItem('Broadcaster Class', Icons.workspace_premium_outlined),
      _ProfItem('My Badge', Icons.verified_outlined),
      _ProfItem('My Bag', Icons.shopping_bag_outlined),
      _ProfItem('Store', Icons.storefront),
      _ProfItem('Task Center', Icons.task_alt),
      _ProfItem('Event Calendar', Icons.calendar_month),
    ];
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        title: const Text('Me',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
              icon: const Icon(Icons.qr_code_scanner),
              onPressed: () => _soon(context, 'Scan')),
          IconButton(
              icon: const Icon(Icons.settings_outlined),
              onPressed: () => _soon(context, 'Settings')),
          IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => supabase.auth.signOut()),
        ],
      ),
      body: ValueListenableBuilder<List<Map<String, dynamic>>>(
        valueListenable: postsNotifier,
        builder: (context, all, _) {
          final mine = all.where((p) => p['user_id'] == user?.id).toList();
          return ListView(
            padding: const EdgeInsets.only(bottom: 110),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(children: [
                  const CircleAvatar(
                      radius: 40, child: Icon(Icons.person, size: 40)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('@${currentUsername()}',
                              style: const TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold)),
                          Text(user?.email ?? '',
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 12)),
                          const SizedBox(height: 4),
                          Row(children: [
                            Text('ID: $shortId',
                                style:
                                    const TextStyle(color: Colors.white70)),
                            const SizedBox(width: 6),
                            const Icon(Icons.copy,
                                size: 14, color: Colors.white70),
                          ]),
                          const SizedBox(height: 6),
                          Wrap(spacing: 6, children: [
                            _badge('0', Icons.shield, Colors.grey),
                            _badge('1', Icons.add, Colors.green),
                            _badge('BLv.1', Icons.diamond, Colors.orange),
                            _badge('LV.1', Icons.hexagon, Colors.deepOrange),
                          ]),
                        ]),
                  ),
                  const Icon(Icons.chevron_right),
                ]),
              ),
              GestureDetector(
                onTap: () => _soon(context, 'Member'),
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                      color: _glass, borderRadius: BorderRadius.circular(16)),
                  child: Row(children: [
                    const Text('Me+ ',
                        style: TextStyle(
                            color: kPink,
                            fontStyle: FontStyle.italic,
                            fontSize: 22,
                            fontWeight: FontWeight.bold)),
                    const Text('Member',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                          gradient: const LinearGradient(
                              colors: [Color(0xFF8E2DE2), kPink]),
                          borderRadius: BorderRadius.circular(20)),
                      child: const Text('First Week  480',
                          style: TextStyle(color: Colors.white)),
                    ),
                  ]),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(children: [
                  _stat(context, 'Fans', 0),
                  _stat(context, 'Following', 0),
                  _stat(context, 'Coins', 0),
                  _stat(context, 'Diamond', 0),
                ]),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(children: [
                  _bigCard(context, 'Recharge', Icons.account_balance_wallet,
                      const [Color(0xFF8E2DE2), kPink]),
                  _bigCard(context, 'NVIP', Icons.workspace_premium,
                      const [kPink, Color(0xFFFF8A5B)]),
                  _bigCard(context, 'Game', Icons.sports_esports,
                      const [Color(0xFF5B2BD1), Color(0xFF8E2DE2)]),
                ]),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 20, 12, 0),
                child: GridView.count(
                  crossAxisCount: 4,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 0.85,
                  children: grid
                      .map((e) => GestureDetector(
                            onTap: () => _soon(context, e.title),
                            child: Column(children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                        colors: [Color(0xFF8E2DE2), kPink]),
                                    borderRadius: BorderRadius.circular(16)),
                                child: Icon(e.icon, color: Colors.white),
                              ),
                              const SizedBox(height: 6),
                              Text(e.title,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      color: Colors.white70, fontSize: 11)),
                            ]),
                          ))
                      .toList(),
                ),
              ),
              _group(context, const [
                _ProfItem('League', Icons.emoji_events_outlined),
                _ProfItem('My Subscribers', Icons.bookmark_add_outlined),
                _ProfItem('My Subscriptions', Icons.subscriptions_outlined),
                _ProfItem('FAM', Icons.family_restroom),
                _ProfItem('Guardian', Icons.shield_outlined),
                _ProfItem('My Companionship', Icons.favorite_border),
                _ProfItem('Top Fans', Icons.star_border),
                _ProfItem('Fans Group', Icons.groups_outlined),
                _ProfItem('Visitor Records', Icons.person_search_outlined,
                    tag: 'Me+ Gold'),
                _ProfItem('History', Icons.history),
              ]),
              _group(context, const [
                _ProfItem('Broadcast Data', Icons.bar_chart),
                _ProfItem('Audience', Icons.people_outline),
                _ProfItem('Replay', Icons.replay_circle_filled_outlined),
                _ProfItem('My Agency', Icons.business_center_outlined),
              ]),
              _group(context, const [
                _ProfItem('Feedback', Icons.headset_mic_outlined),
              ]),
              const SizedBox(height: 16),
              Center(
                child: Text('${mine.length} posts',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 8),
              GridView.builder(
                padding: const EdgeInsets.all(4),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 4,
                  crossAxisSpacing: 4,
                ),
                itemCount: mine.length,
                itemBuilder: (_, i) {
                  final url = mine[i]['media_url'] as String?;
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Container(color: colorFor('${mine[i]['id']}')),
                        if (url != null && url.isNotEmpty)
                          Image.network(url,
                              fit: BoxFit.cover,
                              errorBuilder: (c, e, st) => const SizedBox()),
                        Container(
                          padding: const EdgeInsets.all(6),
                          alignment: Alignment.bottomLeft,
                          child: Text('${mine[i]['caption']}',
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ProfItem {
  final String title;
  final IconData icon;
  final String? tag;
  const _ProfItem(this.title, this.icon, {this.tag});
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
        Image.asset(
          'assets/login_bg.jpg',
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xB3B0306A),
                Color(0xB36A1B5C),
                Color(0xCC2A0A33),
                Color(0xE60B0310),
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

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: kPink.withValues(alpha: 0.6),
                blurRadius: 28,
                spreadRadius: 2,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: Image.asset(
              'assets/logo.jpg',
              width: 150,
              height: 150,
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Connect ♥ Share ♥ Love',
          style: GoogleFonts.dancingScript(fontSize: 20, color: Colors.white),
        ),
      ],
    );
  }
}


class MessageScreen extends StatelessWidget {
  const MessageScreen({super.key});

  void _soon(BuildContext c, String t) => ScaffoldMessenger.of(c)
      .showSnackBar(SnackBar(content: Text('$t - coming soon')));

  Widget _feature(BuildContext c, String title, IconData icon,
      List<Color> colors) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _soon(c, title),
        child: Container(
          height: 110,
          margin: const EdgeInsets.symmetric(horizontal: 5),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: colors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(22)),
          child: Stack(children: [
            Text(title,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            Positioned(
                right: 0,
                bottom: 0,
                child: Icon(icon, size: 44, color: Colors.white70)),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 110),
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text('Chat',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 12),
            Row(children: [
              _feature(context, 'Free Call', Icons.video_call,
                  const [Color(0xFF8E2DE2), Color(0xFFB44CFF)]),
              _feature(context, 'Mood bubble', Icons.bubble_chart,
                  const [Color(0xFFFF8A65), kPink]),
              _feature(context, 'Secret note', Icons.lock_outline,
                  const [Color(0xFF2B2640), Color(0xFF4A3F6B)]),
            ]),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => _soon(context, "Who's viewed me"),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20)),
                child: const Row(children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white24,
                    child: Icon(Icons.visibility_outlined,
                        color: Colors.white, size: 28),
                  ),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Who's viewed me",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold)),
                          SizedBox(height: 4),
                          Text('0 people viewed your profile',
                              style: TextStyle(color: Colors.white70)),
                        ]),
                  ),
                ]),
              ),
            ),
            const SizedBox(height: 40),
            const Center(
              child: Text('No messages yet.',
                  style: TextStyle(color: Colors.white54, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
