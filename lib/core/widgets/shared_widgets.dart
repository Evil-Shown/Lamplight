import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

/// Shared building blocks for the campus-blue prototype.
///
/// Everything here is deliberately flat and light: white cards on an
/// off-white page, a single blue for action, and semantic colour reserved
/// for status. The motion widgets ([CountUp], [StaggeredEntrance],
/// [PressScale]) are carried over from the previous design pass.

/// The standard screen chrome: a centred title, a back chevron, and a
/// bottom action slot. Matches the prototype's app bars.
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.bottomBar,
    this.showBack = true,
    this.onBack,
  });

  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? bottomBar;
  final bool showBack;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        leading: showBack
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 19),
                color: AppColors.textPrimary,
                onPressed: onBack ?? () => Navigator.of(context).maybePop(),
              )
            : null,
        title: Text(title, style: AppText.title(17, w: FontWeight.w600)),
        actions: actions,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      body: body,
      bottomNavigationBar: bottomBar,
    );
  }
}

/// White rounded card with a hairline border — the prototype's base surface.
class SurfaceCard extends StatelessWidget {
  const SurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.color,
    this.borderColor,
    this.radius = AppRadii.md,
    this.elevated = false,
    this.tint,
    this.gradient,
    this.margin,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;
  final Color? borderColor;
  final double radius;
  final bool elevated;

  /// When set, the card gets a soft coloured shadow in this hue, which is
  /// what separates a featured card from a plain one.
  final Color? tint;
  final Gradient? gradient;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final shadow = tint != null
        ? AppShadows.layered(tint!)
        : (elevated ? AppShadows.raised : null);

    // Material (not Container) so ListTile children still paint their own
    // background and ink splashes.
    final content = Material(
      color: gradient == null ? (color ?? AppColors.surface) : Colors.transparent,
      borderRadius: BorderRadius.circular(radius),
      clipBehavior: Clip.antiAlias,
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          gradient: gradient,
          color: gradient == null ? Colors.transparent : null,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: borderColor ?? AppColors.border),
          boxShadow: shadow,
        ),
        child: child,
      ),
    );

    final body = onTap == null ? content : PressScale(onTap: onTap!, child: content);

    if (margin == null) return body;
    return Padding(padding: margin!, child: body);
  }
}

/// A softly tinted, glassy tile — the replacement for the old flat
/// quick-action blocks. Reads as a distinct surface without the weight of
/// a full card.
class GlassTile extends StatelessWidget {
  const GlassTile({
    super.key,
    required this.child,
    this.onTap,
    this.tint = AppColors.primary,
    this.padding = const EdgeInsets.all(14),
    this.radius = AppRadii.lg,
  });

  final Widget child;
  final VoidCallback? onTap;
  final Color tint;
  final EdgeInsetsGeometry padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final content = Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.alphaBlend(tint.withValues(alpha: 0.10), AppColors.surface),
              Color.alphaBlend(tint.withValues(alpha: 0.04), AppColors.surface),
            ],
          ),
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: tint.withValues(alpha: 0.16)),
        ),
        child: Padding(padding: padding, child: child),
      ),
    );
    return onTap == null ? content : PressScale(onTap: onTap!, child: content);
  }
}

/// A gradient panel with a slow drifting highlight, used behind hero
/// content on the home, session, and account screens.
class GradientHero extends StatelessWidget {
  const GradientHero({
    super.key,
    required this.child,
    this.gradient,
    this.padding = const EdgeInsets.all(20),
    this.radius = AppRadii.xl,
    this.animated = true,
  });

  final Widget child;
  final Gradient? gradient;
  final EdgeInsetsGeometry padding;
  final double radius;
  final bool animated;

  @override
  Widget build(BuildContext context) {
    final panel = Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: gradient ?? AppGradients.aurora,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: AppShadows.glow(AppColors.primary),
      ),
      child: child,
    );

    if (animated && !MediaQuery.disableAnimationsOf(context)) {
      return _ShimmerSheen(radius: radius, child: panel);
    }
    return panel;
  }
}

/// Drifts a soft white highlight across its child without letting the
/// sheen escape the child's shape.
class _ShimmerSheen extends StatefulWidget {
  const _ShimmerSheen({required this.child, required this.radius});

  final Widget child;
  final double radius;

  @override
  State<_ShimmerSheen> createState() => _ShimmerSheenState();
}

class _ShimmerSheenState extends State<_ShimmerSheen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 4200),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.radius),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) => Stack(
          children: [
            child!,
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment(-2.4 + 4.8 * _controller.value, -1),
                      end: Alignment(-1.4 + 4.8 * _controller.value, 1),
                      colors: [
                        Colors.white.withValues(alpha: 0.0),
                        Colors.white.withValues(alpha: 0.14),
                        Colors.white.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        child: widget.child,
      ),
    );
  }
}

/// Small uppercase grey label that opens a section.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: AppText.overline(11, color: color ?? AppColors.textFaint),
    );
  }
}

/// Section header with an optional right-aligned action.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppText.title(17, w: FontWeight.w700)),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: AppText.body(13, color: AppColors.textSecondary),
                ),
              ],
            ],
          ),
        ),
        if (actionLabel != null && onAction != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              minimumSize: const Size(0, 34),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  actionLabel!,
                  style: AppText.label(
                    13,
                    w: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(Icons.chevron_right_rounded,
                    size: 18, color: AppColors.primary),
              ],
            ),
          ),
      ],
    );
  }
}

/// Tinted pill used for availability, status, and counts.
class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.label,
    this.color = AppColors.primary,
    this.background,
    this.icon,
    this.compact = false,
    this.pulse = false,
  });

  final String label;
  final Color color;
  final Color? background;
  final IconData? icon;
  final bool compact;
  final bool pulse;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3.5 : 5,
      ),
      decoration: BoxDecoration(
        color: background ?? color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadii.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (pulse) ...[
            _PulseDot(color: color),
            const SizedBox(width: 6),
          ] else if (icon != null) ...[
            Icon(icon, size: compact ? 12 : 13, color: color),
            const SizedBox(width: 4),
          ],
          // Flexible so the pill can shrink inside tight rows rather than
          // overflowing the parent.
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.label(
                compact ? 11 : 12,
                w: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PulseDot extends StatefulWidget {
  const _PulseDot({required this.color});

  final Color color;

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.color.withValues(alpha: 1.0 - (0.45 * _controller.value)),
        ),
      ),
    );
  }
}

/// Label/value pair, split left/right.
class InfoRow extends StatelessWidget {
  const InfoRow({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
    this.dense = false,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: dense ? 7 : 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: AppText.body(13.5, color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: AppText.title(
                14,
                w: FontWeight.w600,
                color: valueColor ?? AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tinted callout used for the amber "seat unavailable" and green
/// "3 copies available" states.
///
/// Named [Callout] rather than [Banner] because Flutter's Material library
/// already exports a widget by that name.
class Callout extends StatelessWidget {
  const Callout({
    super.key,
    required this.message,
    this.icon,
    this.tone = CalloutTone.info,
    this.title,
    this.margin,
  });

  final String message;
  final String? title;
  final IconData? icon;
  final CalloutTone tone;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final (fg, bg) = switch (tone) {
      CalloutTone.info => (AppColors.primary, AppColors.primarySoft),
      CalloutTone.success => (AppColors.success, AppColors.successSoft),
      CalloutTone.warning => (AppColors.warning, AppColors.warningSoft),
      CalloutTone.danger => (AppColors.error, AppColors.errorSoft),
      CalloutTone.neutral => (AppColors.neutral, AppColors.neutralSoft),
    };

    return Container(
      margin: margin,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadii.sm),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 19, color: fg),
            const SizedBox(width: 11),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null) ...[
                  Text(
                    title!,
                    style: AppText.title(13.5, w: FontWeight.w600, color: fg),
                  ),
                  const SizedBox(height: 3),
                ],
                Text(message, style: AppText.body(12.5, color: fg, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum CalloutTone { info, success, warning, danger, neutral }

/// Empty-state block: icon in a soft circle, a headline, and an optional CTA.
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
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primarySoft,
              ),
              child: Icon(icon, size: 36, color: AppColors.primary),
            ),
            const SizedBox(height: 20),
            Text(title, style: AppText.title(17, w: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppText.body(13.5, color: AppColors.textSecondary, height: 1.5),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 22),
              OutlinedButton(
                onPressed: onAction,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 46),
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                ),
                child: Text(
                  actionLabel!,
                  style: AppText.label(
                    13,
                    w: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Horizontal scrolling row of selectable chips.
class FilterChipRow extends StatelessWidget {
  const FilterChipRow({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
    this.iconBuilder,
    this.isSelectedOf,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
  });

  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelected;
  final IconData Function(String)? iconBuilder;
  final bool Function(String option)? isSelectedOf;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: padding,
        itemCount: options.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final option = options[i];
          final isSelected =
              isSelectedOf?.call(option) ?? option == selected;
          final icon = iconBuilder?.call(option);
          return PressScale(
            onTap: () => onSelected(option),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadii.full),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.border,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(
                      icon,
                      size: 15,
                      color: isSelected ? AppColors.textInverse : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    option,
                    style: AppText.label(
                      13,
                      w: FontWeight.w600,
                      color: isSelected ? AppColors.textInverse : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Two-or-three way pill switcher used for the Books/Seats/Waiting tabs
/// and the Active/History tabs.
class SegmentedTabs extends StatelessWidget {
  const SegmentedTabs({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
  });

  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelected;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.surfaceSunken,
          borderRadius: BorderRadius.circular(AppRadii.sm),
        ),
        child: Row(
          children: [
            for (final option in options)
              Expanded(
                child: PressScale(
                  onTap: () => onSelected(option),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    height: 38,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: option == selected ? AppColors.surface : Colors.transparent,
                      borderRadius: BorderRadius.circular(AppRadii.xs),
                      boxShadow: option == selected ? AppShadows.card : null,
                    ),
                    child: Text(
                      option,
                      style: AppText.label(
                        13.5,
                        w: FontWeight.w600,
                        color: option == selected
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Sticky bar for the primary action at the bottom of a screen.
class BottomActionBar extends StatelessWidget {
  const BottomActionBar({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          child: child,
        ),
      ),
    );
  }
}

/// Full-width button with an optional leading icon and four tones.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.trailingIcon,
    this.tone = ButtonTone.primary,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final IconData? trailingIcon;
  final ButtonTone tone;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (tone) {
      ButtonTone.primary => (AppColors.primary, AppColors.textInverse),
      ButtonTone.secondary => (AppColors.surface, AppColors.primary),
      ButtonTone.danger => (AppColors.surface, AppColors.error),
      ButtonTone.neutral => (AppColors.surfaceMuted, AppColors.textPrimary),
    };

    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          elevation: 0,
          shadowColor: Colors.transparent,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.sm),
            side: switch (tone) {
              ButtonTone.secondary => const BorderSide(color: AppColors.primary, width: 1.4),
              ButtonTone.danger => const BorderSide(color: AppColors.error, width: 1.4),
              _ => BorderSide.none,
            },
          ),
          textStyle: AppText.title(15, w: FontWeight.w600, color: fg),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 19),
              const SizedBox(width: 9),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.title(15, w: FontWeight.w600, color: fg),
              ),
            ),
            if (trailingIcon != null) ...[
              const SizedBox(width: 6),
              Icon(trailingIcon, size: 18),
            ],
          ],
        ),
      ),
    );
  }
}

enum ButtonTone { primary, secondary, danger, neutral }

/// A row with an optional icon square and chevron — the Settings and
/// "Reservation Information" row style.
class SettingRow extends StatelessWidget {
  const SettingRow({
    super.key,
    required this.label,
    this.value,
    this.icon,
    this.onTap,
    this.showChevron = true,
    this.valueColor,
  });

  final String label;
  final String? value;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool showChevron;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            if (icon != null) ...[
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(AppRadii.xs),
                ),
                child: Icon(icon, size: 18, color: AppColors.primary),
              ),
              const SizedBox(width: 13),
            ],
            Expanded(
              child: Text(
                label,
                style: AppText.body(14.5, color: AppColors.textPrimary),
              ),
            ),
            if (value != null)
              Text(
                value!,
                style: AppText.body(14, color: valueColor ?? AppColors.textSecondary),
              ),
            if (showChevron) ...[
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right_rounded,
                  size: 20, color: AppColors.textFaint),
            ],
          ],
        ),
      ),
    );
  }
}

/// A soft rounded square holding a single icon.
class IconBadge extends StatelessWidget {
  const IconBadge({
    super.key,
    required this.icon,
    this.color = AppColors.primary,
    this.background,
    this.size = 40,
  });

  final IconData icon;
  final Color color;
  final Color? background;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background ?? color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadii.sm),
      ),
      child: Icon(icon, size: size * 0.46, color: color),
    );
  }
}

/// Book cover from OpenLibrary, falling back to a generated spine plate.
class BookCover extends StatelessWidget {
  const BookCover({
    super.key,
    required this.title,
    this.color,
    this.isbn,
    this.width = 56,
    this.height = 78,
    this.radius = AppRadii.xs,
  });

  final String title;
  final int? color;
  final String? isbn;
  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final base = color ?? AppColors.coverPalette[title.hashCode.abs() % AppColors.coverPalette.length];

    Widget plate() => _CoverPlate(title: title, base: base, radius: radius);

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: isbn == null
            ? plate()
            : Image.network(
                'https://covers.openlibrary.org/b/isbn/$isbn-L.jpg',
                fit: BoxFit.cover,
                gaplessPlayback: true,
                errorBuilder: (_, __, ___) => plate(),
                loadingBuilder: (context, child, progress) =>
                    progress == null ? child : plate(),
              ),
      ),
    );
  }
}

class _CoverPlate extends StatelessWidget {
  const _CoverPlate({
    required this.title,
    required this.base,
    required this.radius,
  });

  final String title;
  final int base;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final words =
        title.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    final initials = words.take(2).map((w) => w[0].toUpperCase()).join();

    return Container(
      decoration: BoxDecoration(
        gradient: AppGradients.cover(base),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 5,
            top: 0,
            bottom: 0,
            child: Container(
                width: 1.2, color: Colors.white.withValues(alpha: 0.35)),
          ),
          Center(
            child: Text(
              initials,
              style: AppText.title(
                15,
                w: FontWeight.w700,
                color: Colors.white.withValues(alpha: 0.94),
              ),
            ),
          ),
          Positioned(
            left: 12,
            right: 8,
            bottom: 8,
            child: Container(
              height: 1.4,
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

/// The green tick in a soft circle used at the top of every success screen.
class SuccessCheck extends StatelessWidget {
  const SuccessCheck({super.key, this.size = 76, this.color = AppColors.success});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.6, end: 1),
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeOutBack,
      builder: (context, value, child) =>
          Transform.scale(scale: value, child: child),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.14),
        ),
        child: Icon(Icons.check_rounded, size: size * 0.52, color: color),
      ),
    );
  }
}

/// A number that counts up when it first appears — used for queue position,
/// live-density figures, and the staff dashboard stats.
class CountUp extends StatelessWidget {
  const CountUp({
    super.key,
    required this.value,
    this.style,
    this.duration = const Duration(milliseconds: 900),
    this.suffix = '',
    this.prefix = '',
  });

  final int value;
  final TextStyle? style;
  final Duration duration;
  final String suffix;
  final String prefix;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, animated, _) => Text(
        '$prefix${animated.round()}$suffix',
        style: style,
      ),
    );
  }
}

/// Fades and lifts children in sequence — the entrance treatment on lists
/// and card stacks.
class StaggeredEntrance extends StatelessWidget {
  const StaggeredEntrance({
    super.key,
    required this.child,
    this.index = 0,
    this.step = const Duration(milliseconds: 55),
    this.offset = 14,
  });

  final Widget child;
  final int index;
  final Duration step;
  final double offset;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;

    return TweenAnimationBuilder<double>(
      key: ValueKey('stagger-$index'),
      tween: Tween(begin: 0, end: 1),
      duration: step * (index + 1) + const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, (1 - value) * offset),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

/// Press feedback: a small scale-down that springs back.
class PressScale extends StatefulWidget {
  const PressScale({
    super.key,
    required this.onTap,
    required this.child,
    this.scale = 0.975,
  });

  final VoidCallback onTap;
  final Widget child;
  final double scale;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? widget.scale : 1,
        duration: const Duration(milliseconds: 130),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}

/// A thin progress track — the "Live library density" bars.
class MeterBar extends StatelessWidget {
  const MeterBar({
    super.key,
    required this.value,
    this.color = AppColors.success,
    this.height = 6,
    this.background,
  });

  final double value;
  final Color color;
  final double height;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => Container(
        height: height,
        decoration: BoxDecoration(
          color: background ?? AppColors.surfaceSunken,
          borderRadius: BorderRadius.circular(AppRadii.full),
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: value.clamp(0.0, 1.0)),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutCubic,
            builder: (context, animated, _) => Container(
              width: constraints.maxWidth * animated,
              height: height,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color.withValues(alpha: 0.7), color],
                ),
                borderRadius: BorderRadius.circular(AppRadii.full),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The statistic tiles on the staff dashboard.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.label,
    required this.value,
    this.suffix = '',
    this.caption,
    this.color = AppColors.primary,
    this.icon,
  });

  final String label;
  final int value;
  final String suffix;
  final String? caption;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      padding: const EdgeInsets.all(14),
      tint: color.withValues(alpha: 0.30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 5),
              ],
              Expanded(child: SectionLabel(label)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              CountUp(
                value: value,
                style: AppText.display(
                  25,
                  w: FontWeight.w800,
                  color: color,
                  ls: -0.6,
                ),
              ),
              if (suffix.isNotEmpty)
                Text(
                  suffix,
                  style: AppText.title(
                    13,
                    w: FontWeight.w600,
                    color: AppColors.textFaint,
                  ),
                ),
            ],
          ),
          if (caption != null) ...[
            const SizedBox(height: 4),
            Text(
              caption!,
              style: AppText.body(11.5, color: AppColors.textFaint),
            ),
          ],
        ],
      ),
    );
  }
}
