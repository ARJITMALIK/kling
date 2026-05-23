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
  int _tabIndex = 0; // 0 = Generate, 1 = Enter code

  @override
  void initState() {
    super.initState();
    _generateCode();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _generateCode() async {
    setState(() => _isLoading = true);
    final code = await ref.read(coupleProvider.notifier).generateInviteCode();
    setState(() {
      _myCode = code;
      _isLoading = false;
    });
  }

  Future<void> _joinCouple() async {
    if (_codeController.text.trim().length != 6) return;
    setState(() => _isJoining = true);
    final success = await ref.read(coupleProvider.notifier).joinCouple(
          _codeController.text.trim().toUpperCase(),
        );
    setState(() => _isJoining = false);
    if (success && mounted) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.pairSuccess);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.gradientBg),
        child: SafeArea(
          child: Padding(
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
                  'Share your code or enter theirs',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                ),
                const SizedBox(height: 32),

                // Tab selector
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _tabIndex = 0),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _tabIndex == 0
                                ? AppColors.accentPink.withValues(alpha: 0.2)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _tabIndex == 0
                                  ? AppColors.accentPink.withValues(alpha: 0.5)
                                  : Colors.white.withValues(alpha: 0.1),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              'Share My Code',
                              style: TextStyle(
                                color: _tabIndex == 0
                                    ? AppColors.accentPink
                                    : AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _tabIndex = 1),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _tabIndex == 1
                                ? AppColors.accentPurple.withValues(alpha: 0.2)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _tabIndex == 1
                                  ? AppColors.accentPurple.withValues(alpha: 0.5)
                                  : Colors.white.withValues(alpha: 0.1),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              'Enter Code',
                              style: TextStyle(
                                color: _tabIndex == 1
                                    ? AppColors.accentPurple
                                    : AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Tab content
                Expanded(
                  child: _tabIndex == 0 ? _buildShareCode() : _buildEnterCode(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShareCode() {
    return Column(
      children: [
        GlassCard(
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
        ),
        const SizedBox(height: 24),
        const Text(
          'Waiting for your partner to enter this code...',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.accentPink.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }

  Widget _buildEnterCode() {
    return Column(
      children: [
        GlassCard(
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
                ),
                onChanged: (_) => setState(() {}),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        GradientButton(
          text: 'Connect 💕',
          gradient: AppColors.gradientBlue,
          isLoading: _isJoining,
          onPressed: _codeController.text.trim().length == 6 ? _joinCouple : null,
        ),
      ],
    );
  }
}
