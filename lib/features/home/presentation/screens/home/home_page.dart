import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:mahj_saudi/features/home/presentation/widgets/semester_card.dart';
import 'package:mahj_saudi/features/home/data/repositories/educational_repository_impl.dart';
import 'package:mahj_saudi/core/theme/app_theme.dart';
import 'package:mahj_saudi/features/home/presentation/widgets/custom_bottom_nav.dart';
import 'package:mahj_saudi/core/services/ad_service.dart';
import 'cubit/home_cubit.dart';
import 'cubit/home_state.dart';
import '../content/content_page.dart';
import '../timer/timer_page.dart';
import '../favorites/favorites_page.dart';
import '../library/library_page.dart';
import '../more/more_page.dart';
import '../notifications/notifications_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 2; // Home is index 2
  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
  }

  void _loadBannerAd() {
    _bannerAd = GetIt.I<AdService>().createBannerAd()
      ..load().then((_) {
        if (mounted) {
          setState(() {
            _isBannerAdLoaded = true;
          });
        }
      });
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      const TimerPage(),
      const FavoritesPage(),
      const _HomeContent(), // Index 2
      const LibraryPage(),
      const MorePage(),
    ];

    return Scaffold(
      body: Column(
        children: [
          Expanded(child: pages[_currentIndex]),
          if (_isBannerAdLoaded && _bannerAd != null)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  width: _bannerAd!.size.width.toDouble(),
                  height: _bannerAd!.size.height.toDouble(),
                  child: AdWidget(ad: _bannerAd!),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}

class _HomeContent extends StatefulWidget {
  const _HomeContent();

  @override
  State<_HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<_HomeContent> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => HomeCubit(
        context.read<EducationalRepositoryImpl>(),
      )..loadRootSemesters(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text("منهجي السعودي"),
          actions: [
            Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.notifications_none), 
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsPage()));
                },
              ),
            ),
          ],
          leading: Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.share), 
              onPressed: () => context.read<HomeCubit>().shareApp(),
            ),
          ),
        ),
        body: Directionality(
          textDirection: TextDirection.rtl,
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildHeader(context),
                BlocBuilder<HomeCubit, HomeState>(
                  builder: (context, state) {
                    if (state is HomeLoading) {
                      return const Padding(
                        padding: EdgeInsets.all(50.0),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    if (state is HomeLoaded) {
                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        itemCount: state.items.length,
                        itemBuilder: (context, index) {
                          final item = state.items[index];
                          return SemesterCard(
                            title: item.title,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ContentPage(
                                          node: item,
                                          parentId: item.id,
                                          title: item.title,
                                        ),
                                      ),
                                    );
                                  },
                          );
                        },
                      );
                    }
                    if (state is HomeError) {
                      return Center(child: Text(state.message));
                    }
                    return const SizedBox();
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 20),
        Center(
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha:0.1), blurRadius: 10, offset: const Offset(0, 5)),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Image.asset(
                'assets/newLogo.jpeg',
                height: 80,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Text(
                  "Mnhaji",
                  style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(
                "مرحبًا بك! يرجى اختيار الفصل الدراسي الذي تريده لتتمكن من تصفح جميع المواد الخاصة بك",
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Align(
            alignment: Alignment.centerRight,
            child: Text(
              "الفصول الدراسية",
              style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 22),
            ),
          ),
        ),
      ],
    );
  }
}
