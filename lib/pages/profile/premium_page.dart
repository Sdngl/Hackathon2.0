import 'package:flutter/material.dart';

import '../theme/apptheme.dart';
import '../widgets/subscription_card.dart';

class PremiumPage extends StatefulWidget {
  final Future<void> Function(SubscriptionPlan plan) onSubscribe;

  const PremiumPage({
    super.key,
    required this.onSubscribe,
  });

  @override
  State<PremiumPage> createState() => _PremiumPageState();
}

class _PremiumPageState extends State<PremiumPage> {
  String _selectedId = 'half_year';
  bool _submitting = false;

  SubscriptionPlan get _selectedPlan =>
      kPlans.firstWhere((plan) => plan.id == _selectedId);

  Future<void> _continueWithEsewa() async {
    if (_submitting) return;

    setState(() => _submitting = true);

    try {
      await widget.onSubscribe(_selectedPlan);
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  String _planHeadline(SubscriptionPlan plan) {
    switch (plan.months) {
      case 1:
        return 'Flexible access';
      case 6:
        return 'Best balance for ongoing care';
      case 12:
        return 'Best value for long-term access';
      default:
        return 'Premium access';
    }
  }

  String _planDurationLabel(SubscriptionPlan plan) {
    if (plan.months == 1) return '1 Month Plan';
    return '${plan.months} Months Plan';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F7F6),
        surfaceTintColor: const Color(0xFFF5F7F6),
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'SEVA Premium',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: Color(0xFF17211E),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _PremiumHero(),

            const SizedBox(height: 26),

            const Text(
              'Choose Your Plan',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.2,
                color: Color(0xFF17211E),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Simple, transparent plans for your SEVA experience.',
              style: TextStyle(
                fontSize: 12.5,
                color: Color(0xFF7A8581),
              ),
            ),

            const SizedBox(height: 14),

            _LargePlanCard(
              selectedPlan: _selectedPlan,
              selectedId: _selectedId,
              submitting: _submitting,
              onSelect: (id) {
                setState(() => _selectedId = id);
              },
              onContinue: _continueWithEsewa,
              headline: _planHeadline(_selectedPlan),
              durationLabel: _planDurationLabel(_selectedPlan),
            ),

            const SizedBox(height: 28),

            const Text(
              'What You Unlock',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.2,
                color: Color(0xFF17211E),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'More access. More useful features. One connected experience.',
              style: TextStyle(
                fontSize: 12.5,
                color: Color(0xFF7A8581),
              ),
            ),

            const SizedBox(height: 12),

            const _UnlockCard(
              icon: Icons.medical_services_outlined,
              iconBackground: Color(0xFFE4F6F0),
              iconColor: Color(0xFF0C8A70),
              title: 'Premium Doctor Features',
              subtitle:
              'Access Premium doctor recommendation and consultation features.',
            ),
            const SizedBox(height: 10),
            const _UnlockCard(
              icon: Icons.insights_outlined,
              iconBackground: Color(0xFFEAF1FF),
              iconColor: Color(0xFF3978E8),
              title: 'Advanced Health Insights',
              subtitle:
              'Get more useful insights from your saved health information.',
            ),
            const SizedBox(height: 10),
            const _UnlockCard(
              icon: Icons.document_scanner_outlined,
              iconBackground: Color(0xFFF1EBFF),
              iconColor: Color(0xFF7A56E8),
              title: 'Premium Analysis Tools',
              subtitle:
              'Access additional Premium analysis features across SEVA.',
            ),
            const SizedBox(height: 10),
            const _UnlockCard(
              icon: Icons.auto_awesome_rounded,
              iconBackground: Color(0xFFFFF0DE),
              iconColor: Color(0xFFE47B13),
              title: 'More Premium Features',
              subtitle:
              'Get access to new Premium features as SEVA continues to grow.',
            ),

            const SizedBox(height: 18),

            const _SecurePaymentCard(),
          ],
        ),
      ),
    );
  }
}

class _PremiumHero extends StatelessWidget {
  const _PremiumHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 18, 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFF3FBF8),
            Color(0xFFE1F7EF),
          ],
        ),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF1C9),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: const Icon(
                        Icons.workspace_premium_rounded,
                        color: Color(0xFFE3A316),
                        size: 25,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: 'SEVA ',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF17211E),
                              ),
                            ),
                            TextSpan(
                              text: 'Premium',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF0C8A70),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Unlock more for a healthier you',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF23332F),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Get advanced insights, premium care features and more from SEVA.',
                  style: TextStyle(
                    fontSize: 12.3,
                    height: 1.45,
                    color: Color(0xFF5C6C67),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: const Color(0xFFCEF3E6),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0C8A70).withOpacity(0.09),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.workspace_premium_rounded,
              color: Color(0xFFE3A316),
              size: 48,
            ),
          ),
        ],
      ),
    );
  }
}

class _LargePlanCard extends StatelessWidget {
  final SubscriptionPlan selectedPlan;
  final String selectedId;
  final bool submitting;
  final ValueChanged<String> onSelect;
  final VoidCallback onContinue;
  final String headline;
  final String durationLabel;

  const _LargePlanCard({
    required this.selectedPlan,
    required this.selectedId,
    required this.submitting,
    required this.onSelect,
    required this.onContinue,
    required this.headline,
    required this.durationLabel,
  });

  @override
  Widget build(BuildContext context) {
    final isRecommended = selectedPlan.id == 'half_year';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isRecommended
            ? const Color(0xFFF7FCFA)
            : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isRecommended
              ? AppColors.primary
              : const Color(0xFFE2E9E6),
          width: isRecommended ? 1.4 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PlanSegmentedSelector(
            selectedId: selectedId,
            onSelect: onSelect,
          ),

          const SizedBox(height: 22),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFFE1F7EF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.calendar_month_outlined,
                  color: AppColors.primary,
                  size: 25,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      durationLabel,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF17211E),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      headline,
                      style: const TextStyle(
                        fontSize: 12.3,
                        color: Color(0xFF6B7773),
                      ),
                    ),
                  ],
                ),
              ),
              if (isRecommended)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE8B3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'MOST POPULAR',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFB66D00),
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 20),

          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Rs. ${formatRs(selectedPlan.price)}',
                style: const TextStyle(
                  fontSize: 31,
                  height: 1,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.7,
                  color: Color(0xFF17211E),
                ),
              ),
              if (selectedPlan.saveText != null) ...[
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDDF7EC),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    selectedPlan.saveText!,
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 5),

          Text(
            selectedPlan.months == 1
                ? 'Rs. ${formatRs(selectedPlan.price)} per month'
                : 'Rs. ${formatRs(selectedPlan.perMonth)} per month',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF7A8581),
            ),
          ),

          const SizedBox(height: 20),

          const _PlanFeature(text: 'Access to Premium SEVA features'),
          const SizedBox(height: 10),
          const _PlanFeature(text: 'Advanced health insights'),
          const SizedBox(height: 10),
          const _PlanFeature(text: 'Premium doctor features'),
          const SizedBox(height: 10),
          const _PlanFeature(text: 'Premium analysis tools'),

          const SizedBox(height: 22),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: submitting ? null : onContinue,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor:
                AppColors.primary.withOpacity(0.6),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: submitting
                  ? const SizedBox(
                width: 21,
                height: 21,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: Colors.white,
                ),
              )
                  : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 27,
                    height: 27,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Text(
                      'e',
                      style: TextStyle(
                        fontSize: 18,
                        height: 1,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 9),
                  const Text(
                    'Continue with eSewa',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    size: 19,
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

class _PlanSegmentedSelector extends StatelessWidget {
  final String selectedId;
  final ValueChanged<String> onSelect;

  const _PlanSegmentedSelector({
    required this.selectedId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F4),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          for (final plan in kPlans)
            Expanded(
              child: _PlanTab(
                label: plan.months == 1
                    ? '1 Month'
                    : '${plan.months} Months',
                selected: selectedId == plan.id,
                onTap: () => onSelect(plan.id),
              ),
            ),
        ],
      ),
    );
  }
}

class _PlanTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PlanTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 11,
        ),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary
              : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
          boxShadow: selected
              ? [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.18),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight:
            selected ? FontWeight.w800 : FontWeight.w700,
            color: selected
                ? Colors.white
                : const Color(0xFF31423D),
          ),
        ),
      ),
    );
  }
}

class _PlanFeature extends StatelessWidget {
  final String text;

  const _PlanFeature({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 19,
          height: 19,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_rounded,
            color: Colors.white,
            size: 13,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 12.5,
              color: Color(0xFF40504B),
            ),
          ),
        ),
      ],
    );
  }
}

class _UnlockCard extends StatelessWidget {
  final IconData icon;
  final Color iconBackground;
  final Color iconColor;
  final String title;
  final String subtitle;

  const _UnlockCard({
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE4EAE7),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 23,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF17211E),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11.3,
                    height: 1.4,
                    color: Color(0xFF6F7B77),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SecurePaymentCard extends StatelessWidget {
  const _SecurePaymentCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF4F7),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.verified_user_outlined,
            color: Color(0xFF3D7891),
            size: 22,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Secure payment through eSewa',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF214B5C),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Your selected plan is passed to your existing eSewa payment flow.',
                  style: TextStyle(
                    fontSize: 10.8,
                    height: 1.4,
                    color: Color(0xFF5F7882),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
