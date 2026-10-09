import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

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
        systemOverlayStyle: AppColors.isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
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
    // background and ink splashes. M3 tonal surface: no hairline border
    // unless the caller asks for one.
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
          border: borderColor == null
              ? null
              : Border.all(color: borderColor!),
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

/// The one hero panel per screen: `hero` gradient (deep blue, 135°) with
/// a slow drifting white sheen. Radius 28, white text, calm shadow — the
/// spec retires glow, so the lift comes from the gradient itself.
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
        gradient: gradient ?? AppGradients.hero,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: AppColors.isDark
            ? null
            : [
                BoxShadow(
                  color: const Color(0xFF0842A0).withValues(alpha: 0.22),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                ),
              ],
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
                Icon(Icons.chevron_right_rounded,
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
    this.color,
    this.background,
    this.icon,
    this.compact = false,
    this.pulse = false,
  });

  final String label;
  final Color? color;
  final Color? background;
  final IconData? icon;
  final bool compact;
  final bool pulse;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppColors.primary;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3.5 : 5,
      ),
      decoration: BoxDecoration(
        color: background ?? effectiveColor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadii.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (pulse) ...[
            _PulseDot(color: effectiveColor),
            const SizedBox(width: 6),
          ] else if (icon != null) ...[
            Icon(icon, size: compact ? 12 : 13, color: effectiveColor),
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
                color: effectiveColor,
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
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primarySoft,
              ),
              child: Icon(icon, size: 36, color: AppColors.primaryDark),
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
              // M3 filter chip: selected = secondaryContainer with a
              // leading check, unselected = surface with an outline.
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.cyanSoft
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadii.full),
                border: Border.all(
                  color: isSelected
                      ? Colors.transparent
                      : AppColors.borderStrong,
                  width: isSelected ? 0 : 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isSelected && icon == null) ...[
                    Icon(
                      Icons.check_rounded,
                      size: 15,
                      color: AppColors.scheme.onSecondaryContainer,
                    ),
                    const SizedBox(width: 5),
                  ],
                  if (icon != null) ...[
                    Icon(
                      icon,
                      size: 15,
                      color: isSelected
                          ? AppColors.scheme.onSecondaryContainer
                          : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    option,
                    style: AppText.label(
                      13,
                      w: FontWeight.w600,
                      color: isSelected
                          ? AppColors.scheme.onSecondaryContainer
                          : AppColors.textSecondary,
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
        // M3 segmented button: outlined track, selected segment in the
        // secondary container.
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadii.full),
          border: Border.all(color: AppColors.borderStrong),
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
                      color: option == selected
                          ? AppColors.cyanSoft
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(AppRadii.full),
                    ),
                    child: Text(
                      option,
                      style: AppText.label(
                        13.5,
                        w: FontWeight.w600,
                        color: option == selected
                            ? AppColors.scheme.onSecondaryContainer
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
      decoration: BoxDecoration(
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
    // M3 button roles: primary = filled, secondary = outlined,
    // danger = outlined error, neutral = filled tonal.
    return SizedBox(
      height: 52,
      child: switch (tone) {
        ButtonTone.primary => ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textInverse,
              elevation: 0,
              shadowColor: Colors.transparent,
              shape: const StadiumBorder(),
            ),
            child: _buttonChild(),
          ),
        ButtonTone.secondary => OutlinedButton(
            onPressed: onPressed,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              backgroundColor: Colors.transparent,
              side: BorderSide(color: AppColors.borderStrong, width: 1.2),
              shape: const StadiumBorder(),
            ),
            child: _buttonChild(),
          ),
        ButtonTone.danger => OutlinedButton(
            onPressed: onPressed,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              backgroundColor: Colors.transparent,
              side: BorderSide(color: AppColors.error.withValues(alpha: 0.5)),
              shape: const StadiumBorder(),
            ),
            child: _buttonChild(),
          ),
        ButtonTone.neutral => ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primarySoft,
              foregroundColor: AppColors.primaryDark,
              elevation: 0,
              shadowColor: Colors.transparent,
              shape: const StadiumBorder(),
            ),
            child: _buttonChild(),
          ),
      },
    );
  }

  Widget _buttonChild() {
    final fg = switch (tone) {
      ButtonTone.primary => AppColors.textInverse,
      ButtonTone.secondary => AppColors.primary,
      ButtonTone.danger => AppColors.error,
      ButtonTone.neutral => AppColors.primaryDark,
    };
    return Row(
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
              Icon(Icons.chevron_right_rounded,
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
    this.color,
    this.background,
    this.size = 40,
  });

  final IconData icon;
  final Color? color;
  final Color? background;
  final double size;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppColors.primary;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background ?? effectiveColor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadii.sm),
      ),
      child: Icon(icon, size: size * 0.46, color: effectiveColor),
    );
  }
}

/// Book cover from OpenLibrary, falling back to a generated spine plate.
///
/// Pass [heroTag] on list/detail pairs so the cover flies between routes.
class BookCover extends StatelessWidget {
  const BookCover({
    super.key,
    required this.title,
    this.color,
    this.isbn,
    this.width = 56,
    this.height = 78,
    this.radius = AppRadii.xs,
    this.heroTag,
  });

  final String title;
  final int? color;
  final String? isbn;
  final double width;
  final double height;
  final double radius;
  final String? heroTag;

  @override
  Widget build(BuildContext context) {
    final base = color ?? AppColors.coverPalette[title.hashCode.abs() % AppColors.coverPalette.length];

    Widget plate() => _CoverPlate(title: title, base: base, radius: radius);

    // OpenLibrary keys on bare digits — dashes in stored ISBNs break the URL.
    final cleanIsbn = isbn?.replaceAll(RegExp(r'[^0-9Xx]'), '');

    Widget cover = Container(
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
        child: cleanIsbn == null || cleanIsbn.isEmpty
            ? plate()
            : Image.network(
                'https://covers.openlibrary.org/b/isbn/$cleanIsbn-L.jpg?default=false',
                fit: BoxFit.cover,
                gaplessPlayback: true,
                errorBuilder: (_, __, ___) => plate(),
                loadingBuilder: (context, child, progress) =>
                    progress == null
                        ? AnimatedOpacity(
                            opacity: 1,
                            duration: const Duration(milliseconds: 260),
                            child: child,
                          )
                        : plate(),
              ),
      ),
    );

    if (heroTag != null) {
      cover = Hero(tag: heroTag!, child: cover);
    }
    return cover;
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
  const SuccessCheck({super.key, this.size = 76, this.color});

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppColors.success;
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
          color: effectiveColor.withValues(alpha: 0.14),
        ),
        child: Icon(Icons.check_rounded, size: size * 0.52, color: effectiveColor),
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
      onTapDown: (_) {
        Haptics.tap();
        setState(() => _pressed = true);
      },
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
    this.color,
    this.height = 6,
    this.background,
  });

  final double value;
  final Color? color;
  final double height;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppColors.success;
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
                  colors: [
                    effectiveColor.withValues(alpha: 0.7),
                    effectiveColor
                  ],
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

/// Centralised haptic vocabulary so interactions feel consistent.
class Haptics {
  Haptics._();

  /// Light tick for taps and card presses.
  static void tap() => HapticFeedback.lightImpact();

  /// Subtle click for segmented controls and tab switches.
  static void selection() => HapticFeedback.selectionClick();

  /// Firmer double-tick for confirmations and completed flows.
  static void success() => HapticFeedback.mediumImpact();

  /// Warning buzz for destructive or error states.
  static void danger() => HapticFeedback.vibrate();
}

/// A shimmering placeholder block used while content loads.
class Skeleton extends StatefulWidget {
  const Skeleton({
    super.key,
    this.width,
    this.height = 14,
    this.radius = AppRadii.xs,
    this.color,
  });

  final double? width;
  final double height;
  final double radius;
  final Color? color;

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = widget.color ??
        (AppColors.isDark
            ? Colors.white.withValues(alpha: 0.07)
            : Colors.black.withValues(alpha: 0.06));
    final highlight = AppColors.isDark
        ? Colors.white.withValues(alpha: 0.16)
        : Colors.black.withValues(alpha: 0.03);

    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.radius),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(-1.6 + 3.2 * _controller.value, 0),
              end: Alignment(-0.6 + 3.2 * _controller.value, 0),
              colors: [base, highlight, base],
            ),
          ),
        ),
      ),
    );
  }
}

/// A card-shaped skeleton placeholder matching [SurfaceCard] proportions.
class SkeletonCard extends StatelessWidget {
  const SkeletonCard({super.key, this.height = 84, this.padding});

  final double height;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      padding: padding ?? const EdgeInsets.all(16),
      child: SizedBox(
        height: height,
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Skeleton(width: 44, height: 44, radius: AppRadii.sm),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Skeleton(
                          width: double.infinity,
                          height: 12,
                          radius: AppRadii.full),
                      SizedBox(height: 8),
                      Skeleton(width: 140, height: 10, radius: AppRadii.full),
                    ],
                  ),
                ),
              ],
            ),
            Spacer(),
            Skeleton(width: double.infinity, height: 10, radius: AppRadii.full),
          ],
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
    this.color,
    this.icon,
  });

  final String label;
  final int value;
  final String suffix;
  final String? caption;
  final Color? color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppColors.primary;
    return SurfaceCard(
      padding: const EdgeInsets.all(14),
      tint: effectiveColor.withValues(alpha: 0.30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14, color: effectiveColor),
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
                  color: effectiveColor,
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

/// A live/stale/offline freshness indicator driven by a real timestamp.
///
/// `< 45s` → "Live · just now" with a pulsing green dot, `< 5 min` →
/// "Live · N min ago", older → "Stale · N min ago" with an amber dot,
/// and a null timestamp reads as "Offline — showing cached data".
class LiveFreshness extends StatelessWidget {
  const LiveFreshness({
    super.key,
    required this.lastSyncedAt,
    this.size = 11.5,
  });

  final DateTime? lastSyncedAt;
  final double size;

  @override
  Widget build(BuildContext context) {
    final (color, label, pulsing) = _resolve();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        pulsing ? _PulseDot(color: color) : _StaticDot(color: color),
        const SizedBox(width: 7),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.body(size, color: AppColors.textFaint),
          ),
        ),
      ],
    );
  }

  (Color, String, bool) _resolve() {
    if (lastSyncedAt == null) {
      return (AppColors.warning, 'Offline — showing cached data', false);
    }
    final diff = DateTime.now().difference(lastSyncedAt!);
    if (diff.inSeconds < 45) return (AppColors.success, 'Live · just now', true);
    if (diff.inMinutes < 5) {
      return (AppColors.success, 'Live · ${diff.inMinutes} min ago', true);
    }
    return (AppColors.warning, 'Stale · ${diff.inMinutes} min ago', false);
  }
}

class _StaticDot extends StatelessWidget {
  const _StaticDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

/// The signature call-slip motif (spec §2.4 / §4.1): a surface card with
/// 12 dp semicircular side notches at the perforation line and a dashed
/// perforation. Top = identity, bottom = QR/meta. Light mode only gets
/// the soft card shadow; dimmed + a diagonal stamp when cancelled.
class TicketCard extends StatelessWidget {
  const TicketCard({
    super.key,
    required this.top,
    required this.bottom,
    this.notchFraction = 0.60,
    this.radius = AppRadii.lg,
    this.dimmed = false,
  });

  final Widget top;
  final Widget bottom;

  /// Vertical position of the perforation, as a fraction of height.
  final double notchFraction;
  final double radius;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final shape = TicketShapeBorder(
      radius: radius,
      notchFraction: notchFraction,
    );
    return Material(
      color: AppColors.surface,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      elevation: AppColors.isDark ? 0 : 5,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      child: Opacity(
        opacity: dimmed ? 0.35 : 1,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
              child: top,
            ),
            // Perforation: dashed hairline between the notches.
            CustomPaint(
              size: const Size.fromHeight(1),
              painter: _DashedLinePainter(color: AppColors.border),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
              child: bottom,
            ),
          ],
        ),
      ),
    );
  }
}

/// Rounded-rect shape with concave semicircular notches cut from both
/// sides at [notchFraction] of the height — drawn with arcs, not images.
class TicketShapeBorder extends ShapeBorder {
  const TicketShapeBorder({
    this.radius = AppRadii.lg,
    this.notchRadius = 12,
    this.notchFraction = 0.60,
  });

  final double radius;
  final double notchRadius;
  final double notchFraction;

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      Path()..addRect(rect);

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    final r = radius;
    final n = notchRadius;
    final cy = rect.top + (rect.height * notchFraction);
    return Path()
      ..moveTo(rect.left + r, rect.top)
      ..lineTo(rect.right - r, rect.top)
      ..arcToPoint(
        Offset(rect.right, rect.top + r),
        radius: Radius.circular(r),
      )
      ..lineTo(rect.right, cy - n)
      ..arcToPoint(
        Offset(rect.right, cy + n),
        radius: Radius.circular(n),
        clockwise: false,
      )
      ..lineTo(rect.right, rect.bottom - r)
      ..arcToPoint(
        Offset(rect.right - r, rect.bottom),
        radius: Radius.circular(r),
      )
      ..lineTo(rect.left + r, rect.bottom)
      ..arcToPoint(
        Offset(rect.left, rect.bottom - r),
        radius: Radius.circular(r),
      )
      ..lineTo(rect.left, cy + n)
      ..arcToPoint(
        Offset(rect.left, cy - n),
        radius: Radius.circular(n),
        clockwise: false,
      )
      ..lineTo(rect.left, rect.top + r)
      ..arcToPoint(
        Offset(rect.left + r, rect.top),
        radius: Radius.circular(r),
      )
      ..close();
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {}

  @override
  ShapeBorder scale(double t) => this;
}

class _DashedLinePainter extends CustomPainter {
  const _DashedLinePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    const dash = 5;
    const gap = 5;
    var x = 0.0;
    while (x < size.width) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(math.min(x + dash, size.width), 0),
        paint,
      );
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(_DashedLinePainter oldDelegate) =>
      oldDelegate.color != color;
}

/// The QR tile (spec §4.2 QrPassTile): always white with ink modules,
/// regardless of theme — QR codes never invert. Generous quiet zone.
class QrPassTile extends StatelessWidget {
  const QrPassTile({
    super.key,
    required this.data,
    this.size = 240,
  });

  final String data;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: AppColors.border),
      ),
      // The QR shrinks to fit narrow tickets instead of overflowing.
      child: LayoutBuilder(
        builder: (context, constraints) {
          final qr = math.min(size, constraints.maxWidth - 2);
          return QrImageView(
            data: data,
            version: QrVersions.auto,
            size: qr,
            backgroundColor: Colors.white,
            eyeStyle: const QrEyeStyle(
              eyeShape: QrEyeShape.square,
              color: Color(0xFF191C20),
            ),
            dataModuleStyle: const QrDataModuleStyle(
              dataModuleShape: QrDataModuleShape.square,
              color: Color(0xFF191C20),
            ),
          );
        },
      ),
    );
  }
}

/// The one destructive-action confirmation (spec §4.4 / M01): radius 28,
/// title, body with the consequence spelled out, safe action left in a
/// tonal tone, destructive right in danger. Returns true when the user
/// chose the destructive action.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String body,
  required String confirmLabel,
  String cancelLabel = 'Cancel',
}) {
  return showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.xl),
      ),
      title: Text(title, style: AppText.title(19, w: FontWeight.w700)),
      content: Text(
        body,
        style: AppText.body(14.5, height: 1.5, color: AppColors.textSecondary),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(
            cancelLabel,
            style: AppText.label(14, w: FontWeight.w600,
                color: AppColors.primary),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.error,
          ),
          child: Text(
            confirmLabel,
            style: AppText.label(14, w: FontWeight.w700,
                color: AppColors.error),
          ),
        ),
      ],
    ),
  ).then((value) => value ?? false);
}

/// Outlined shelf-code tag (`B2-14`) in tabular figures — one of the
/// signature details of the design language.
class ShelfTag extends StatelessWidget {
  const ShelfTag(this.code, {super.key, this.color});

  final String code;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color ?? AppColors.borderStrong),
      ),
      child: Text(
        code,
        style: AppText.label(
          11.5,
          w: FontWeight.w600,
          ls: 0.3,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

/// App-level strip shown under the chrome on root tabs when the live
/// streams have gone quiet: never synced, or the last sync is older than
/// five minutes. Slides in and out so it never jolts the layout.
class ConnectivityBanner extends StatelessWidget {
  const ConnectivityBanner({super.key, required this.lastSyncedAt});

  final DateTime? lastSyncedAt;

  /// Null sync = cold cache; anything older than five minutes is treated
  /// as a connection problem, matching [LiveFreshness]'s stale threshold.
  bool get _shouldShow {
    if (lastSyncedAt == null) return true;
    return DateTime.now().difference(lastSyncedAt!).inMinutes >= 5;
  }

  String get _message {
    if (lastSyncedAt == null) return 'Offline — showing cached data';
    final minutes = DateTime.now().difference(lastSyncedAt!).inMinutes;
    return 'Connection issue — data is $minutes min old';
  }

  @override
  Widget build(BuildContext context) {
    final show = _shouldShow;
    return Semantics(
      liveRegion: true,
      child: AnimatedSlide(
        offset: show ? Offset.zero : const Offset(0, -1),
        duration: AppMotion.base,
        curve: AppMotion.enter,
        child: AnimatedOpacity(
          opacity: show ? 1 : 0,
          duration: AppMotion.base,
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.warningContainer,
              borderRadius: BorderRadius.circular(AppRadii.sm),
            ),
            child: Row(
              children: [
                Icon(Icons.cloud_off_rounded,
                    size: 15, color: AppColors.onWarningContainer),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _message,
                    style: AppText.label(
                      12,
                      w: FontWeight.w600,
                      color: AppColors.onWarningContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The error sibling of [EmptyState]: red-toned icon circle, a fixed
/// friendly headline, and a Retry action. Never shows raw exception text.
class ErrorState extends StatelessWidget {
  const ErrorState({
    super.key,
    this.message = 'We could not reach the library service just now.',
    this.onRetry,
  });

  final String message;
  final VoidCallback? onRetry;

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
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.errorContainer,
              ),
              child: Icon(Icons.error_outline_rounded,
                  size: 36, color: AppColors.error),
            ),
            const SizedBox(height: 20),
            Text('Something went wrong',
                style: AppText.title(17, w: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppText.body(
                  13.5, color: AppColors.textSecondary, height: 1.5),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 22),
              OutlinedButton(
                onPressed: onRetry,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 46),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                ),
                child: Text(
                  'Retry',
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
