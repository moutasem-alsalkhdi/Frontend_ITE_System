import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';
import '../login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _user;
  double _balance = 0;
  List _transactions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final user = await ApiService.getUser();
      final balRes = await ApiService.getWalletBalance();
      final txRes = await ApiService.getWalletTransactions();
      setState(() {
        _user = user;
        _balance = (balRes['data']?['balance'] ?? 0).toDouble();
        _transactions = txRes['data'] ?? [];
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _logout() async {
    await ApiService.logout();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
            (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: _loading
            ? const LoadingWidget()
            : CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader()),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildInfoCard(),
                  const SizedBox(height: 16),
                  const SectionTitle(title: 'آخر المعاملات المالية'),
                  ..._transactions.take(5).map(_buildTxCard),
                  const SizedBox(height: 16),
                  _buildLogoutBtn(),
                ]),
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
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        bottom: 24,
        left: 16,
        right: 16,
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.teal.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.teal, width: 2),
            ),
            child: const Icon(Icons.person_rounded,
                color: AppColors.teal, size: 38),
          ),
          const SizedBox(height: 12),
          Text(
            _user?['name'] ?? '',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            _user?['university_id'] ?? '',
            style:
            const TextStyle(color: Colors.white54, fontSize: 13),
          ),
          const SizedBox(height: 12),
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.teal.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppColors.teal.withOpacity(0.3), width: 0.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.account_balance_wallet_outlined,
                    color: AppColors.teal, size: 18),
                const SizedBox(width: 8),
                Text(
                  '${_balance.toStringAsFixed(0)} ل.س',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    final items = [
      {'icon': Icons.badge_outlined, 'label': 'الرقم الجامعي', 'value': _user?['university_id'] ?? '—'},
      {'icon': Icons.format_list_numbered_rounded, 'label': 'الرقم الامتحاني', 'value': _user?['exam_number'] ?? '—'},
      {'icon': Icons.school_outlined, 'label': 'السنة الدراسية', 'value': 'السنة ${_user?['year_of_study'] ?? '—'}'},
      {'icon': Icons.group_outlined, 'label': 'رقم المجموعة', 'value': '${_user?['group_number'] ?? '—'}'},
    ];

    return AppCard(
      child: Column(
        children: items.map((item) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                Icon(item['icon'] as IconData,
                    color: AppColors.teal, size: 20),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item['label'] as String,
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textHint)),
                    Text(item['value'] as String,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary)),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTxCard(dynamic tx) {
    final isCredit = tx['type'] == 'credit';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isCredit ? AppColors.passBg : AppColors.failBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isCredit
                    ? Icons.arrow_downward_rounded
                    : Icons.arrow_upward_rounded,
                color:
                isCredit ? AppColors.passGreen : AppColors.failRed,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tx['description'] ?? (isCredit ? 'شحن رصيد' : 'دفع رسوم'),
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  Text(_formatDate(tx['created_at']),
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textHint)),
                ],
              ),
            ),
            Text(
              '${isCredit ? '+' : '-'}${tx['amount']} ل.س',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isCredit
                      ? AppColors.passGreen
                      : AppColors.failRed),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutBtn() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _logout,
        icon: const Icon(Icons.logout_rounded, color: AppColors.failRed),
        label: const Text('تسجيل الخروج',
            style: TextStyle(
                color: AppColors.failRed,
                fontFamily: 'Cairo',
                fontWeight: FontWeight.w600)),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          side: const BorderSide(color: AppColors.failRed, width: 0.5),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr).toLocal();
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return '';
    }
  }
}