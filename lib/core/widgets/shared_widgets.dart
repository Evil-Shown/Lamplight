import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../constants/app_constants.dart';
import 'ledger_widgets.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppText.serif(21)),
                if (subtitle != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    subtitle!,
                    style: AppText.sans(12.5, color: AppColors.textSecondary),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: AppSpacing.sm),
            Text(trailing!.toUpperCase(), style: AppText.mono(10.5, ls: 2)),
          ],
          if (actionLabel != null && onAction != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(0, 36),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(actionLabel!),
            ),
        ],
      ),
    );
  }
}

/// Ink-stamp chip — dashed border, tinted fill, archive-mono uppercase label.
class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.label,
    required this.color,
    this.icon,
    this.compact = false,
    this.pulse = false,
  });

  final String label;
  final Color color;
  final IconData? icon;
  final bool compact;
  final bool pulse;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      foregroundPainter: DashedRRectPainter(
        color: color.withValues(alpha: 0.5),
        radius: AppRadii.full,
        strokeWidth: 1.3,
      ),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 9 : 11,
          vertical: compact ? 4 : 5.5,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.09),
          borderRadius: BorderRadius.circular(AppRadii.full),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: compact ? 12 : 13, color: color),
              const SizedBox(width: 4),
            ] else ...[
              _Dot(color: color, pulse: pulse),
              const SizedBox(width: 5),
            ],
            Text(
              label.toUpperCase(),
              style: AppText.mono(
                compact ? 9.5 : 10.5,
                w: FontWeight.w700,
                ls: 1.8,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Dot extends StatefulWidget {
  const _Dot({required this.color, required this.pulse});

  final Color color;
  final bool pulse;

  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  AnimationController? _controller;

  @override
  void initState() {
    super.initState();
    if (widget.pulse) {
      _controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1100),
      )..repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dot = Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
    );
    if (_controller == null) return dot;
    return FadeTransition(
      opacity: Tween<double>(begin: 1, end: 0.28).animate(
        CurvedAnimation(parent: _controller!, curve: Curves.easeInOut),
      ),
      child: dot,
    );
  }
}

class InfoRow extends StatelessWidget {
  const InfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.goldSoft.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: AppColors.goldDeep),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label.toUpperCase(), style: AppText.mono(9.5, ls: 2)),
                const SizedBox(height: 3),
                Text(value, style: AppText.sans(14.5, w: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                color: AppColors.goldSoft.withValues(alpha: 0.5),
                shape: BoxShape.circle,
                boxShadow: AppShadows.soft,
              ),
              child: Icon(icon, size: 38, color: AppColors.goldDeep),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(title, style: AppText.serif(21), textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              style: AppText.sans(
                13.5,
                color: AppColors.textSecondary,
                height: 1.45,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.lg),
              OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

class FilterChipBar extends StatelessWidget {
  const FilterChipBar({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: options.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final option = options[index];
          final isSelected = option == selected;
          return GestureDetector(
            onTap: () => onSelected(option),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.ink : AppColors.paperCard,
                borderRadius: BorderRadius.circular(AppRadii.full),
                border: Border.all(
                  color: isSelected
                      ? AppColors.gold.withValues(alpha: 0.55)
                      : AppColors.line,
                  width: isSelected ? 1.4 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.gold.withValues(alpha: 0.18),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              child: Text(
                option,
                style: AppText.sans(
                  13,
                  w: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? AppColors.paper : AppColors.textSecondary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Book cover art. When [isbn] is provided the real cover is fetched from
/// the OpenLibrary covers API; the etched-initials plate renders while
/// loading and on failure so the footprint never changes.
class BookCover extends StatelessWidget {
  const BookCover({
    super.key,
    required this.title,
    this.color,
    this.isbn,
    this.width = 56,
    this.height = 78,
    this.radius = 10,
  });

  final String title;
  final int? color;
  final String? isbn;
  final double width;
  final double height;
  final double radius;

  Color get _base {
    if (color != null) return Color(color!);
    final idx = title.hashCode.abs() % AppColors.coverPalette.length;
    return AppColors.coverPalette[idx];
  }

  String get _initials {
    final words = title.trim().split(RegExp(r'\s+'));
    if (words.isEmpty) return 'B';
    if (words.length == 1) return words.first.substring(0, 1).toUpperCase();
    return (words[0][0] + words[1][0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final plate = _InitialsPlate(
      base: _base,
      initials: _initials,
      radius: radius,
    );

    Widget content;
    if (isbn == null || isbn!.isEmpty) {
      content = plate;
    } else {
      content = ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Image.network(
          'https://covers.openlibrary.org/b/isbn/$isbn-L.jpg',
          width: width,
          height: height,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          errorBuilder: (_, __, ___) => plate,
          loadingBuilder: (context, child, progress) =>
              progress == null ? child : plate,
        ),
      );
    }

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.28),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B2334).withValues(alpha: 0.28),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: content,
      ),
    );
  }
}

/// Etched initials plate — the fallback cover art.
class _InitialsPlate extends StatelessWidget {
  const _InitialsPlate({
    required this.base,
    required this.initials,
    required this.radius,
  });

  final Color base;
  final String initials;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: AppGradients.cover(base.toARGB32()),
      ),
      child: Stack(
        children: [
          // Gold spine rule
          Positioned(
            left: 7,
            top: 8,
            bottom: 8,
            child: Container(
              width: 1.4,
              color: AppColors.gold.withValues(alpha: 0.55),
            ),
          ),
          Center(
            child: Text(
              initials,
              style: AppText.serif(
                17,
                w: FontWeight.w700,
                color: Colors.white.withValues(alpha: 0.94),
                ls: 1,
              ),
            ),
          ),
          Positioned(
            left: 14,
            right: 9,
            bottom: 9,
            child: Container(
              height: 1.6,
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Pressable paper card with subtle scale feedback.
class SoftCard extends StatelessWidget {
  const SoftCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.color,
    this.margin,
    this.elevated = false,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? color;
  final EdgeInsetsGeometry? margin;
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadii.lg);
    final content = Padding(
      padding: padding ?? const EdgeInsets.all(AppSpacing.md),
      child: child,
    );

    Widget card = Container(
      margin: margin,
      decoration: BoxDecoration(
        color: color ?? AppColors.paperCard,
        borderRadius: radius,
        border: Border.all(color: AppColors.line),
        boxShadow: elevated ? AppShadows.soft : null,
      ),
      child: Material(
        type: MaterialType.transparency,
        clipBehavior: Clip.antiAlias,
        borderRadius: radius,
        child: content,
      ),
    );

    if (onTap != null) {
      card = _PressScale(onTap: onTap!, child: card);
    }
    return card;
  }
}

class _PressScale extends StatefulWidget {
  const _PressScale({required this.onTap, required this.child});

  final VoidCallback onTap;
  final Widget child;

  @override
  State<_PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<_PressScale> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.975 : 1,
        duration: const Duration(milliseconds: 130),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}

class AlertBanner extends StatelessWidget {
  const AlertBanner({
    super.key,
    required this.message,
    this.icon = Icons.info_outline,
    this.tone = AlertTone.info,
    this.margin,
  });

  final String message;
  final IconData icon;
  final AlertTone tone;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (tone) {
      AlertTone.info => (AppColors.inkSoft.withValues(alpha: 0.07), AppColors.inkSoft),
      AlertTone.success => (AppColors.stampGreen.withValues(alpha: 0.09), AppColors.stampGreen),
      AlertTone.warning => (AppColors.stampGold.withValues(alpha: 0.10), AppColors.stampGold),
      AlertTone.danger => (AppColors.stampRed.withValues(alpha: 0.08), AppColors.stampRed),
    };

    return Container(
      margin: margin,
      child: CustomPaint(
        foregroundPainter: DashedRRectPainter(
          color: fg.withValues(alpha: 0.45),
          radius: AppRadii.md,
        ),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Icon(icon, color: fg, size: 21),
              const SizedBox(width: AppSpacing.sm + 4),
              Expanded(
                child: Text(
                  message,
                  style: AppText.sans(13, w: FontWeight.w600, color: fg, height: 1.35),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum AlertTone { info, success, warning, danger }

class SummaryRow extends StatelessWidget {
  const SummaryRow({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(label.toUpperCase(), style: AppText.mono(10, ls: 2)),
          ),
          const SizedBox(width: AppSpacing.md),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: AppText.sans(14, w: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

/// Gold-foil success emblem with serif headline — confirmation screens.
class SuccessHero extends StatelessWidget {
  const SuccessHero({super.key, required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.6, end: 1),
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutBack,
          builder: (context, scale, child) =>
              Transform.scale(scale: scale, child: child),
          child: SizedBox(
            width: 116,
            height: 116,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 116,
                  height: 116,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.gold.withValues(alpha: 0.12),
                  ),
                ),
                Container(
                  width: 92,
                  height: 92,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppGradients.foil,
                    boxShadow: AppShadows.glow,
                  ),
                  child: const Icon(Icons.check_rounded,
                      size: 42, color: AppColors.inkDeep),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(title, style: AppText.serif(26), textAlign: TextAlign.center),
        const SizedBox(height: AppSpacing.sm),
        Text(
          subtitle,
          style: AppText.sans(14, w: FontWeight.w500, color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class IconBadge extends StatelessWidget {
  const IconBadge({
    super.key,
    required this.icon,
    this.color = AppColors.goldDeep,
    this.size = 44,
  });

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: color, size: size * 0.46),
    );
  }
}

class BottomActionBar extends StatelessWidget {
  const BottomActionBar({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.paperCard,
        border: const Border(top: BorderSide(color: AppColors.line)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B2334).withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.sm,
          ),
          child: child,
        ),
      ),
    );
  }
}

String seatStatusLabel(String raw) {
  if (raw.isEmpty) return raw;
  return raw[0].toUpperCase() + raw.substring(1);
}
