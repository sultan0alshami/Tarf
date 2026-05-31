import 'package:flutter/material.dart';

import '../../theme/tokens.dart';

/// Shared "Calm Sanctuary" building blocks (see design.md §5). These unify the
/// grouped-section, list-row, bento, slider, empty-state and pill-chip patterns
/// so every screen reads the same. All are RTL-correct (directional padding) and
/// theme-driven (light + dark) — never hard-coded colors.

/// A quiet section label shown above a [TarfGroup].
class TarfSectionHeader extends StatelessWidget {
  const TarfSectionHeader(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        TarfTokens.space2,
        TarfTokens.space4,
        TarfTokens.space2,
        TarfTokens.space2,
      ),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
      ),
    );
  }
}

/// A rounded tonal card grouping [children] with hairline dividers between them
/// (no divider before the first or after the last). Use with [TarfListRow].
class TarfGroup extends StatelessWidget {
  const TarfGroup({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i != 0) {
        rows.add(const Divider(
          height: 1,
          thickness: 1,
          indent: TarfTokens.space3,
          endIndent: TarfTokens.space3,
        ));
      }
      rows.add(children[i]);
    }
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(mainAxisSize: MainAxisSize.min, children: rows),
    );
  }
}

/// A grouped list row: optional leading [icon], a [title] (+ optional
/// [subtitle]), and a [trailing] control (toggle / value / chevron). At least
/// 56 tall; the whole row is tappable (≥44 hit) when [onTap] is set. Mirrors in
/// RTL automatically (leading → start, trailing → end).
class TarfListRow extends StatelessWidget {
  const TarfListRow({
    super.key,
    this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.titleColor,
    this.iconColor,
  });

  final IconData? icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? titleColor;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final content = Padding(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: TarfTokens.space3,
        vertical: 10,
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 22, color: iconColor ?? scheme.onSurfaceVariant),
            const SizedBox(width: TarfTokens.space3),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(color: titleColor ?? scheme.onSurface),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: TarfTokens.space3),
            trailing!,
          ],
        ],
      ),
    );
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 56),
      child: onTap == null ? content : InkWell(onTap: onTap, child: content),
    );
  }
}

/// Large tabular-figure numerals (timer / stopwatch / alarm). Forced LTR so the
/// numeral block never mirrors in RTL (a clock face does not flip).
class TarfTimeText extends StatelessWidget {
  const TarfTimeText(this.text, {super.key, this.style, this.color});

  final String text;
  final TextStyle? style;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final base = style ?? Theme.of(context).textTheme.displayLarge;
    return Text(
      text,
      textDirection: TextDirection.ltr,
      style: base?.copyWith(
        color: color,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}

/// A bento metric card: a big tabular [value] over a small [label].
class TarfMetricCard extends StatelessWidget {
  const TarfMetricCard({
    super.key,
    required this.value,
    required this.label,
    this.onTap,
  });

  final String value;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final inner = Padding(
      padding: const EdgeInsets.symmetric(
        vertical: TarfTokens.space3,
        horizontal: TarfTokens.space2,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
    return Card(
      child: onTap == null
          ? inner
          : InkWell(
              borderRadius: BorderRadius.circular(TarfTokens.radiusM),
              onTap: onTap,
              child: inner,
            ),
    );
  }
}

/// A tactile labeled slider row with a tabular value read-out. Fill grows from
/// the start edge (right in RTL) — Flutter's [Slider] handles directionality.
class TarfSliderTile extends StatelessWidget {
  const TarfSliderTile({
    super.key,
    required this.label,
    required this.valueLabel,
    required this.value,
    required this.min,
    required this.max,
    this.divisions,
    required this.onChanged,
  });

  final String label;
  final String valueLabel;
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        TarfTokens.space3,
        TarfTokens.space2,
        TarfTokens.space3,
        TarfTokens.space1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
              Text(
                valueLabel,
                textDirection: TextDirection.ltr,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w600,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
              ),
            ],
          ),
          Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: divisions,
            label: valueLabel,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

/// A calm empty state: a soft mark, a warm line, and (optionally) one primary
/// action — per design.md §5 ("Empty states").
class TarfEmptyState extends StatelessWidget {
  const TarfEmptyState({
    super.key,
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(TarfTokens.space5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: scheme.primary.withValues(alpha: 0.85)),
            const SizedBox(height: TarfTokens.space3),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: TarfTokens.space4),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

/// A pill preset chip (e.g. timer quick durations). Accent-filled + bold when
/// [selected]; tonal otherwise (never color-alone — weight changes too).
class TarfPresetChip extends StatelessWidget {
  const TarfPresetChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: selected ? scheme.primary : scheme.surfaceContainerHighest,
      shape: const StadiumBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(
            horizontal: TarfTokens.space4,
            vertical: TarfTokens.space2,
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: selected ? scheme.onPrimary : scheme.onSurfaceVariant,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
          ),
        ),
      ),
    );
  }
}
