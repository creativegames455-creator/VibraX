import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  final sum = key.codeUnits.fold<int>(0, (a, b) => a + b);
  return Colors.primaries[sum % Colors.primaries.length].shade700;
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
      theme: ThemeData(
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.graphic_eq, size: 72),
                const SizedBox(height: 12),
                const Text(
                  'VibraX',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                      labelText: 'Email', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _password,
                  obscureText: true,
                  decoration: const InputDecoration(
                      labelText: 'Password (6+ characters)',
                      border: OutlineInputBorder()),
                ),
                const SizedBox(height: 20),
                if (_loading)
                  const Center(child: CircularProgressIndicator())
                else ...[
                  FilledButton(
                    onPressed: () => _submit(false),
                    child: const Padding(
                      padding: EdgeInsets.all(14),
                      child: Text('Log in'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton(
                    onPressed: () => _submit(true),
                    child: const Padding(
                      padding: EdgeInsets.all(14),
                      child: Text('Create account'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
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
      bottomNavigationBar: NavigationBar(
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
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color, Colors.black],
        ),
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
    );
  }
}

class DiscoverScreen extends StatelessWidget {
  const DiscoverScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Discover')),
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
    if (caption.isEmpty) {
      _msg('Write a caption first');
      return;
    }
    setState(() => _busy = true);
    try {
      await supabase
          .from('posts')
          .insert({'caption': caption, 'username': currentUsername()});
      _controller.clear();
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
      appBar: AppBar(title: const Text('Create')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              height: 160,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white24),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(child: Icon(Icons.video_call, size: 56)),
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
      appBar: AppBar(title: const Text('Live now')),
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
      appBar: AppBar(
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
