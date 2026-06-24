import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../domain/entities/card_entity.dart';

class CardWidget extends StatelessWidget {
  final CardEntity card;
  final VoidCallback onFreezeToggle;
  final VoidCallback onDelete;

  const CardWidget({
    super.key,
    required this.card,
    required this.onFreezeToggle,
    required this.onDelete,
  });

  void _showCardDetails(BuildContext context) {
    final fullNumber = card.cardNumber.isNotEmpty ? card.cardNumber : '????';
    final formattedNumber = fullNumber.replaceAllMapped(RegExp(r".{4}"), (match) => "${match.group(0)} ").trim();
    final last4 = card.cardNumber.length >= 4 ? card.cardNumber.substring(card.cardNumber.length - 4) : '????';
    final holder = card.cardHolderName.isNotEmpty ? card.cardHolderName : '—';
    final expiry = card.expiryDate.isNotEmpty ? card.expiryDate : '—';
    final cvv = card.cvv.isNotEmpty ? card.cvv : '***';
    final cardType = card.cardType.isNotEmpty ? card.cardType : '—';
    final statusLabel = card.isFrozen ? 'Frozen' : 'Active';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CardDetailsSheet(
        fullNumber: formattedNumber,
        last4: last4,
        holder: holder,
        expiry: expiry,
        cvv: cvv,
        cardType: cardType,
        statusLabel: statusLabel,
        isVirtual: card.isVirtual,
        isFrozen: card.isFrozen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fullNumber = card.cardNumber.isNotEmpty ? card.cardNumber : '????';
    final String formattedNumber = fullNumber.replaceAllMapped(RegExp(r".{4}"), (match) => "${match.group(0)} ").trim();
    final holder = card.cardHolderName.isNotEmpty ? card.cardHolderName : '—';
    final expiry = card.expiryDate.isNotEmpty ? card.expiryDate : '—';

    final List<Color> gradientColors = card.isFrozen
        ? [Colors.grey.shade400, Colors.grey.shade600]
        : (card.cardType.toLowerCase() == 'credit'
            ? [const Color(0xFF1E3C72), const Color(0xFF2A5298)]
            : [const Color(0xFF009FFF), const Color(0xFFec2F4B)]);

    return GestureDetector(
      onTap: () => _showCardDetails(context),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20.0),
          boxShadow: [
            BoxShadow(
              color: gradientColors.last.withValues(alpha: 0.45),
              blurRadius: 16.0,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(22.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: card label + chip icon
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        card.isVirtual
                            ? 'Virtual ${card.cardType} Card'
                            : '${card.cardType} Card',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15.0,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      if (card.isFrozen)
                        const Text(
                          'FROZEN',
                          style: TextStyle(
                            color: Colors.lightBlueAccent,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                    ],
                  ),
                  Icon(
                    card.isFrozen ? Icons.ac_unit : Icons.credit_card,
                    color: Colors.white.withValues(alpha: 0.85),
                    size: 28,
                  ),
                ],
              ),
              const SizedBox(height: 28.0),

              // Card number row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    formattedNumber,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20.0,
                      letterSpacing: 3.0,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  // Tap hint
                  Row(
                    children: [
                      Icon(Icons.touch_app,
                          color: Colors.white.withValues(alpha: 0.6), size: 14),
                      const SizedBox(width: 4),
                      Text(
                        'Details',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24.0),

              // Bottom row: holder + expiry + actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _infoColumn('Card Holder', holder),
                  _infoColumn('Expires', expiry),
                  // Actions
                  Row(
                    children: [
                      _actionButton(
                        icon: card.isFrozen ? Icons.play_arrow : Icons.pause,
                        label: card.isFrozen ? 'Unfreeze' : 'Freeze',
                        onTap: onFreezeToggle,
                      ),
                      const SizedBox(width: 6),
                      _actionButton(
                        icon: Icons.delete_outline,
                        label: 'Delete',
                        onTap: onDelete,
                        isDestructive: true,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 11.0,
          ),
        ),
        const SizedBox(height: 4.0),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14.0,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon,
              color: isDestructive ? Colors.redAccent : Colors.white, size: 20),
          Text(
            label,
            style: TextStyle(
              color: isDestructive ? Colors.redAccent : Colors.white,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Details bottom sheet ───────────────────────────────────────────────────────

class _CardDetailsSheet extends StatelessWidget {
  final String fullNumber;
  final String last4;
  final String holder;
  final String expiry;
  final String cvv;
  final String cardType;
  final String statusLabel;
  final bool isVirtual;
  final bool isFrozen;

  const _CardDetailsSheet({
    required this.fullNumber,
    required this.last4,
    required this.holder,
    required this.expiry,
    required this.cvv,
    required this.cardType,
    required this.statusLabel,
    required this.isVirtual,
    required this.isFrozen,
  });

  void _copy(BuildContext context, String value, String label) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.dividerColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              const Icon(Icons.credit_card, size: 22),
              const SizedBox(width: 10),
              Text(
                'Card Details',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'These are the full details for this card. '
            'Keep this information secure.',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: Colors.grey, height: 1.4),
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 8),

          _detailRow(context, 'Card Number', fullNumber, fullNumber.replaceAll(' ', '')),
          _detailRow(context, 'CVV', cvv, cvv),
          _detailRow(context, 'Card Holder', holder, holder),
          _detailRow(context, 'Expiry Date', expiry, expiry),
          _detailRow(context, 'Card Type', cardType, cardType),
          _detailRow(context, 'Type',
              isVirtual ? 'Virtual Card' : 'Physical Card',
              isVirtual ? 'Virtual' : 'Physical'),
          _detailRow(context, 'Status',
              isFrozen ? '❄ Frozen' : '✓ Active',
              statusLabel),

          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(
      BuildContext context, String label, String display, String copyValue) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: Colors.grey, fontSize: 11)),
                const SizedBox(height: 3),
                Text(display,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600, fontSize: 15)),
              ],
            ),
          ),
          if (copyValue != '—')
            IconButton(
              icon: const Icon(Icons.copy, size: 18),
              tooltip: 'Copy $label',
              onPressed: () => _copy(context, copyValue, label),
              color: theme.primaryColor,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }
}
