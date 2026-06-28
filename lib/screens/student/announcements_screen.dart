import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';

class AnnouncementsScreen extends StatefulWidget {
  const AnnouncementsScreen({super.key});

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List _announcements = [];
  List _notifications = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final aRes = await ApiService.getAnnouncements();
      final nRes = await ApiService.getNotifications();
      setState(() {
        _announcements = aRes['data'] ?? [];
        _notifications = nRes['data'] ?? [];
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _loading
                  ? const LoadingWidget()
                  : TabBarView(
                controller: _tabController,
                children: [
                  _buildAnnouncementsList(),
                  _buildNotificationsList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: AppColors.navy,
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 12,
              bottom: 4,
              left: 16,
              right: 16,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('الإعلانات والإشعارات',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700)),
                IconButton(
                  onPressed: () async {
                    await ApiService.markAllRead();
                    _load();
                  },
                  icon: const Icon(Icons.done_all_rounded,
                      color: AppColors.teal, size: 22),
                  tooltip: 'تعيين الكل مقروء',
                ),
              ],
            ),
          ),
          TabBar(
            controller: _tabController,
            indicatorColor: AppColors.teal,
            indicatorWeight: 3,
            labelColor: AppColors.teal,
            unselectedLabelColor: Colors.white54,
            labelStyle: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 13,
                fontWeight: FontWeight.w600),
            tabs: const [
              Tab(text: 'الإعلانات'),
              Tab(text: 'الإشعارات'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnnouncementsList() {
    if (_announcements.isEmpty) {
      return const ErrorWidget2(message: 'لا توجد إعلانات حالياً');
    }
    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.teal,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount: _announcements.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _buildAnnouncementCard(_announcements[i]),
      ),
    );
  }

  Widget _buildAnnouncementCard(Map a) {
    final isAdmin = a['sender_role'] == 'admin';
    final accentColor = isAdmin ? AppColors.amber : AppColors.teal;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border(right: BorderSide(color: accentColor, width: 3)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(a['title'] ?? '',
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
          if (a['content'] != null) ...[
            const SizedBox(height: 6),
            Text(a['content'],
                style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.6)),
          ],
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(a['sender_name'] ?? '',
                  style: TextStyle(
                      fontSize: 11,
                      color: accentColor,
                      fontWeight: FontWeight.w600)),
              Text(
                _formatDate(a['created_at']),
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textHint),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList() {
    if (_notifications.isEmpty) {
      return const ErrorWidget2(message: 'لا توجد إشعارات');
    }
    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.teal,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount: _notifications.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) => _buildNotifCard(_notifications[i]),
      ),
    );
  }

  Widget _buildNotifCard(Map n) {
    final isRead = n['read_at'] != null;
    final data = n['data'] ?? {};

    return Dismissible(
      key: Key(n['id']),
      direction: DismissDirection.startToEnd,
      background: Container(
        decoration: BoxDecoration(
          color: AppColors.failRed,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) async {
        await ApiService.deleteNotification(n['id']);
        _load();
      },
      child: GestureDetector(
        onTap: () async {
          if (!isRead) {
            await ApiService.markNotificationRead(n['id']);
            _load();
          }
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isRead ? Colors.white : const Color(0xFFF0FDFB),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isRead ? AppColors.border : AppColors.teal.withOpacity(0.3),
              width: 0.5,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 5, left: 10),
                decoration: BoxDecoration(
                  color: isRead ? Colors.transparent : AppColors.teal,
                  shape: BoxShape.circle,
                  border: isRead
                      ? Border.all(color: AppColors.border)
                      : null,
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data['title'] ?? '',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: isRead
                                ? FontWeight.w500
                                : FontWeight.w700,
                            color: isRead
                                ? AppColors.textSecondary
                                : AppColors.textPrimary)),
                    if (data['message'] != null) ...[
                      const SizedBox(height: 4),
                      Text(data['message'],
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              height: 1.5)),
                    ],
                    const SizedBox(height: 4),
                    Text(_formatDate(n['created_at']),
                        style: const TextStyle(
                            fontSize: 10, color: AppColors.textHint)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr).toLocal();
      final now = DateTime.now();
      final diff = now.difference(date);
      if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} دقيقة';
      if (diff.inHours < 24) return 'منذ ${diff.inHours} ساعة';
      if (diff.inDays == 1) return 'أمس';
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return '';
    }
  }
}