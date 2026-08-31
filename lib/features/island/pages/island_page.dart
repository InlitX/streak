import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/i18n/l10n.dart';
import 'package:streak/core/routing/app_navigator.dart';
import 'package:streak/core/utils/app_snackbar.dart';
import 'package:streak/core/widgets/sheet_type.dart';
import 'package:streak/features/focus/state/focus_controller.dart';
import 'package:streak/features/habits/state/habits_controller.dart';
import 'package:streak/features/island/data/island_art.dart';
import 'package:streak/features/island/data/island_ledger.dart';
import 'package:streak/features/island/data/island_light.dart';
import 'package:streak/features/island/data/island_piece.dart';
import 'package:streak/features/island/state/island_controller.dart';
import 'package:streak/features/island/widgets/island_canvas.dart';
import 'package:streak/features/island/widgets/island_sheets.dart';
import 'package:streak/features/todos/state/todos_controller.dart';

class IslandPage extends StatefulWidget implements FullWidthPage {
  const IslandPage({super.key});

  @override
  State<IslandPage> createState() => _IslandPageState();
}

class _IslandPageState extends State<IslandPage> {
  final _canvas = GlobalKey<IslandCanvasState>();
  final _turn = ValueNotifier<int>(0);
  late final Future<IslandArt> _art = IslandArt.load();
  Timer? _clock;

  IslandLedger _ledger = IslandLedger.empty;

  @override
  void initState() {
    super.initState();
    _clock = Timer.periodic(
      const Duration(minutes: 5),
      (_) => setState(() {}),
    );
  }

  @override
  void dispose() {
    _clock?.cancel();
    _turn.dispose();
    super.dispose();
  }

  int get _balance => context.read<IslandController>().balanceFrom(_ledger);

  String _title(IslandController island) =>
      island.name.isEmpty ? context.l10n.island_default_name : island.name;

  Future<void> _rename() async {
    final island = context.read<IslandController>();
    final value = await showIslandNameSheet(context, _title(island));
    if (value != null) await island.rename(value);
  }

  Future<void> _pick(IslandPiece piece) async {
    final island = context.read<IslandController>();
    await showIslandPieceSheet(
      context,
      piece: piece,
      owned: island.owns(piece),
      balance: _balance,
      onBuy: () => _buy(piece),
    );
  }

  Future<void> _buy(IslandPiece piece) async {
    final island = context.read<IslandController>();
    if (island.owns(piece) || _balance < piece.price) return;
    await island.buy(piece);
    HapticFeedback.mediumImpact();
    _canvas.currentState?.reveal(piece);
    _canvas.currentState?.celebrate(piece);
    if (!mounted) return;
    AppSnackbar.success(
      context,
      context.l10n.island_placed(islandPieceName(context, piece)),
    );
  }

  Future<void> _openShop() async {
    final island = context.read<IslandController>();
    final piece = await showIslandShopSheet(
      context,
      owned: island.owned,
      balance: _balance,
    );
    if (piece == null || !mounted) return;
    _canvas.currentState?.reveal(piece);
    await _pick(piece);
  }

  @override
  Widget build(BuildContext context) {
    final island = context.watch<IslandController>();
    final habits = context.watch<HabitsController>();
    final focus = context.watch<FocusController>();
    final todos = context.watch<TodosController>();
    _ledger = island.ledgerFor(habits.habits, focus.sessions, todos.all);
    final balance = island.balanceFrom(_ledger);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        titleSpacing: 0,
        leading: const _Glass(child: BackButton()),
        title: Material(
          color: context.colors.surface.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: _rename,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 7, 12, 7),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      _title(island),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: sheetHeadingStyle(context, size: 16),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    LucideIcons.pencil,
                    size: 13,
                    color: context.tokens.muted,
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          _Glass(
            child: IconButton(
              icon: const Icon(LucideIcons.circleHelp),
              onPressed: () => showIslandHelpSheet(
                context,
                started: island.built > 0,
                onReset: context.read<IslandController>().reset,
              ),
            ),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: FutureBuilder<IslandArt>(
        future: _art,
        builder: (context, snapshot) {
          final art = snapshot.data;
          if (art == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return Stack(
            children: [
              Positioned.fill(
                child: IslandCanvas(
                  key: _canvas,
                  art: art,
                  owned: island.owned,
                  ghost: IslandLight.ghostFor(now, dark),
                  light: IslandLight.matrixFor(now),
                  turn: _turn,
                  onPick: _pick,
                ),
              ),
              Positioned(
                left: 12,
                right: 12,
                top: MediaQuery.paddingOf(context).top + 4,
                child: _Header(balance: balance, built: island.built),
              ),
              Positioned(
                left: 14,
                bottom: 18,
                child: SafeArea(
                  top: false,
                  child: _Compass(turn: _turn),
                ),
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: SafeArea(
                  top: false,
                  child: _Footer(
                    complete: island.complete,
                    empty: _ledger.earned == 0 && island.built == 0,
                    owned: island.owned,
                    balance: balance,
                    onShop: _openShop,
                    onPick: (piece) {
                      _canvas.currentState?.reveal(piece);
                      _pick(piece);
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Glass extends StatelessWidget {
  const _Glass({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: Material(
        color: context.colors.surface.withValues(alpha: 0.92),
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: child,
      ),
    );
  }
}

class _Compass extends StatelessWidget {
  const _Compass({required this.turn});

  final ValueNotifier<int> turn;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: turn,
      builder: (context, value, _) => Material(
        color: context.colors.surface.withValues(alpha: 0.92),
        shape: const CircleBorder(),
        elevation: 1,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () {
            HapticFeedback.selectionClick();
            turn.value = (value + 1) % 4;
          },
          child: SizedBox(
            width: 46,
            height: 46,
            child: AnimatedRotation(
              turns: value / 4,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              child: Icon(
                LucideIcons.navigation,
                size: 19,
                color: context.colors.primary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.balance, required this.built});

  final int balance;
  final int built;

  @override
  Widget build(BuildContext context) {
    final total = islandPieces.length;
    return Row(
      children: [
        _Pill(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.coins, size: 15, color: context.colors.primary),
              const SizedBox(width: 6),
              Text('$balance', style: sheetHeadingStyle(context, size: 15)),
            ],
          ),
        ),
        const Spacer(),
        _Pill(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$built/$total',
                style: sheetLabelStyle(context, size: 12),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 52,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: total == 0 ? 0 : built / total,
                    minHeight: 4,
                    backgroundColor: context.colors.surfaceContainerHighest,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
      decoration: BoxDecoration(
        color: context.colors.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(999),
      ),
      child: child,
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({
    required this.complete,
    required this.empty,
    required this.owned,
    required this.balance,
    required this.onShop,
    required this.onPick,
  });

  final bool complete;
  final bool empty;
  final Set<String> owned;
  final int balance;
  final VoidCallback onShop;
  final ValueChanged<IslandPiece> onPick;

  List<IslandPiece> get _next {
    final left = islandPieces.where((p) => !owned.contains(p.id)).toList()
      ..sort((a, b) => a.price.compareTo(b.price));
    final seen = <String>{};
    final out = <IslandPiece>[];
    for (final piece in left) {
      if (!seen.add(piece.kind)) continue;
      out.add(piece);
      if (out.length == 4) break;
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final next = complete || empty ? const <IslandPiece>[] : _next;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (next.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: context.colors.surface.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              complete ? context.l10n.island_complete : context.l10n.island_empty,
              textAlign: TextAlign.center,
              style: sheetBodyStyle(context, size: 12.5),
            ),
          )
        else
          SizedBox(
            height: 74,
            child: FittedBox(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < next.length; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    _NextChip(
                      piece: next[i],
                      affordable: balance >= next[i].price,
                      onTap: () => onPick(next[i]),
                    ),
                  ],
                ],
              ),
            ),
          ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: onShop,
          icon: const Icon(LucideIcons.store, size: 17),
          label: Text(
            context.l10n.island_shop,
            style: sheetActionStyle(context, size: 15),
          ),
          style: FilledButton.styleFrom(minimumSize: const Size(190, 48)),
        ),
      ],
    );
  }
}

class _NextChip extends StatelessWidget {
  const _NextChip({
    required this.piece,
    required this.affordable,
    required this.onTap,
  });

  final IslandPiece piece;
  final bool affordable;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.colors.surface.withValues(alpha: 0.92),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          width: 74,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: affordable
                  ? context.colors.primary.withValues(alpha: 0.45)
                  : context.colors.surfaceContainerHighest,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(child: IslandThumb(piece: piece, owned: true, size: 38)),
              const SizedBox(height: 2),
              IslandPrice(
                value: piece.price,
                tint: affordable ? context.colors.primary : context.tokens.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
