import 'dart:io';

import 'package:flutter/material.dart';

import '../controllers/app_state.dart';
import '../theme/daylog_theme.dart';
import 'fullscreen_image_viewer.dart';

/// The ribbon. Above the fold: what happened. The fold: now. Below: what
/// is planned, as hollow stitches on a dotted rail. Tap a ghost to fill it.
class TimeRibbonTimeline extends StatefulWidget {
  const TimeRibbonTimeline({
    super.key,
    required this.events,
    required this.showNow,
    required this.onTapEvent,
    required this.onLongPressEvent,
    required this.onCompleteGhost,
  });

  final List<EventView> events;
  final bool showNow;
  final void Function(EventView) onTapEvent;
  final void Function(EventView) onLongPressEvent;
  final void Function(EventView) onCompleteGhost;

  @override
  State<TimeRibbonTimeline> createState() => _TimeRibbonTimelineState();
}

class _TimeRibbonTimelineState extends State<TimeRibbonTimeline> {
  final _scroll = ScrollController();
  final _foldKey = GlobalKey();
  int _eventCount = 0;

  @override
  void initState() {
    super.initState();
    _eventCount = widget.events.length;
    WidgetsBinding.instance.addPostFrameCallback((_) => _toFold(immediate: true));
  }

  @override
  void didUpdateWidget(TimeRibbonTimeline old) {
    super.didUpdateWidget(old);
    final n = widget.events.length;
    if (n != _eventCount) {
      _eventCount = n;
      WidgetsBinding.instance.addPostFrameCallback((_) => _toFold());
    }
  }

  /// Scroll so the fold sits in the lower third: past fills the screen,
  /// the first ghost or two peek in below.
  void _toFold({bool immediate = false}) {
    if (!mounted) return;
    final ctx = _foldKey.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(ctx,
          alignment: 0.68,
          duration: immediate || reducedMotion(context) ? Duration.zero : const Duration(milliseconds: 260),
          curve: Curves.easeOut);
      return;
    }
    if (_scroll.hasClients && _scroll.position.hasContentDimensions) {
      _scroll.jumpTo(_scroll.position.maxScrollExtent);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final c2 = _foldKey.currentContext;
        if (c2 != null) {
          Scrollable.ensureVisible(c2,
              alignment: 0.68,
              duration: immediate || reducedMotion(context) ? Duration.zero : const Duration(milliseconds: 260),
              curve: Curves.easeOut);
        }
      });
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dl = Dl.of(context);
    final now = DateTime.now();
    final past = widget.events.where((e) => e.isDone || e.status == 'skipped').toList();
    final future = widget.events.where((e) => e.isGhost).toList();

    if (past.isEmpty && future.isEmpty) return const _EmptyDay();

    final items = <_Row>[
      for (final e in past) _Row.event(e),
      if (widget.showNow) _Row.fold(now),
      for (final e in future) _Row.event(e),
    ];

    return ListView.builder(
      controller: _scroll,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.fromLTRB(dl.x5, dl.x2, dl.x5, dl.x8),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final it = items[i];
        final prev = i > 0 ? items[i - 1] : null;
        final next = i < items.length - 1 ? items[i + 1] : null;
        if (it.isFold) {
          return _FoldRow(key: _foldKey, time: it.time, prev: prev?.time, next: next?.time);
        }
        final e = it.event!;
        return _EventRow(
          event: e,
          prevTime: prev?.time,
          nextTime: next?.time,
          onTap: e.isGhost ? () => widget.onCompleteGhost(e) : () => widget.onTapEvent(e),
          onLongPress: () => widget.onLongPressEvent(e),
        );
      },
    );
  }
}

class _Row {
  _Row.event(this.event)
      : isFold = false,
        time = event!.local;
  _Row.fold(this.time)
      : isFold = true,
        event = null;
  final EventView? event;
  final bool isFold;
  final DateTime time;
}

const double _timeCol = 50;
const double _railW = 20;
const double _stitchY = 21;

class _EventRow extends StatefulWidget {
  const _EventRow({
    required this.event,
    required this.prevTime,
    required this.nextTime,
    required this.onTap,
    required this.onLongPress,
  });
  final EventView event;
  final DateTime? prevTime, nextTime;
  final VoidCallback onTap, onLongPress;

  @override
  State<_EventRow> createState() => _EventRowState();
}

class _EventRowState extends State<_EventRow> {
  bool _noteOpen = false;

  @override
  Widget build(BuildContext context) {
    final dl = Dl.of(context);
    final theme = Theme.of(context);
    final e = widget.event;
    final ghost = e.isGhost;
    final skipped = e.status == 'skipped';
    final hue = arcColorFor(e.local);
    final soft = theme.colorScheme.onSurfaceVariant;
    final faint = theme.brightness == Brightness.dark ? DlColors.inkFaintDark : DlColors.inkFaint;
    final hh = e.local.hour.toString().padLeft(2, '0');
    final mm = e.local.minute.toString().padLeft(2, '0');
    final textColor = ghost || skipped ? soft : theme.colorScheme.onSurface;

    return InkWell(
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: _timeCol,
              child: Padding(
                padding: EdgeInsets.only(top: dl.x3 + 1),
                child: Text(ghost ? '~$hh:$mm' : '$hh:$mm',
                    style: DlType.mono(context, size: 12.5, color: ghost ? faint : null)),
              ),
            ),
            CustomPaint(
              size: const Size(_railW, double.infinity),
              painter: _RailPainter(
                hue: ghost ? faint : hue,
                topHue: widget.prevTime == null ? null : (ghost ? faint : _mid(e.local, widget.prevTime!)),
                bottomHue: widget.nextTime == null ? null : (ghost ? faint : _mid(e.local, widget.nextTime!)),
                hollow: ghost,
                struck: skipped,
                dotted: ghost,
              ),
            ),
            SizedBox(width: dl.x3),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: dl.x3),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(e.rawText,
                        style: theme.textTheme.bodyLarge!.copyWith(
                          color: textColor,
                          decoration: skipped ? TextDecoration.lineThrough : null,
                          decorationColor: faint,
                        )),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        if (e.keyName != null)
                          Text(e.keyName!,
                              style: theme.textTheme.bodySmall!
                                  .copyWith(color: ghost ? faint : hue, fontWeight: FontWeight.w600))
                        else if (!ghost)
                          Text('unfiled · tap to file',
                              style: theme.textTheme.bodySmall!.copyWith(color: soft, fontStyle: FontStyle.italic)),
                        if (ghost) ...[
                          if (e.keyName != null) Text('  ·  ', style: theme.textTheme.bodySmall),
                          Text('planned · tap when done',
                              style: theme.textTheme.bodySmall!.copyWith(color: faint)),
                        ],
                        if (e.numbers.isNotEmpty) ...[
                          Text('  ·  ', style: theme.textTheme.bodySmall),
                          Text(e.numbers, style: DlType.mono(context, size: 11.5)),
                        ],
                        if (e.modality == 'voice') ...[
                          const SizedBox(width: 6),
                          Icon(Icons.mic_none, size: 13, color: soft),
                        ],
                        if (e.note != null && e.note!.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: () => setState(() => _noteOpen = !_noteOpen),
                            child: Icon(_noteOpen ? Icons.expand_less : Icons.notes, size: 15, color: soft),
                          ),
                        ],
                      ],
                    ),
                    if (_noteOpen && e.note != null) ...[
                      SizedBox(height: dl.x2),
                      Text(e.note!, style: theme.textTheme.bodyMedium!.copyWith(color: soft, height: 1.5)),
                    ],
                    if (e.hasPhoto) ...[
                      SizedBox(height: dl.x2),
                      GestureDetector(
                        onTap: () => FullscreenImageViewer.show(context,
                            imagePath: e.photoPath!,
                            caption: e.rawText,
                            tag: e.keyName,
                            time: '$hh:$mm',
                            calories: e.calories),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(Dl.radiusSmall),
                          child: Image.file(File(e.photoPath!),
                              height: 120, width: double.infinity, fit: BoxFit.cover, cacheWidth: 600),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Color _mid(DateTime a, DateTime b) {
    final half = Duration(minutes: a.difference(b).inMinutes.abs() ~/ 2);
    return arcColorFor(a.isAfter(b) ? a.subtract(half) : a.add(half));
  }
}

class _FoldRow extends StatefulWidget {
  const _FoldRow({super.key, required this.time, this.prev, this.next});
  final DateTime time;
  final DateTime? prev, next;
  @override
  State<_FoldRow> createState() => _FoldRowState();
}

class _FoldRowState extends State<_FoldRow> with SingleTickerProviderStateMixin {
  late final _breath = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (reducedMotion(context)) {
      _breath.stop();
      _breath.value = 1;
    } else if (!_breath.isAnimating) {
      _breath.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _breath.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hue = arcColorFor(widget.time);
    final faint = theme.brightness == Brightness.dark ? DlColors.inkFaintDark : DlColors.inkFaint;
    final hh = widget.time.hour.toString().padLeft(2, '0');
    final mm = widget.time.minute.toString().padLeft(2, '0');
    return SizedBox(
      height: 40,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: _timeCol,
            child: Center(child: Text('$hh:$mm', style: DlType.mono(context, size: 12.5, color: hue))),
          ),
          FadeTransition(
            opacity: Tween(begin: 0.5, end: 1.0).animate(_breath),
            child: CustomPaint(
              size: const Size(_railW, double.infinity),
              painter: _RailPainter(
                hue: hue,
                topHue: widget.prev == null ? null : hue,
                bottomHue: widget.next == null ? null : faint,
                pulse: true,
                dottedBelow: true,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Row(children: [
              Text('now', style: theme.textTheme.bodySmall!.copyWith(color: hue, fontWeight: FontWeight.w600)),
              const SizedBox(width: 10),
              Expanded(child: Divider(color: hue.withValues(alpha: 0.35))),
            ]),
          ),
        ],
      ),
    );
  }
}

class _RailPainter extends CustomPainter {
  _RailPainter({
    required this.hue,
    this.topHue,
    this.bottomHue,
    this.hollow = false,
    this.struck = false,
    this.dotted = false,
    this.dottedBelow = false,
    this.pulse = false,
  });
  final Color hue;
  final Color? topHue, bottomHue;
  final bool hollow, struck, dotted, dottedBelow, pulse;

  @override
  void paint(Canvas canvas, Size size) {
    final x = size.width / 2;
    final y = pulse ? size.height / 2 : _stitchY;
    final r = pulse ? 5.0 : 3.5;

    void seg(double y0, double y1, Color a, Color b, bool dot) {
      final p = Paint()
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [a, b])
            .createShader(Rect.fromLTRB(x - 1, y0, x + 1, y1));
      if (!dot) {
        canvas.drawLine(Offset(x, y0), Offset(x, y1), p);
      } else {
        for (var yy = y0; yy < y1; yy += 7) {
          canvas.drawLine(Offset(x, yy), Offset(x, (yy + 3).clamp(y0, y1)), p);
        }
      }
    }

    if (topHue != null) seg(0, y - r - 2, topHue!, hue, dotted);
    if (bottomHue != null) seg(y + r + 2, size.height, hue, bottomHue!, dotted || dottedBelow);

    if (hollow) {
      canvas.drawCircle(Offset(x, y), r, Paint()..color = hue..style = PaintingStyle.stroke..strokeWidth = 1.5);
    } else {
      canvas.drawCircle(Offset(x, y), r, Paint()..color = hue);
    }
    if (struck) {
      canvas.drawLine(Offset(x - 5, y + 5), Offset(x + 5, y - 5), Paint()..color = hue..strokeWidth = 1.5);
    }
    if (pulse) {
      canvas.drawCircle(Offset(x, y), 9,
          Paint()..color = hue.withValues(alpha: 0.25)..style = PaintingStyle.stroke..strokeWidth = 2);
    }
  }

  @override
  bool shouldRepaint(_RailPainter o) =>
      o.hue != hue || o.topHue != topHue || o.bottomHue != bottomHue || o.hollow != hollow || o.struck != struck;
}

class _EmptyDay extends StatelessWidget {
  const _EmptyDay();
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dl = Dl.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(dl.x5 + _timeCol + _railW + dl.x3, dl.x6, dl.x5, dl.x8),
      child: Text('Nothing here yet.\nTap Up when you wake, or write one line.',
          style: theme.textTheme.bodyMedium!.copyWith(color: theme.colorScheme.onSurfaceVariant, height: 1.5)),
    );
  }
}
