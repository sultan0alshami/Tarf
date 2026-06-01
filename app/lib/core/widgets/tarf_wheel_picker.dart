import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/tokens.dart';

/// One column of a [TarfWheelPicker]: a vertical drum of [values] (already
/// formatted strings) with the current [selected] index and an [onSelected]
/// callback, plus an optional trailing [separator] (e.g. ":") shown after it.
class TarfWheelColumn {
  const TarfWheelColumn({
    required this.values,
    required this.selected,
    required this.onSelected,
    this.separator,
    this.flex = 1,
  });

  final List<String> values;
  final int selected;
  final ValueChanged<int> onSelected;
  final String? separator;
  final int flex;
}

/// A calm drum/wheel picker in the Calm Sanctuary style: a translucent selection
/// pill sits behind the centered row, values are tabular and forced-LTR, and the
/// centered value is rendered in the accent color. Built on Flutter's
/// [ListWheelScrollView] — no third-party package. Used by the alarm editor
/// (hour · minute · AM/PM) and the timer (HH · MM · SS).
class TarfWheelPicker extends StatelessWidget {
  const TarfWheelPicker({
    super.key,
    required this.columns,
    this.itemExtent = 48,
    this.height = 196,
  });

  final List<TarfWheelColumn> columns;
  final double itemExtent;
  final double height;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final row = <Widget>[];
    for (final c in columns) {
      row.add(Expanded(
        flex: c.flex,
        child: _WheelColumn(column: c, itemExtent: itemExtent),
      ));
      if (c.separator != null) {
        row.add(Text(
          c.separator!,
          textDirection: TextDirection.ltr,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: scheme.onSurfaceVariant,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
        ));
      }
    }
    return SizedBox(
      height: height,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // The selection pill behind the centered row.
          IgnorePointer(
            child: Container(
              height: itemExtent,
              margin:
                  const EdgeInsets.symmetric(horizontal: TarfTokens.space4),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(TarfTokens.radiusM),
              ),
            ),
          ),
          // Clock faces never mirror: keep columns hour→minute→AM/PM in
          // reading order even under RTL (design.md §9).
          Directionality(
            textDirection: TextDirection.ltr,
            child: Row(children: row),
          ),
        ],
      ),
    );
  }
}

class _WheelColumn extends StatefulWidget {
  const _WheelColumn({required this.column, required this.itemExtent});

  final TarfWheelColumn column;
  final double itemExtent;

  @override
  State<_WheelColumn> createState() => _WheelColumnState();
}

class _WheelColumnState extends State<_WheelColumn> {
  late FixedExtentScrollController _controller;
  late int _current;

  @override
  void initState() {
    super.initState();
    _current = widget.column.selected;
    _controller = FixedExtentScrollController(initialItem: _current);
  }

  @override
  void didUpdateWidget(_WheelColumn old) {
    super.didUpdateWidget(old);
    // An external change (e.g. tapping a preset) animates the drum to it.
    if (widget.column.selected != _current &&
        widget.column.selected != old.column.selected) {
      _current = widget.column.selected;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _controller.hasClients) {
          _controller.animateToItem(
            _current,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListWheelScrollView.useDelegate(
      controller: _controller,
      itemExtent: widget.itemExtent,
      physics: const FixedExtentScrollPhysics(),
      diameterRatio: 1.6,
      perspective: 0.004,
      overAndUnderCenterOpacity: 0.45,
      onSelectedItemChanged: (i) {
        HapticFeedback.selectionClick();
        setState(() => _current = i);
        widget.column.onSelected(i);
      },
      childDelegate: ListWheelChildListDelegate(
        children: [
          for (var i = 0; i < widget.column.values.length; i++)
            Center(
              child: Text(
                widget.column.values[i],
                textDirection: TextDirection.ltr,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: i == _current ? scheme.primary : scheme.onSurface,
                      fontWeight:
                          i == _current ? FontWeight.w700 : FontWeight.w500,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
              ),
            ),
        ],
      ),
    );
  }
}
