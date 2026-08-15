import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../../../../../core/services/ad_service.dart';
import '../exams/exams_page.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/services/local_storage_service.dart';
import '../../../../../core/services/notification_service.dart';
import 'cubit/more_cubit.dart';
import 'cubit/more_state.dart';

class MorePage extends StatelessWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => MoreCubit(
        storage: GetIt.I<LocalStorageService>(),
        notifications: GetIt.I<NotificationService>(),
      ),
      child: const MoreView(),
    );
  }
}

class MoreView extends StatelessWidget {
  const MoreView({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<MoreCubit>();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("المزيد"),
        elevation: 0,
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildProfileHeader(),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    _buildItem(
                      icon: Icons.edit_note_rounded,
                      title: "الاختبارات",
                      subtitle: "نماذج اختبارات لجميع المواد",
                      onTap: () {
                        GetIt.I<AdService>().showInterstitialAd(
                          onAdDismissed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const ExamsPage()));
                          },
                        );
                      },
                    ),
                    BlocBuilder<MoreCubit, MoreState>(
                      builder: (context, state) {
                        return _buildItem(
                          icon: state.notificationsEnabled 
                            ? Icons.notifications_active_outlined 
                            : Icons.notifications_off_outlined,
                          title: "الاشعارات",
                          subtitle: state.notificationsEnabled ? "مفعلة" : "معطلة",
                          trailing: Switch(
                            value: state.notificationsEnabled,
                            activeThumbColor: AppTheme.primaryGreen,
                            onChanged: (value) {
                              GetIt.I<AdService>().showInterstitialAd(
                                onAdDismissed: () => cubit.toggleNotifications(value),
                              );
                            },
                          ),
                          onTap: () {
                            GetIt.I<AdService>().showInterstitialAd(
                              onAdDismissed: () => cubit.toggleNotifications(!state.notificationsEnabled),
                            );
                          },
                        );
                      },
                    ),
                    _buildItem(
                      icon: Icons.share_rounded,
                      title: "مشاركة التطبيق",
                      subtitle: "شارك الفائدة مع زملائك",
                      onTap: () {
                        GetIt.I<AdService>().showInterstitialAd(
                          onAdDismissed: () => cubit.shareApp(),
                        );
                      },
                    ),
                    _buildItem(
                      icon: Icons.contact_support_rounded,
                      title: "اتصل بنا",
                      subtitle: "الدعم الفني والاستفسارات",
                      onTap: () {
                        GetIt.I<AdService>().showInterstitialAd(
                          onAdDismissed: () => cubit.launchEmail(),
                        );
                      },
                    ),
                    _buildItem(
                      icon: Icons.star_rounded,
                      title: "قيمنا",
                      subtitle: "رأيك يهمنا لتطوير التطبيق",
                      onTap: () {
                        GetIt.I<AdService>().showInterstitialAd(
                          onAdDismissed: () => cubit.launchStore(),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildRemoveAdsItem(),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              const Text(
                "الإصدار 1.0.0",
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Stack(
      alignment: .topCenter,
      children: [
        Container(
          height: 120,
          decoration: const BoxDecoration(
            color: AppTheme.primaryGreen,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(40),
              bottomRight: Radius.circular(40),
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.only(top: 20, left: 24, right: 24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha:0.05),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.primaryGreen.withValues(alpha:0.1), width: 4),
                ),
                child: CircleAvatar(
                  radius: 45,
                  backgroundColor: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Image.asset('assets/newLogo.jpeg'),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "تطبيق منهجي السعودي",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryGreen,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRemoveAdsItem() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withValues(alpha:0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // Future: Implement In-App Purchase logic
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: Colors.white24,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.block_flipped, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "إزالة الإعلانات",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "استمتع بتجربة بدون إعلانات مقابل \$3 فقط",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha:0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withValues(alpha:0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: AppTheme.primaryGreen, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                trailing ?? const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
