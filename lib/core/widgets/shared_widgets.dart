import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../state/app_state.dart';
import '../feedback/app_feedback.dart';

import '../theme/app_theme.dart';
import 'glass.dart';

/// Shared building blocks for the campus-blue prototype.
///
/// "Liquid Glass Campus": frosted translucent cards over an aurora
/// backdrop, a single blue for action, and semantic colour reserved for
/// status. Cards use [FrostedCard] (no blur) so lists scroll smoothly; the
/// blur lives in chrome only (see glass.dart). Presses spring and fire
/// [AppFeedback] (haptic + soft sound).

/// The standard screen chrome: aurora backdrop, a blurred glass app bar
/// with a centred title and back chevron, and a bottom action slot.
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.bottomBar,
    this.showBack = true,
    this.onBack,
    this.contentUnderBar = false,
  });

  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? bottomBar;
  final bool showBack;
  final VoidCallback? onBack;

  /// When true the body extends beneath the glass app bar so content
  /// scrolls under the blur. The scrollable must then start with
  /// [GlassAppBar.contentTopPadding] of top padding.
  final bool contentUnderBar;

  @override
  Widget build(BuildContext context) {
    return AuroraBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: contentUnderBar,
        appBar: GlassAppBar(
          title: title,
          actions: actions,
          leading: showBack
              ? IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 19),
                  color: AppColors.textPrimary,
                  onPressed: () {
                    AppFeedback.tap();
                    (onBack ?? () => Navigator.of(context).maybePop())();
                  },
                )
              : null,
        ),
        body: body,
        bottomNavigationBar: bottomBar,
      ),
    );
  }
}

/// Frosted rounded card (translucent fill, rim light, hairline, soft
/// shadow) with no backdrop blur, so it is safe in scrolling lists.
/// Passing [color] or [gradient] switches to a solid fill.
class SurfaceCard extends StatelessWidget {
  const SurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.color,
    this.borderColor,
    this.radius = AppRadii.card,
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
    final solid = color != null || gradient != null;
    final accent = tint != null
        ? AppShadows.layered(tint!)
        : (elevated ? AppShadows.raised : const <BoxShadow>[]);

    Widget content;
    if (!solid) {
      content = FrostedCard(
        radius: radius,
        padding: padding,
        shadows: accent.isEmpty,
        border: borderColor == null,
        child: child,
      );
      if (borderColor != null) {
        content = DecoratedBox(
          position: DecorationPosition.foreground,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: borderColor!),
          ),
          child: content,
        );
      }
      if (accent.isNotEmpty) {
        content = DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            boxShadow: accent,
          ),
          child: content,
        );
      }
    } else {
      // Material (not Container) so ListTile children still paint their
      // own background and ink splashes.
      content = Material(
        color: gradient == null ? color : Colors.transparent,
        borderRadius: BorderRadius.circular(radius),
        clipBehavior: Clip.antiAlias,
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: borderColor ?? AppGlass.border),
            boxShadow: accent.isEmpty ? AppGlass.shadows : accent,
          ),
          child: child,
        ),
      );
    }

    final body = onTap == null ? content : PressScale(onTap: onTap!, child: content);

    if (margin == null) return body;
    return Padding(padding: margin!, child: body);
  }
}

/// The one hero panel per screen: the hero gradient (sapphire to indigo,
/// 135 degrees) with a glass highlight at the top-left, a soft bloom at
/// the top-right, a rim line, and an optional drifting sheen. Text on it
/// should be white.
class GradientHero extends StatelessWidget {
  const GradientHero({
    super.key,
    required this.child,
    this.gradient,
    this.padding = const EdgeInsets.all(20),
    this.radius = AppRadii.xl,
    this.animated = false,
  });

  final Widget child;
  final Gradient? gradient;
  final EdgeInsetsGeometry padding;
  final double radius;
  final bool animated;

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(radius);
    final panel = DecoratedBox(
      decoration: BoxDecoration(
        gradient: gradient ?? AppGradients.hero,
        borderRadius: r,
        boxShadow: [
          BoxShadow(
            color: (AppColors.isDark ? Colors.black : const Color(0xFF0F172A))
                .withValues(alpha: AppColors.isDark ? 0.40 : 0.16),
            blurRadius: 28,
            spreadRadius: -4,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          borderRadius: r,
          border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: r,
            gradient: RadialGradient(
              center: const Alignment(0.95, -1.05),
              radius: 0.9,
              colors: [
                Colors.white.withValues(alpha: 0.20),
                Colors.white.withValues(alpha: 0),
              ],
            ),
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: r,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                stops: const [0, 0.4],
                colors: [
                  Colors.white.withValues(alpha: 0.16),
                  Colors.white.withValues(alpha: 0),
                ],
              ),
            ),
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
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
      style: AppText.overline(
        11.5,
        w: FontWeight.w700,
        ls: 1.3,
        color: color ?? AppColors.textSecondary,
      ),
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
              Text(title, style: AppText.title(18, w: FontWeight.w700)),
              if (subtitle != null) ...[
                const SizedBox(height: 3),
                Text(
                  subtitle!,
                  style: AppText.body(
                    13.5,
                    color: AppColors.textSecondary,
                    height: 1.3,
                  ),
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
        color: background ?? effectiveColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadii.full),
        border: Border.all(color: effectiveColor.withValues(alpha: 0.20)),
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
      CalloutTone.info => (
          AppColors.isDark ? const Color(0xFFFDE68A) : AppColors.primary,
          AppColors.primarySoft,
        ),
      CalloutTone.success => (
          AppColors.isDark ? AppColors.onSuccessContainer : AppColors.success,
          AppColors.successSoft,
        ),
      CalloutTone.warning => (
          AppColors.isDark ? AppColors.onWarningContainer : AppColors.warning,
          AppColors.warningSoft,
        ),
      CalloutTone.danger => (
          AppColors.isDark
              ? AppColors.scheme.onErrorContainer
              : AppColors.error,
          AppColors.errorSoft,
        ),
      CalloutTone.neutral => (AppColors.neutral, AppColors.neutralSoft),
    };

    return Container(
      margin: margin,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg.withValues(alpha: AppColors.isDark ? 0.95 : 0.92),
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(
          color: fg.withValues(alpha: AppColors.isDark ? 0.35 : 0.18),
        ),
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
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primarySoft,
                    AppColors.primarySoft.withValues(alpha: 0.55),
                  ],
                ),
                border: Border.all(color: AppGlass.rim),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.16),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
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

/// Horizontal scrolling row of selectable chips (frosted; the selected
/// chip takes an indigo wash). Selecting fires [AppFeedback.select].
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
    final dark = AppColors.isDark;
    final fgSelected = AppColors.scheme.onSecondaryContainer;
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
            feedback: isSelected ? PressFeedback.none : PressFeedback.select,
            child: AnimatedContainer(
              duration: AppMotion.fast,
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected
                    ? Color.alphaBlend(
                        AppColors.indigo.withValues(alpha: dark ? 0.42 : 0.16),
                        AppGlass.cardFill,
                      )
                    : AppGlass.cardFill,
                borderRadius: BorderRadius.circular(AppRadii.full),
                border: Border.all(
                  color: isSelected
                      ? AppColors.indigo.withValues(alpha: dark ? 0.55 : 0.35)
                      : AppGlass.border,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isSelected && icon == null) ...[
                    Icon(Icons.check_rounded, size: 15, color: fgSelected),
                    const SizedBox(width: 5),
                  ],
                  if (icon != null) ...[
                    Icon(
                      icon,
                      size: 15,
                      color: isSelected ? fgSelected : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    option,
                    style: AppText.label(
                      13,
                      w: FontWeight.w600,
                      color: isSelected ? fgSelected : AppColors.textSecondary,
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
/// and the Active/History tabs. A glass thumb springs between segments.
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
    final dark = AppColors.isDark;
    final reduced = MediaQuery.disableAnimationsOf(context);
    final index = options.indexOf(selected);
    final fgSelected = AppColors.scheme.onSecondaryContainer;
    return Padding(
      padding: padding,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppGlass.cardFill,
          borderRadius: BorderRadius.circular(AppRadii.full),
          border: Border.all(color: AppGlass.border),
        ),
        child: SizedBox(
          height: 38,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth / options.length;
              return Stack(
                children: [
                  if (index >= 0)
                    AnimatedPositioned(
                      duration: reduced ? Duration.zero : AppMotion.entranceSettle,
                      curve: AppMotion.springEntrance,
                      left: index * w,
                      width: w,
                      top: 0,
                      bottom: 0,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: dark
                              ? AppColors.indigo.withValues(alpha: 0.45)
                              : Color.alphaBlend(
                                  AppColors.indigo.withValues(alpha: 0.14),
                                  Colors.white,
                                ),
                          borderRadius: BorderRadius.circular(AppRadii.full),
                          border: Border.all(
                            color: AppColors.indigo
                                .withValues(alpha: dark ? 0.6 : 0.25),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.indigo
                                  .withValues(alpha: dark ? 0.35 : 0.18),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                      ),
                    ),
                  Row(
                    children: [
                      for (final option in options)
                        Expanded(
                          child: PressScale(
                            onTap: () => onSelected(option),
                            scale: 0.97,
                            feedback: option == selected
                                ? PressFeedback.none
                                : PressFeedback.select,
                            child: Container(
                              alignment: Alignment.center,
                              child: AnimatedDefaultTextStyle(
                                duration: AppMotion.fast,
                                style: AppText.label(
                                  13.5,
                                  w: FontWeight.w600,
                                  color: option == selected
                                      ? fgSelected
                                      : AppColors.textSecondary,
                                ),
                                child: Text(option),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Sticky glass bar for the primary action at the bottom of a screen.
class BottomActionBar extends StatelessWidget {
  const BottomActionBar({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: AppGlass.blurChrome,
          sigmaY: AppGlass.blurChrome,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppGlass.chromeFill,
            border: Border(top: BorderSide(color: AppGlass.border)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// Full-width button with an optional leading icon and four tones.
///
/// The primary tone is a gradient pill with an inner highlight and a
/// coloured glow. All tones spring on press and fire [AppFeedback.tap].
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

  VoidCallback? get _wrapped => onPressed == null
      ? null
      : () {
          AppFeedback.tap();
          onPressed!();
        };

  @override
  Widget build(BuildContext context) {
    // Roles: primary = gradient fill, secondary = glass outline,
    // danger = outlined error, neutral = tonal.
    final button = switch (tone) {
      ButtonTone.primary => _gradientButton(),
      ButtonTone.secondary => OutlinedButton(
          onPressed: _wrapped,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            backgroundColor: AppGlass.cardFill.withValues(alpha: 1),
            side: BorderSide(color: AppColors.borderStrong, width: 1.2),
            shape: const StadiumBorder(),
          ),
          child: _buttonChild(),
        ),
      ButtonTone.danger => OutlinedButton(
          onPressed: _wrapped,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.error,
            backgroundColor: AppGlass.cardFill,
            side: BorderSide(color: AppColors.error.withValues(alpha: 0.5)),
            shape: const StadiumBorder(),
          ),
          child: _buttonChild(),
        ),
      ButtonTone.neutral => ElevatedButton(
          onPressed: _wrapped,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primarySoft,
            foregroundColor: AppColors.primaryDark,
            elevation: 0,
            shadowColor: Colors.transparent,
            shape: const StadiumBorder(),
          ),
          child: _buttonChild(),
        ),
    };
    return SizedBox(
      height: 52,
      child: tone == ButtonTone.primary
          ? button
          : _PressListener(enabled: onPressed != null, child: button),
    );
  }

  Widget _gradientButton() {
    final enabled = onPressed != null;
    final base = AppColors.primary;
    final end = AppColors.isDark ? AppColors.scheme.secondary : AppColors.indigo;
    final face = Semantics(
      button: true,
      enabled: enabled,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadii.full),
          gradient: enabled
              ? LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color.lerp(base, Colors.white, 0.14)!,
                    base,
                    Color.lerp(base, end, 0.45)!,
                  ],
                )
              : null,
          color: enabled ? null : AppColors.textPrimary.withValues(alpha: 0.12),
          border: enabled
              ? Border.all(color: Colors.white.withValues(alpha: 0.22))
              : null,
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: base.withValues(alpha: 0.42),
                    blurRadius: 22,
                    spreadRadius: -6,
                    offset: const Offset(0, 9),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.10),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadii.full),
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (enabled)
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  height: 26,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withValues(alpha: 0.24),
                          Colors.white.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _buttonChild(),
              ),
            ],
          ),
        ),
      ),
    );
    if (!enabled) return face;
    return PressScale(onTap: onPressed!, child: face);
  }

  Widget _buttonChild() {
    final fg = onPressed == null
        ? AppColors.textPrimary.withValues(alpha: 0.38)
        : switch (tone) {
            ButtonTone.primary =>
                AppColors.isDark ? const Color(0xFF0F172A) : AppColors.textInverse,
            ButtonTone.secondary => AppColors.primary,
            ButtonTone.danger => AppColors.error,
            ButtonTone.neutral => AppColors.primaryDark,
          };
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 19, color: tone == ButtonTone.primary ? fg : null),
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
          Icon(trailingIcon,
              size: 18, color: tone == ButtonTone.primary ? fg : null),
        ],
      ],
    );
  }
}

enum ButtonTone { primary, secondary, danger, neutral }

/// A row with an optional icon square and chevron: the Settings and
/// "Reservation Information" row style. Give it [switchValue] and
/// [onSwitchChanged] to render a switch instead of the chevron (toggle
/// feedback included; tapping anywhere on the row flips it).
class SettingRow extends StatelessWidget {
  const SettingRow({
    super.key,
    required this.label,
    this.value,
    this.icon,
    this.onTap,
    this.showChevron = true,
    this.valueColor,
    this.switchValue,
    this.onSwitchChanged,
  });

  final String label;
  final String? value;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool showChevron;
  final Color? valueColor;
  final bool? switchValue;
  final ValueChanged<bool>? onSwitchChanged;

  @override
  Widget build(BuildContext context) {
    final hasSwitch = switchValue != null;
    final VoidCallback? rowTap = hasSwitch
        ? (onSwitchChanged == null
            ? null
            : () {
                AppFeedback.toggle();
                onSwitchChanged!(!switchValue!);
              })
        : (onTap == null
            ? null
            : () {
                AppFeedback.tap();
                onTap!();
              });
    return InkWell(
      onTap: rowTap,
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
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                  border: Border.all(color: AppGlass.rim.withValues(alpha: 0.5)),
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
            if (hasSwitch)
              IgnorePointer(
                child: Switch(value: switchValue!, onChanged: onSwitchChanged == null ? null : (_) {}),
              )
            else if (showChevron) ...[
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
    this.coverUrl,
    this.width = 56,
    this.height = 78,
    this.radius = AppRadii.xs,
    this.heroTag,
  });

  final String title;
  final int? color;
  final String? isbn;
  final String? coverUrl;
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
    final imageUrl = coverUrl?.trim().isNotEmpty == true
      ? coverUrl!.trim()
      : (cleanIsbn == null || cleanIsbn.isEmpty
        ? null
        : 'https://covers.openlibrary.org/b/isbn/$cleanIsbn-L.jpg?default=false');

    Widget cover = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 16,
            spreadRadius: -2,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: imageUrl == null
            ? plate()
            : Image.network(
            imageUrl,
                fit: BoxFit.cover,
                gaplessPlayback: true,
            headers: const {'Accept': 'image/*'},
            webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
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

/// The green tick in a soft glowing circle used at the top of every
/// success screen. Springs in and fires [AppFeedback.success] once.
class SuccessCheck extends StatefulWidget {
  const SuccessCheck({super.key, this.size = 76, this.color});

  final double size;
  final Color? color;

  @override
  State<SuccessCheck> createState() => _SuccessCheckState();
}

class _SuccessCheckState extends State<SuccessCheck> {
  @override
  void initState() {
    super.initState();
    AppFeedback.success();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveColor = widget.color ?? AppColors.success;
    final size = widget.size;
    final reduced = MediaQuery.disableAnimationsOf(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: reduced ? 1 : 0.6, end: 1),
      duration: reduced ? Duration.zero : AppMotion.entranceSettle,
      curve: AppMotion.springEntrance,
      builder: (context, value, child) =>
          Transform.scale(scale: value, child: child),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: effectiveColor.withValues(alpha: 0.16),
          border: Border.all(color: effectiveColor.withValues(alpha: 0.25)),
          boxShadow: [
            BoxShadow(
              color: effectiveColor.withValues(alpha: 0.28),
              blurRadius: 28,
              spreadRadius: -4,
              offset: const Offset(0, 8),
            ),
          ],
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

/// Which [AppFeedback] a [PressScale] fires on tap.
enum PressFeedback { tap, select, toggle, none }

/// Press feedback: scales down while held and springs back on release,
/// then fires [feedback] (haptic + sound) when the tap completes.
class PressScale extends StatefulWidget {
  const PressScale({
    super.key,
    required this.onTap,
    required this.child,
    this.scale = 0.965,
    this.feedback = PressFeedback.tap,
  });

  final VoidCallback onTap;
  final Widget child;
  final double scale;
  final PressFeedback feedback;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _pressed = false;

  void _fire() {
    switch (widget.feedback) {
      case PressFeedback.tap:
        AppFeedback.tap();
      case PressFeedback.select:
        AppFeedback.select();
      case PressFeedback.toggle:
        AppFeedback.toggle();
      case PressFeedback.none:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: () {
        _fire();
        widget.onTap();
      },
      child: _SpringScale(
        pressed: _pressed,
        scale: widget.scale,
        child: widget.child,
      ),
    );
  }
}

/// Scale-down on press, spring-back on release.
class _SpringScale extends StatelessWidget {
  const _SpringScale({
    required this.pressed,
    required this.scale,
    required this.child,
  });

  final bool pressed;
  final double scale;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    return AnimatedScale(
      scale: pressed ? scale : 1,
      duration: reduced
          ? Duration.zero
          : (pressed ? AppMotion.instant : AppMotion.pressSettle),
      curve: pressed ? Curves.easeOutCubic : AppMotion.springPress,
      child: child,
    );
  }
}

/// Adds the spring press to a child that handles its own taps (e.g. a
/// Material button), via raw pointer events so no gesture is stolen.
class _PressListener extends StatefulWidget {
  const _PressListener({required this.child, this.enabled = true});

  final Widget child;
  final bool enabled;

  @override
  State<_PressListener> createState() => _PressListenerState();
}

class _PressListenerState extends State<_PressListener> {
  bool _pressed = false;

  void _set(bool v) {
    if (_pressed != v && mounted) setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: widget.enabled ? (_) => _set(true) : null,
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: _SpringScale(
        pressed: _pressed && widget.enabled,
        scale: 0.97,
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

/// Centralised haptic vocabulary so interactions feel consistent. Routed
/// through [AppFeedback], so each call also plays its soft sound and obeys
/// the Settings switches. Prefer calling [AppFeedback] directly in new code.
class Haptics {
  Haptics._();

  /// Light tick for taps and card presses.
  static void tap() => AppFeedback.tap();

  /// Subtle click for segmented controls and tab switches.
  static void selection() => AppFeedback.select();

  /// Firmer confirmation for completed flows.
  static void success() => AppFeedback.success();

  /// Warning buzz for destructive or error states.
  static void danger() => AppFeedback.error();
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller
        ..stop()
        ..value = 0.35;
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
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
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    // Demo data is already announced by the connectivity banner.
    if (scope?.notifier?.dataSource == DataSource.demo) {
      return const SizedBox.shrink();
    }
    final (color, label, pulsing) = _resolve(scope?.notifier);
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

  (Color, String, bool) _resolve(AppState? state) {
    if (state != null) {
      // Truthful states first: the data source and connection health win
      // over the age of the last snapshot.
      if (state.dataSource == DataSource.demo) {
        return (AppColors.neutral, 'Demo data', false);
      }
      switch (state.syncStatus) {
        case SyncStatus.syncing:
          return (AppColors.neutral, 'Syncing…', false);
        case SyncStatus.offline:
          return (AppColors.warning, 'Offline · saved data', false);
        case SyncStatus.signedOut:
          return (AppColors.warning, 'Not signed in', false);
        case SyncStatus.permissionDenied:
          return (AppColors.error, 'No permission to load data', false);
        case SyncStatus.error:
          return (AppColors.error, 'Sync problem · saved data', false);
        case SyncStatus.stale:
        case SyncStatus.live:
          break;
      }
    }
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
      color: AppColors.isDark
          ? const Color(0xFF111827).withValues(alpha: 0.95)
          : Colors.white,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      elevation: AppColors.isDark ? 0 : 5,
      shadowColor: (AppColors.isDark ? Colors.black : const Color(0xFF0F172A))
          .withValues(alpha: 0.12),
      child: Opacity(
        opacity: dimmed ? 0.35 : 1,
        child: DecoratedBox(
          decoration: BoxDecoration(gradient: AppGlass.highlight),
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
                painter: _DashedLinePainter(color: AppColors.borderStrong),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                child: bottom,
              ),
            ],
          ),
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
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    canvas.drawPath(
      getOuterPath(rect),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = AppGlass.border,
    );
  }

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
    final isDark = AppColors.isDark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : null,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: color ??
              (isDark ? const Color(0xFF475569) : AppColors.borderStrong),
        ),
      ),
      child: Text(
        code,
        style: AppText.label(
          11.5,
          w: FontWeight.w600,
          ls: 0.3,
          color: isDark ? const Color(0xFFE2E8F0) : AppColors.textSecondary,
        ),
      ),
    );
  }
}

/// App-level strip under the chrome that tells the truth about the data on
/// screen. It reads [AppState.syncStatus]: hidden when live and fresh, a
/// quiet "Demo data" chip for sample data, and a warning strip with a Retry
/// action for offline, stale, permission and other sync problems.
class ConnectivityBanner extends StatelessWidget {
  const ConnectivityBanner({super.key, required this.lastSyncedAt});

  /// Kept for existing callers; falls back to the state's own value.
  final DateTime? lastSyncedAt;

  static String _ago(DateTime at) {
    final d = DateTime.now().difference(at);
    if (d.inMinutes < 1) return 'just now';
    if (d.inMinutes < 60) return '${d.inMinutes} min ago';
    if (d.inHours < 24) return '${d.inHours} h ago';
    return '${d.inDays} d ago';
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final synced = lastSyncedAt ?? state.lastSyncedAt;
    final status = state.syncStatus;

    Widget? content;
    if (state.dataSource == DataSource.demo) {
      content = _chip();
    } else {
      final savedNote = synced == null
          ? 'No sync yet'
          : 'Last synced ${_ago(synced)}';
      content = switch (status) {
        SyncStatus.live => null,
        SyncStatus.syncing => _strip(
            icon: Icons.sync_rounded,
            message: 'Syncing…',
            showRetry: false,
            state: state,
          ),
        SyncStatus.offline || SyncStatus.stale => _strip(
            icon: Icons.cloud_off_rounded,
            message: "You're offline — showing saved data",
            detail: savedNote,
            state: state,
          ),
        SyncStatus.signedOut => _strip(
            icon: Icons.lock_outline_rounded,
            message: 'Not signed in',
            showRetry: false,
            state: state,
          ),
        SyncStatus.permissionDenied => _strip(
            icon: Icons.block_rounded,
            message: "Can't load data: you don't have permission",
            state: state,
          ),
        SyncStatus.error => _strip(
            icon: Icons.error_outline_rounded,
            message: state.lastError?.message ??
                'Something went wrong while syncing.',
            detail: savedNote,
            state: state,
          ),
      };
    }

    return Semantics(
      liveRegion: true,
      child: AnimatedSize(
        duration: AppMotion.base,
        curve: AppMotion.enter,
        alignment: Alignment.topCenter,
        child: SizedBox(
          width: double.infinity,
          child: content ?? const SizedBox.shrink(),
        ),
      ),
    );
  }

  Widget _chip() {
    return Container(
      alignment: Alignment.centerLeft,
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.neutralSoft,
          borderRadius: BorderRadius.circular(AppRadii.full),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.science_outlined, size: 14, color: AppColors.neutral),
            const SizedBox(width: 6),
            Text(
              'Demo data',
              style: AppText.label(
                11.5,
                w: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _strip({
    required IconData icon,
    required String message,
    required AppState state,
    String? detail,
    bool showRetry = true,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      padding: const EdgeInsets.fromLTRB(12, 6, 4, 6),
      decoration: BoxDecoration(
        color: AppColors.warningContainer,
        borderRadius: BorderRadius.circular(AppRadii.sm),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.onWarningContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: AppText.label(
                    12,
                    w: FontWeight.w600,
                    color: AppColors.onWarningContainer,
                  ),
                ),
                if (detail != null)
                  Text(
                    detail,
                    style: AppText.body(
                      11,
                      color: AppColors.onWarningContainer,
                    ),
                  ),
              ],
            ),
          ),
          if (showRetry)
            TextButton(
              onPressed: () => state.refresh(),
              style: TextButton.styleFrom(
                minimumSize: const Size(44, 44),
                foregroundColor: AppColors.onWarningContainer,
              ),
              child: Text(
                'Retry',
                style: AppText.label(12, w: FontWeight.w700),
              ),
            ),
        ],
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

/// Bento quick-action tile (2x2 grid on Home): frosted, tinted, springy.
class BentoTile extends StatelessWidget {
  const BentoTile({
    super.key,
    required this.icon,
    required this.label,
    required this.tint,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color tint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: onTap,
      child: SizedBox(
        height: 96,
        child: FrostedCard(
          tint: tint.withValues(alpha: AppColors.isDark ? 0.18 : 0.12),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 26, color: tint),
              const Spacer(),
              Text(
                label,
                style: AppText.title(14, w: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Depth hero with ambient halo (one per screen).
class DepthHero extends StatelessWidget {
  const DepthHero({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: Transform.translate(
            offset: const Offset(0, 10),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadii.xl),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 32,
                    spreadRadius: -8,
                    offset: const Offset(0, 16),
                  ),
                ],
              ),
            ),
          ),
        ),
        GradientHero(
          animated: false,
          padding: padding,
          radius: AppRadii.xl,
          child: child,
        ),
      ],
    );
  }
}
