import 'package:flutter/material.dart';

void main() => runApp(const DreamJobApp());

// Tinder palette copied verbatim, will be rethemed to DreamJob later
const _tinderOrange = Color(0xFFFF6B33);
const _tinderPink = Color(0xFFFE2C55);
const _tinderDark = Color(0xFF111418);
const _tinderCardBg = Color(0xFF1A1E22);

class DreamJobApp extends StatelessWidget {
  const DreamJobApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DreamJob',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(seedColor: _tinderPink),
      ),
      home: const SplashScreen(),
    );
  }
}

// ---------- SPLASH ----------
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_tinderOrange, _tinderPink, Color(0xFFE91E63)],
          ),
        ),
        child: const Stack(
          children: [
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.local_fire_department, color: Colors.white, size: 48),
                  SizedBox(width: 8),
                  Text('tinder',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 52,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1)),
                ],
              ),
            ),
            Positioned(
              bottom: 48,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  Text('from',
                      style: TextStyle(color: Colors.white70, fontSize: 14)),
                  Text('MatchGroup',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------- LOGIN ----------
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_tinderOrange, _tinderPink, Color(0xFFE91E63)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                    onPressed: () {},
                  ),
                ),
                const Spacer(),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.local_fire_department, color: Colors.white, size: 44),
                    SizedBox(width: 8),
                    Text('tinder',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 48,
                            fontWeight: FontWeight.w800)),
                  ],
                ),
                const Spacer(),
                const Text(
                  "By tapping 'Create account' or 'Sign in' you agree to our Terms. Learn how we process your data in our Privacy Policy and Cookies Policy.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 12, height: 1.4),
                ),
                const SizedBox(height: 24),
                _loginBtn(Icons.apple, 'Sign in with Apple', () => _goHome(context)),
                _loginBtn(Icons.chat_bubble, 'Sign in with Line', () => _goHome(context)),
                _loginBtn(Icons.phone, 'Sign in with Phone Number',
                    () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PhoneScreen()))),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {},
                  child: const Text('Trouble signing in?',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static void _goHome(BuildContext c) => Navigator.pushReplacement(
      c, MaterialPageRoute(builder: (_) => const HomeShell()));

  static Widget _loginBtn(IconData icon, String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton.icon(
          onPressed: onTap,
          icon: Icon(icon, color: _tinderDark),
          label: Text(label,
              style: const TextStyle(
                  color: _tinderDark, fontSize: 16, fontWeight: FontWeight.w600)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          ),
        ),
      ),
    );
  }
}

class PhoneScreen extends StatelessWidget {
  const PhoneScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Your phone number?',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
            const SizedBox(height: 24),
            TextField(
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                hintText: '+57 300 000 0000',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: _tinderDark, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28))),
                onPressed: () => Navigator.pushReplacement(
                    context, MaterialPageRoute(builder: (_) => const HomeShell())),
                child: const Text('Next', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------- HOME SHELL ----------
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int index = 0;
  final pages = const [DeckScreen(), ExploreScreen(), LikesScreen(), ChatScreen(), ProfileScreen()];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: index == 0 ? _tinderDark : Colors.white,
      body: pages[index],
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 16),
        decoration: BoxDecoration(color: _tinderDark, borderRadius: BorderRadius.circular(32)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(0, Icons.local_fire_department, 'Swipe'),
              _navItem(1, Icons.explore_outlined, 'Explore'),
              _navItem(2, Icons.favorite_border, 'Likes', badge: '48'),
              _navItem(3, Icons.chat_bubble_outline, 'Chat', dot: true),
              _navItem(4, Icons.person_outline, 'Profile'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(int i, IconData icon, String label, {String? badge, bool dot = false}) {
    final active = i == index;
    return GestureDetector(
      onTap: () => setState(() => index = i),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? Colors.white24 : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(clipBehavior: Clip.none, children: [
              Icon(icon, color: active ? Colors.white : Colors.white70, size: 22),
              if (badge != null)
                Positioned(
                  right: -10,
                  top: -6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(color: const Color(0xFFFFC107), borderRadius: BorderRadius.circular(10)),
                    child: Text(badge, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800)),
                  ),
                ),
              if (dot)
                Positioned(
                  right: -4,
                  top: -2,
                  child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: _tinderPink, shape: BoxShape.circle)),
                ),
            ]),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(color: active ? Colors.white : Colors.white70, fontSize: 11, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

// ---------- DECK ----------
class DeckScreen extends StatefulWidget {
  const DeckScreen({super.key});
  @override
  State<DeckScreen> createState() => _DeckScreenState();
}

class _DeckScreenState extends State<DeckScreen> {
  int top = 0;
  double drag = 0;
  bool showMatch = false;
  final cards = [
    _CardData(
        name: 'Jasmine',
        age: 27,
        image: 'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=600',
        tags: ['Dog', 'Socially on weekends', 'Non-smoker', 'Often', 'Socially active', 'In a spectrum'],
        bio: 'Basics & Lifestyle'),
    _CardData(
        name: 'Yunieee',
        age: 21,
        image: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=600',
        tags: ['Pilates', 'Coffee', 'Travel'],
        bio: 'Looking for interesting people'),
    _CardData(
        name: 'Anya',
        age: 20,
        image: 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=600',
        tags: ['Design', 'Music', 'Yoga'],
        bio: '3 Photos'),
    _CardData(
        name: 'Sofia',
        age: 24,
        image: 'https://images.unsplash.com/photo-1488426862026-3ee34e13d85d?w=600',
        tags: ['Tech', 'Hiking', 'Books'],
        bio: 'New friends'),
  ];

  void _swipe(bool right) {
    if (right) {
      setState(() => showMatch = true);
      Future.delayed(const Duration(milliseconds: 1400), () {
        if (mounted) setState(() => showMatch = false);
      });
    }
    setState(() {
      top = (top + 1) % cards.length;
      drag = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final card = cards[top];
    return SafeArea(
      child: Stack(
        children: [
          Column(
            children: [
              // top filter bar
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.tune, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _chip('For You', true),
                            _chip('Astrology', false),
                            _chip('Double Date', false),
                            _chip('Music', false),
                          ],
                        ),
                      ),
                    ),
                    const Icon(Icons.bolt, color: Color(0xFF9C27B0), size: 26),
                  ],
                ),
              ),
              // card
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: GestureDetector(
                    onHorizontalDragUpdate: (d) => setState(() => drag += d.delta.dx),
                    onHorizontalDragEnd: (_) {
                      if (drag > 90) _swipe(true);
                      if (drag < -90) _swipe(false);
                      setState(() => drag = 0);
                    },
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DetailScreen(card: card))),
                    child: Transform.rotate(
                      angle: drag * 0.0008,
                      child: Transform.translate(
                        offset: Offset(drag * 0.5, 0),
                        child: Stack(
                          children: [
                            // card container
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(24),
                                image: DecorationImage(image: NetworkImage(card.image), fit: BoxFit.cover),
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(24),
                                  gradient: const LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [Colors.transparent, Colors.black54],
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // dots indicator
                                      Row(
                                        children: List.generate(6, (i) => Expanded(
                                          child: Container(
                                              height: 3,
                                              margin: EdgeInsets.only(right: i==5?0:4),
                                              decoration: BoxDecoration(
                                                  color: i==0?Colors.white:Colors.white38,
                                                  borderRadius: BorderRadius.circular(2))),
                                        )),
                                      ),
                                      const Spacer(),
                                      Row(
                                        children: [
                                          Text('${card.name} ${card.age}',
                                              style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800)),
                                          const SizedBox(width: 6),
                                          const Icon(Icons.verified, color: Colors.blueAccent, size: 20),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(8)),
                                        child: Text(card.bio, style: const TextStyle(color: Colors.white, fontSize: 12)),
                                      ),
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 6,
                                        runSpacing: 6,
                                        children: card.tags
                                            .map((t) => Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                  decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white24)),
                                                  child: Text(t, style: const TextStyle(color: Colors.white, fontSize: 11)),
                                                ))
                                            .toList(),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            // swipe labels
                            if (drag > 40)
                              Positioned(
                                top: 24,
                                left: 16,
                                child: Transform.rotate(
                                  angle: -0.2,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(border: Border.all(color: Colors.greenAccent, width: 3), borderRadius: BorderRadius.circular(8)),
                                    child: const Text('LIKE', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.w900, fontSize: 22)),
                                  ),
                                ),
                              ),
                            if (drag < -40)
                              Positioned(
                                top: 24,
                                right: 16,
                                child: Transform.rotate(
                                  angle: 0.2,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(border: Border.all(color: _tinderPink, width: 3), borderRadius: BorderRadius.circular(8)),
                                    child: const Text('NOPE', style: TextStyle(color: _tinderPink, fontWeight: FontWeight.w900, fontSize: 22)),
                                  ),
                                ),
                              ),
                            Positioned(
                              right: 12,
                              bottom: 90,
                              child: GestureDetector(
                                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DetailScreen(card: card))),
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(color: Colors.black54, shape: BoxShape.circle, border: Border.all(color: Colors.white)),
                                  child: const Icon(Icons.arrow_upward, color: Colors.white, size: 20),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // action buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _roundBtn(Icons.replay, Colors.grey, 22, () => setState(() => top = (top - 1) % cards.length)),
                    _roundBtn(Icons.close, _tinderPink, 30, () => _swipe(false), big: true),
                    _roundBtn(Icons.star, Colors.blueAccent, 26, () => _swipe(true)),
                    _roundBtn(Icons.favorite, const Color(0xFF7ED321), 28, () => _swipe(true), big: true),
                    _roundBtn(Icons.send, Colors.blue, 22, () {}),
                  ],
                ),
              ),
              const SizedBox(height: 80),
            ],
          ),
          if (showMatch) const MatchOverlay(),
        ],
      ),
    );
  }

  Widget _chip(String t, bool sel) => Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(color: sel ? Colors.white : Colors.white10, borderRadius: BorderRadius.circular(20)),
        child: Text(t, style: TextStyle(color: sel ? Colors.black : Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
      );

  Widget _roundBtn(IconData i, Color c, double s, VoidCallback onTap, {bool big = false}) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: big ? 64 : 52,
          height: big ? 64 : 52,
          decoration: BoxDecoration(
            color: Colors.black,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white12),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 8)],
          ),
          child: Icon(i, color: c, size: s),
        ),
      );
}

class _CardData {
  final String name;
  final int age;
  final String image;
  final List<String> tags;
  final String bio;
  _CardData({required this.name, required this.age, required this.image, required this.tags, required this.bio});
}

// ---------- DETAIL ----------
class DetailScreen extends StatelessWidget {
  final _CardData card;
  const DetailScreen({super.key, required this.card});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 420,
            pinned: true,
            leading: IconButton(icon: const Icon(Icons.keyboard_arrow_down, size: 32), onPressed: () => Navigator.pop(context)),
            flexibleSpace: FlexibleSpaceBar(
              background: Image.network(card.image, fit: BoxFit.cover),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text('${card.name}, ${card.age}', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
                    const SizedBox(width: 8),
                    const Icon(Icons.verified, color: Colors.blue),
                  ]),
                  const SizedBox(height: 8),
                  const Text('Looking for  New friends', style: TextStyle(color: Colors.black54)),
                  const SizedBox(height: 16),
                  const Text('About me', style: TextStyle(fontWeight: FontWeight.w700)),
                  const Text('Looking for interesting people to chat and hang out with. Love dogs and good coffee.'),
                  const SizedBox(height: 16),
                  Wrap(spacing: 8, runSpacing: 8, children: card.tags.map((t) => Chip(label: Text(t))).toList()),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: _tinderPink, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28))),
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Liked!'))); 
                      },
                      child: const Text('Like', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MatchOverlay extends StatelessWidget {
  const MatchOverlay({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      color: _tinderPink.withOpacity(0.95),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('It\'s a Match!', style: TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic)),
            const SizedBox(height: 8),
            const Text('You and Jasmine liked each other', style: TextStyle(color: Colors.white, fontSize: 16)),
            const SizedBox(height: 24),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              _avatar('https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=200'),
              const SizedBox(width: 16),
              _avatar('https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200'),
            ]),
            const SizedBox(height: 32),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)), padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14)),
              onPressed: () {},
              child: const Text('Send a Message', style: TextStyle(color: _tinderPink, fontWeight: FontWeight.w700)),
            ),
            TextButton(onPressed: () {}, child: const Text('Keep Swiping', style: TextStyle(color: Colors.white))),
          ],
        ),
      ),
    );
  }

  Widget _avatar(String url) => CircleAvatar(radius: 48, backgroundImage: NetworkImage(url));
}

// ---------- EXPLORE ----------
class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final cats = ['For You', 'Astrology', 'Double Date', 'Music', 'Festival Mode', 'Verified', 'College', 'Gamer'];
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Explore', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 1.2, crossAxisSpacing: 12, mainAxisSpacing: 12),
              itemCount: cats.length,
              itemBuilder: (_, i) => Container(
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), gradient: LinearGradient(colors: [Colors.pink.shade400, Colors.orange.shade400])),
                child: Center(child: Text(cats[i], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16))),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

// ---------- LIKES ----------
class LikesScreen extends StatelessWidget {
  const LikesScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: const Color(0xFFFFF3E0), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.orange.shade200)),
            child: const Row(children: [Icon(Icons.star, color: Colors.orange), SizedBox(width: 8), Text('48 Likes  •  See who likes you', style: TextStyle(fontWeight: FontWeight.w700))]),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.75, crossAxisSpacing: 12, mainAxisSpacing: 12),
              itemCount: 6,
              itemBuilder: (_, i) => ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(children: [
                  Image.network('https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=400', fit: BoxFit.cover, width: double.infinity, height: double.infinity),
                  Container(color: Colors.white.withOpacity(0.6)),
                  const Center(child: Icon(Icons.lock, size: 32)),
                  Positioned(bottom: 8, left: 8, child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12)), child: const Text('Blurred', style: TextStyle(color: Colors.white, fontSize: 11)))),
                ]),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

// ---------- CHAT ----------
class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Chat', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          SizedBox(
            height: 80,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 5,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) => Column(children: [
                CircleAvatar(radius: 28, backgroundImage: NetworkImage('https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=200')),
                const SizedBox(height: 4),
                Text(['Jasmine', 'Yunieee', 'Anya', 'Sofia', 'Mia'][i], style: const TextStyle(fontSize: 11)),
              ]),
            ),
          ),
          const Divider(),
          const Text('Messages', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              children: [
                _msgTile('Jasmine', 'Hey! How are you?', '2m', true),
                _msgTile('Yunieee', 'You matched! Say hi', '1h', false),
                _msgTile('Anya', 'Sticker', '3h', false),
                ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: const Text('Sofia'),
                  subtitle: const Text('Looking for new friends'),
                  trailing: const Icon(Icons.more_horiz),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatDetail())),
                ),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  Widget _msgTile(String name, String last, String time, bool unread) => ListTile(
        leading: CircleAvatar(backgroundImage: NetworkImage('https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=200')),
        title: Text(name, style: TextStyle(fontWeight: unread ? FontWeight.w800 : FontWeight.w500)),
        subtitle: Text(last, style: const TextStyle(fontSize: 13)),
        trailing: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(time, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          if (unread) Container(width: 8, height: 8, margin: const EdgeInsets.only(top: 4), decoration: const BoxDecoration(color: _tinderPink, shape: BoxShape.circle)),
        ]),
      );
}

class ChatDetail extends StatelessWidget {
  const ChatDetail({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(children: [CircleAvatar(backgroundImage: NetworkImage('https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=200')), SizedBox(width: 8), Text('Jasmine 27')]),
        actions: [IconButton(icon: const Icon(Icons.videocam_outlined), onPressed: () {}), IconButton(icon: const Icon(Icons.shield_outlined), onPressed: () {})],
      ),
      body: Column(children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Center(child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)), child: const Text('You matched with Jasmine on 03/08'))),
              const SizedBox(height: 16),
              Align(alignment: Alignment.centerLeft, child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(16)), child: const Text('Hey!'))),
              const SizedBox(height: 8),
              Align(alignment: Alignment.centerRight, child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: _tinderPink, borderRadius: BorderRadius.circular(16)), child: const Text('Hi Jasmine!', style: TextStyle(color: Colors.white)))),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            Expanded(child: TextField(decoration: InputDecoration(hintText: 'Type a message', border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)), contentPadding: const EdgeInsets.symmetric(horizontal: 16)))),
            const SizedBox(width: 8),
            CircleAvatar(backgroundColor: _tinderPink, child: IconButton(icon: const Icon(Icons.send, color: Colors.white, size: 18), onPressed: () {})),
          ]),
        ),
      ]),
    );
  }
}

// ---------- PROFILE ----------
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Stack(children: [
            ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.network('https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=600', height: 360, width: double.infinity, fit: BoxFit.cover)),
            Positioned(bottom: 12, left: 12, child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)), child: const Text('Santiago, 24', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)))),
          ]),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: ElevatedButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InterestsScreen())), icon: const Icon(Icons.edit, color: Colors.white), label: const Text('Edit Profile', style: TextStyle(color: Colors.white)), style: ElevatedButton.styleFrom(backgroundColor: _tinderDark, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))))),
            const SizedBox(width: 12),
            Expanded(child: OutlinedButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())), icon: const Icon(Icons.settings), label: const Text('Settings'))),
          ]),
          const SizedBox(height: 16),
          _profileCard('Basics', ['Engineer', 'Bogota', 'Hybrid']),
          _profileCard('Work mode', ['Remote', 'EU timezone']),
          const SizedBox(height: 80),
        ]),
      ),
    );
  }

  Widget _profileCard(String title, List<String> chips) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, children: chips.map((c) => Chip(label: Text(c, style: const TextStyle(fontSize: 12)))).toList()),
        ]),
      );
}

class InterestsScreen extends StatefulWidget {
  const InterestsScreen({super.key});
  @override
  State<InterestsScreen> createState() => _InterestsScreenState();
}

class _InterestsScreenState extends State<InterestsScreen> {
  final all = ['Freelancing', 'Photography', 'Singing', 'Writing', 'Travel', 'Music', 'Gaming', 'Cooking', 'Sport', 'Art', 'Tech', 'Design', 'Investing', 'Entrepreneurship', 'Choir', 'Cosplay', 'Sneakers', 'Batik', 'Entrepreneurship'];
  final sel = <String>{};
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)), title: const Text('Interests'), actions: [IconButton(icon: const Icon(Icons.check, color: Colors.white), onPressed: () => Navigator.pop(context), style: IconButton.styleFrom(backgroundColor: _tinderDark))]),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Interests', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)), Text('${sel.length} of 10', style: const TextStyle(color: Colors.grey))]),
          const SizedBox(height: 12),
          TextField(decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: 'Search', border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)), filled: true, fillColor: Colors.grey.shade100)),
          const SizedBox(height: 12),
          Expanded(child: SingleChildScrollView(child: Wrap(spacing: 8, runSpacing: 8, children: all.map((e) => ChoiceChip(label: Text(e), selected: sel.contains(e), onSelected: (v) => setState(() { if (v) sel.add(e); else sel.remove(e); }), selectedColor: _tinderPink, labelStyle: TextStyle(color: sel.contains(e) ? Colors.white : Colors.black54))).toList()))),
        ]),
      ),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(children: const [
        ListTile(leading: Icon(Icons.shield), title: Text('Safety & Privacy'), trailing: Icon(Icons.chevron_right)),
        ListTile(leading: Icon(Icons.notifications), title: Text('Notifications'), trailing: Icon(Icons.chevron_right)),
        ListTile(leading: Icon(Icons.language), title: Text('Language'), trailing: Icon(Icons.chevron_right)),
        Divider(),
        ListTile(leading: Icon(Icons.logout, color: Colors.red), title: Text('Log out', style: TextStyle(color: Colors.red))),
        ListTile(leading: Icon(Icons.delete, color: Colors.red), title: Text('Delete account', style: TextStyle(color: Colors.red))),
      ]),
    );
  }
}
