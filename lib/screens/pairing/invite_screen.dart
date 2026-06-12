import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/theme.dart';
import '../../config/routes.dart';
import '../../providers/couple_provider.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/gradient_button.dart';

class InviteScreen extends ConsumerStatefulWidget {
  const InviteScreen({super.key});

  @override
  ConsumerState<InviteScreen> createState() => _InviteScreenState();
}

class _InviteScreenState extends ConsumerState<InviteScreen> {
  final _codeController = TextEditingController();
  String? _myCode;
  bool _isLoading = false;
  bool _isJoining = false;

  @override
  void initState() {
    super.initState();
    _fetchState();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _fetchState() async {
    setState(() => _isLoading = true);
    try {
      final code = await ref.read(coupleProvider.notifier).generateInviteCode();
      await ref.read(coupleProvider.notifier).loadCoupleData();
      if (mounted) {
        setState(() {
          _myCode = code;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll(RegExp(r'ApiException\(\d+\): '), ''))),
        );
      }
    }
  }

  Future<void> _joinCouple() async {
    if (_codeController.text.trim().length != 6) return;
    setState(() => _isJoining = true);
    final success = await ref.read(coupleProvider.notifier).joinCouple(
          _codeController.text.trim().toUpperCase(),
        );
    if (mounted) {
      setState(() => _isJoining = false);
      if (success) {
        _codeController.clear();
        final coupleState = ref.read(coupleProvider);
        if (coupleState.partner?.pairingStatus == 'ACTIVE') {
          Navigator.of(context).pushReplacementNamed(AppRoutes.pairSuccess);
        }
      } else {
        final error = ref.read(coupleProvider).error ?? 'Failed to connect';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.replaceAll(RegExp(r'ApiException\(\d+\): '), ''))),
        );
      }
    }
  }

  Future<void> _cancelRequest() async {
    setState(() => _isJoining = true);
    final success = await ref.read(coupleProvider.notifier).cancelRequest();
    if (mounted) {
      setState(() => _isJoining = false);
      if (!success) {
        final error = ref.read(coupleProvider).error ?? 'Failed to cancel';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.replaceAll(RegExp(r'ApiException\(\d+\): '), ''))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final coupleState = ref.watch(coupleProvider);
    final partner = coupleState.partner;

    // Check if we became active due to a socket event
    if (partner?.pairingStatus == 'ACTIVE') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed(AppRoutes.pairSuccess);
        }
      });
    }

    final isPending = partner?.pairingStatus == 'PENDING';

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(gradient: AppColors.gradientBg),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 40),
                const Text('💑', style: TextStyle(fontSize: 56)),
                const SizedBox(height: 16),
                ShaderMask(
                  shaderCallback: (bounds) =>
                      AppColors.gradientLove.createShader(bounds),
                  child: const Text(
                    'Pair with your partner',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Both of you must enter each other\'s code',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                if (isPending) ...[
                  _buildPendingState(partner!.partnerInviteCode),
                ] else ...[
                  _buildShareCode(),
                  const SizedBox(height: 32),
                  _buildEnterCode(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShareCode() {
    return GlassCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Text(
            'Your invite code',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const CircularProgressIndicator(color: AppColors.accentPink)
          else
            GestureDetector(
              onTap: () {
                if (_myCode != null) {
                  Clipboard.setData(ClipboardData(text: _myCode!));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Code copied! 💕'),
                      backgroundColor: AppColors.accentPink,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.bgPrimary,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.accentPink.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _myCode ?? '------',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 8,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.copy_rounded,
                      color: AppColors.accentPink.withValues(alpha: 0.7),
                      size: 24,
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),
          const Text(
            'Tap to copy • Share with your partner',
            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildEnterCode() {
    return GlassCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Text(
            "Enter your partner's code",
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _codeController,
            textAlign: TextAlign.center,
            textCapitalization: TextCapitalization.characters,
            maxLength: 6,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: 8,
              color: Colors.white,
            ),
            decoration: InputDecoration(
              counterText: '',
              hintText: '______',
              hintStyle: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: 8,
                color: AppColors.textMuted.withValues(alpha: 0.3),
              ),
              border: InputBorder.none,
              focusedBorder: InputBorder.none,
              enabledBorder: InputBorder.none,
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 24),
          GradientButton(
            text: 'Connect 💕',
            gradient: AppColors.gradientBlue,
            isLoading: _isJoining,
            onPressed: _codeController.text.trim().length == 6 ? _joinCouple : null,
          ),
        ],
      ),
    );
  }

  Widget _buildPendingState(String? partnerCode) {
    return GlassCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(
            Icons.hourglass_empty_rounded,
            size: 48,
            color: AppColors.accentPink.withValues(alpha: 0.8),
          ),
          const SizedBox(height: 24),
          const Text(
            'Waiting for your partner...',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Your partner needs to enter your code to complete the pairing.',
            style: TextStyle(
              color: AppColors.textSecondary.withValues(alpha: 0.8),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.bgPrimary.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                const Text(
                  'Your Code:',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Text(
                  _myCode ?? '------',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 4,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          TextButton(
            onPressed: _isJoining ? null : _cancelRequest,
            child: _isJoining
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text(
                    'Cancel Request',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
