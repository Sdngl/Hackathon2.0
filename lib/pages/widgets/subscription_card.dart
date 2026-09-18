import 'package:flutter/material.dart';
import 'package:hackthon2/pages/widgets/widget.dart';
import '../theme/apptheme.dart';


class SubscriptionPlan {
  final String id;
  final String title;
  final int price; // total price in Rs.
  final int months;
  final String? saveText;

  const SubscriptionPlan({
    required this.id,
    required this.title,
    required this.price,
    required this.months,
    this.saveText,
  });

  int get perMonth => (price / months).round();
}

const kPlans = [
  SubscriptionPlan(id: 'monthly', title: 'Monthly', price: 149, months: 1),
  SubscriptionPlan(
      id: 'half_year', title: '6 Months', price: 799, months: 6, saveText: 'Save 11%'),
  SubscriptionPlan(
      id: 'yearly', title: 'Yearly', price: 1499, months: 12, saveText: 'Save 16%'),
];

/// Formats 1499 -> "1,499"
String formatRs(int value) {
  final s = value.toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return buf.toString();
}

class SubscriptionCard extends StatefulWidget {
  /// Plan that gets the "Recommended" badge and is selected by default.
  final String recommendedId;
  final void Function(SubscriptionPlan plan)? onSubscribe;

  const SubscriptionCard({
    super.key,
    this.recommendedId = 'half_year',
    this.onSubscribe,
  });

  @override
  State<SubscriptionCard> createState() => _SubscriptionCardState();
}

class _SubscriptionCardState extends State<SubscriptionCard> {
  late String _selectedId = widget.recommendedId;

  SubscriptionPlan get _selected =>
      kPlans.firstWhere((p) => p.id == _selectedId);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.accentLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.workspace_premium_outlined,
                    color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SEVA Premium',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Unlimited scans, AI insights and doctor suggestions',
                      style: TextStyle(
                          fontSize: 12.5, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22), // room for the badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < kPlans.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(
                  child: _PlanTile(
                    plan: kPlans[i],
                    selected: kPlans[i].id == _selectedId,
                    recommended: kPlans[i].id == widget.recommendedId,
                    onTap: () => setState(() => _selectedId = kPlans[i].id),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            text: 'Subscribe for Rs. ${formatRs(_selected.price)}',
            onPressed: () => widget.onSubscribe?.call(_selected),
          ),
          const SizedBox(height: 10),
          const Text(
            'Cancel anytime. Renews automatically.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

class _PlanTile extends StatelessWidget {
  final SubscriptionPlan plan;
  final bool selected;
  final bool recommended;
  final VoidCallback onTap;

  const _PlanTile({
    required this.plan,
    required this.selected,
    required this.recommended,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final perMonthText = plan.months == 1
        ? 'per month'
        : 'Rs. ${plan.perMonth}/mo';

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(8, 18, 8, 12),
            decoration: BoxDecoration(
              color: selected ? const Color(0xFFF1FAF7) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected ? AppColors.primary : AppColors.border,
                width: selected ? 1.6 : 1,
              ),
            ),
            child: Column(
              children: [
                Text(
                  plan.title,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: selected ? AppColors.primary : AppColors.label,
                  ),
                ),
                const SizedBox(height: 6),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'Rs. ${formatRs(plan.price)}',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  perMonthText,
                  style:
                  const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                ),
                const SizedBox(height: 8),
                // Keeps all tiles the same height even without a save tag
                SizedBox(
                  height: 20,
                  child: plan.saveText == null
                      ? null
                      : Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.accentLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      plan.saveText!,
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (recommended)
            Positioned(
              top: -11,
              child: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Recommended',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}