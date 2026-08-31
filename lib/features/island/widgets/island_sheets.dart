import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:streak/app/theme/app_tokens.dart';
import 'package:streak/core/i18n/l10n.dart';
import 'package:streak/core/widgets/app_confirm_dialog.dart';
import 'package:streak/core/widgets/app_text_field.dart';
import 'package:streak/core/widgets/sheet_type.dart';
import 'package:streak/features/island/data/island_art.dart';
import 'package:streak/features/island/data/island_piece.dart';

String islandPieceName(BuildContext context, IslandPiece piece) {
  final name = islandKindName(context, piece.kind);
  final shade = islandShadeName(context, piece.art);
  return shade.isEmpty ? name : '$name · $shade';
}

String islandShadeName(BuildContext context, String art) {
  final parts = art.split('__');
  if (parts.length < 2) return '';
  return switch (parts[1]) {
    'teal' => context.l10n.island_t_teal,
    'clay' => context.l10n.island_t_clay,
    'white' => context.l10n.island_t_white,
    'coral' => context.l10n.island_t_coral,
    'lilac' => context.l10n.island_t_lilac,
    'autumn' => context.l10n.island_t_autumn,
    'deep' => context.l10n.island_t_deep,
    'silver' => context.l10n.island_t_silver,
    _ => '',
  };
}

String islandKindName(BuildContext context, String kind) {
  final l10n = context.l10n;
  return switch (kind) {
    'agave' => l10n.island_p_agave,
    'altar' => l10n.island_p_altar,
    'archway' => l10n.island_p_archway,
    'banner' => l10n.island_p_banner,
    'bench' => l10n.island_p_bench,
    'blue_railing' => l10n.island_p_blue_railing,
    'bougainvillea' => l10n.island_p_bougainvillea,
    'boulder' => l10n.island_p_boulder,
    'crate' => l10n.island_p_crate,
    'crop_patch' => l10n.island_p_crop_patch,
    'cube_house' => l10n.island_p_cube_house,
    'cypress' => l10n.island_p_cypress,
    'dry_grass' => l10n.island_p_dry_grass,
    'flat_stone' => l10n.island_p_flat_stone,
    'flower_pot' => l10n.island_p_flower_pot,
    'garden_bed' => l10n.island_p_garden_bed,
    'hanging_lantern' => l10n.island_p_hanging_lantern,
    'hay_bale' => l10n.island_p_hay_bale,
    'house' => l10n.island_p_house,
    'lantern_post' => l10n.island_p_lantern_post,
    'large_rock' => l10n.island_p_large_rock,
    'main_chapel' => l10n.island_p_main_chapel,
    'mossy_stone' => l10n.island_p_mossy_stone,
    'olive' => l10n.island_p_olive,
    'pebbles' => l10n.island_p_pebbles,
    'pergola_house' => l10n.island_p_pergola_house,
    'pottery_jar' => l10n.island_p_pottery_jar,
    'rocks' => l10n.island_p_rocks,
    'signpost' => l10n.island_p_signpost,
    'small_bridge' => l10n.island_p_small_bridge,
    'stone_basin' => l10n.island_p_stone_basin,
    'stone_lantern' => l10n.island_p_stone_lantern,
    'stone_pile' => l10n.island_p_stone_pile,
    'storage_box' => l10n.island_p_storage_box,
    'terrace_house' => l10n.island_p_terrace_house,
    'terracotta_pot' => l10n.island_p_terracotta_pot,
    'tower_chapel' => l10n.island_p_tower_chapel,
    'two_story' => l10n.island_p_two_story,
    'veg_garden' => l10n.island_p_veg_garden,
    'villa' => l10n.island_p_villa,
    'water_bucket' => l10n.island_p_water_bucket,
    'well' => l10n.island_p_well,
    'windmill' => l10n.island_p_windmill,
    'wood_pile' => l10n.island_p_wood_pile,
    _ => kind,
  };
}

String islandGroupName(BuildContext context, IslandGroup group) =>
    switch (group) {
      IslandGroup.pueblo => context.l10n.island_g_pueblo,
      IslandGroup.cala => context.l10n.island_g_cala,
      IslandGroup.huerta => context.l10n.island_g_huerta,
      IslandGroup.mirador => context.l10n.island_g_mirador,
      IslandGroup.terrazas => context.l10n.island_g_terrazas,
      IslandGroup.faro => context.l10n.island_g_faro,
      IslandGroup.puerto => context.l10n.island_g_puerto,
      IslandGroup.vega => context.l10n.island_g_vega,
      IslandGroup.astillero => context.l10n.island_g_astillero,
      IslandGroup.ermita => context.l10n.island_g_ermita,
      IslandGroup.caleta => context.l10n.island_g_caleta,
      IslandGroup.cabo => context.l10n.island_g_cabo,
      IslandGroup.molino => context.l10n.island_g_molino,
    };

class IslandThumb extends StatelessWidget {
  const IslandThumb({
    super.key,
    required this.piece,
    required this.owned,
    this.size = 44,
  });

  final IslandPiece piece;
  final bool owned;
  final double size;

  @override
  Widget build(BuildContext context) {
    final image = IslandArt.ready?.sprites[piece.art];
    if (image == null) return SizedBox(width: size, height: size);
    final art = RawImage(
      image: image,
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
    );
    if (owned) return art;
    return Opacity(
      opacity: 0.4,
      child: ColorFiltered(
        colorFilter: const ColorFilter.matrix([
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0, 0, 0, 1, 0,
        ]),
        child: art,
      ),
    );
  }
}

class IslandPrice extends StatelessWidget {
  const IslandPrice({super.key, required this.value, this.tint});

  final int value;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final color = tint ?? context.colors.primary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(LucideIcons.coins, size: 13, color: color),
        const SizedBox(width: 5),
        Text(
          '$value',
          style: sheetHeadingStyle(context, size: 14, color: color),
        ),
      ],
    );
  }
}

Future<void> showIslandPieceSheet(
  BuildContext context, {
  required IslandPiece piece,
  required bool owned,
  required int balance,
  required VoidCallback onBuy,
}) {
  final missing = piece.price - balance;
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheet) => SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IslandThumb(piece: piece, owned: owned, size: 72),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        islandPieceName(sheet, piece),
                        style: sheetTitleStyle(sheet),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        islandGroupName(sheet, piece.group),
                        style: sheetBodyStyle(sheet),
                      ),
                    ],
                  ),
                ),
                if (!owned) IslandPrice(value: piece.price),
              ],
            ),
            const SizedBox(height: 22),
            if (owned)
              _Done(label: sheet.l10n.island_done)
            else
              FilledButton(
                onPressed: missing > 0
                    ? null
                    : () {
                        Navigator.of(sheet).pop();
                        onBuy();
                      },
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
                child: Text(
                  missing > 0
                      ? sheet.l10n.island_need('$missing')
                      : sheet.l10n.island_build,
                  style: sheetActionStyle(sheet, size: 16),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

class _Done extends StatelessWidget {
  const _Done({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: context.tokens.success.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.check, size: 17, color: context.tokens.success),
          const SizedBox(width: 8),
          Text(
            label,
            style: sheetActionStyle(context, size: 15, color: context.tokens.success),
          ),
        ],
      ),
    );
  }
}

Future<IslandPiece?> showIslandShopSheet(
  BuildContext context, {
  required Set<String> owned,
  required int balance,
}) {
  return showModalBottomSheet<IslandPiece>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheet) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.78,
      maxChildSize: 0.94,
      builder: (inner, controller) => _Shop(
        owned: owned,
        balance: balance,
        controller: controller,
        onPick: (piece) => Navigator.of(sheet).pop(piece),
      ),
    ),
  );
}

class _Shop extends StatefulWidget {
  const _Shop({
    required this.owned,
    required this.balance,
    required this.controller,
    required this.onPick,
  });

  final Set<String> owned;
  final int balance;
  final ScrollController controller;
  final ValueChanged<IslandPiece> onPick;

  @override
  State<_Shop> createState() => _ShopState();
}

class _ShopState extends State<_Shop> {
  IslandGroup _group = IslandGroup.values.first;
  bool _affordable = false;

  @override
  Widget build(BuildContext context) {
    var lots = islandShopLots(_group, widget.owned);
    if (_affordable) {
      lots = lots
          .where((lot) => !lot.done && widget.balance >= lot.next.price)
          .toList();
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
          child: SheetTitle(
            context.l10n.island_shop,
            trailing: IslandPrice(value: widget.balance),
          ),
        ),
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: IslandGroup.values.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final group = IslandGroup.values[i];
              final all = islandGroupPieces(group);
              final built = all.where((p) => widget.owned.contains(p.id)).length;
              return _Chip(
                label: islandGroupName(context, group),
                detail: '$built/${all.length}',
                active: group == _group,
                onTap: () => setState(() => _group = group),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 10, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  context.l10n.island_only_affordable,
                  style: sheetBodyStyle(context, size: 13),
                ),
              ),
              Switch(
                value: _affordable,
                onChanged: (value) => setState(() => _affordable = value),
              ),
            ],
          ),
        ),
        Expanded(
          child: lots.isEmpty
              ? Center(
                  child: Text(
                    context.l10n.island_nothing_here,
                    style: sheetBodyStyle(context),
                  ),
                )
              : GridView.builder(
                  controller: widget.controller,
                  padding: const EdgeInsets.fromLTRB(14, 4, 14, 28),
                  gridDelegate:
                      const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 132,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: lots.length,
                  itemBuilder: (_, i) => _ShopTile(
                    lot: lots[i],
                    affordable: widget.balance >= lots[i].next.price,
                    onTap: () => widget.onPick(lots[i].next),
                  ),
                ),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.detail,
    required this.active,
    required this.onTap,
  });

  final String label;
  final String detail;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tone = active ? context.colors.onPrimary : context.colors.onSurface;
    return Material(
      color: active
          ? context.colors.primary
          : context.colors.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              Text(label, style: sheetOptionStyle(context, size: 14, color: tone)),
              const SizedBox(width: 7),
              Text(
                detail,
                style: sheetLabelStyle(
                  context,
                  size: 11,
                  color: tone.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class IslandLot {
  const IslandLot(this.next, this.built, this.total, this.done);

  final IslandPiece next;
  final int built;
  final int total;
  final bool done;
}

List<IslandLot> islandShopLots(IslandGroup group, Set<String> owned) {
  final lots = <String, List<IslandPiece>>{};
  for (final piece in islandGroupPieces(group)) {
    lots.putIfAbsent(piece.art, () => []).add(piece);
  }
  final out = <IslandLot>[];
  for (final pieces in lots.values) {
    final built = pieces.where((p) => owned.contains(p.id)).length;
    final left = pieces.where((p) => !owned.contains(p.id));
    out.add(IslandLot(
      left.isEmpty ? pieces.first : left.first,
      built,
      pieces.length,
      left.isEmpty,
    ));
  }
  out.sort((a, b) {
    if (a.done != b.done) return a.done ? 1 : -1;
    return a.next.price.compareTo(b.next.price);
  });
  return out;
}

class _ShopTile extends StatelessWidget {
  const _ShopTile({
    required this.lot,
    required this.affordable,
    required this.onTap,
  });

  final IslandLot lot;
  final bool affordable;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.colors.surfaceContainerHighest.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
          child: Column(
            children: [
              Expanded(
                child: IslandThumb(
                  piece: lot.next,
                  owned: lot.built > 0,
                  size: 58,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                islandPieceName(context, lot.next),
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: sheetOptionStyle(context, size: 12, selected: lot.done),
              ),
              const SizedBox(height: 4),
              if (lot.done)
                Icon(LucideIcons.check, size: 16, color: context.tokens.success)
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IslandPrice(
                      value: lot.next.price,
                      tint: affordable
                          ? context.colors.primary
                          : context.tokens.muted,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${lot.built}/${lot.total}',
                      style: sheetLabelStyle(context, size: 10),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<String?> showIslandNameSheet(BuildContext context, String current) {
  final field = TextEditingController(text: current);
  return showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheet) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(sheet).viewInsets.bottom),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SheetTitle(sheet.l10n.island_rename),
              const SizedBox(height: 16),
              AppTextField(controller: field, autofocus: true),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.of(sheet).pop(field.text),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
                child: Text(
                  sheet.l10n.save,
                  style: sheetActionStyle(sheet, size: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Future<void> showIslandHelpSheet(
  BuildContext context, {
  required bool started,
  required VoidCallback onReset,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheet) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.8,
      maxChildSize: 0.94,
      builder: (inner, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
        children: [
          SheetTitle(sheet.l10n.island_how),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: ColoredBox(
              color: const Color(0xFF9FD8EE),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Image.asset(
                  'assets/island/preview.webp',
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.medium,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            sheet.l10n.island_goal,
            textAlign: TextAlign.center,
            style: sheetBodyStyle(sheet, size: 12.5),
          ),
          const SizedBox(height: 20),
          _Rule(icon: LucideIcons.check, text: sheet.l10n.island_how_check),
          _Rule(icon: LucideIcons.timer, text: sheet.l10n.island_how_focus),
          _Rule(icon: LucideIcons.sparkles, text: sheet.l10n.island_how_perfect),
          _Rule(icon: LucideIcons.listChecks, text: sheet.l10n.island_how_todo),
          _Rule(icon: LucideIcons.flame, text: sheet.l10n.island_how_streak),
          _Rule(icon: LucideIcons.hand, text: sheet.l10n.island_zoom_hint),
          const SizedBox(height: 8),
          Text(sheet.l10n.island_how_note, style: sheetBodyStyle(sheet)),
          const SizedBox(height: 16),
          _Beta(text: sheet.l10n.island_beta),
          if (started) ...[
            const SizedBox(height: 14),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton(
                onPressed: () async {
                  final yes = await showAppConfirmDialog(
                    sheet,
                    title: sheet.l10n.island_reset,
                    message: sheet.l10n.island_reset_sub,
                    confirmLabel: sheet.l10n.island_reset_go,
                    icon: LucideIcons.rotateCcw,
                  );
                  if (yes != true || !sheet.mounted) return;
                  Navigator.of(sheet).pop();
                  onReset();
                },
                child: Text(
                  sheet.l10n.island_reset,
                  style: sheetActionStyle(
                    sheet,
                    size: 14,
                    color: sheet.tokens.danger,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

class _Beta extends StatelessWidget {
  const _Beta({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.flaskConical,
                size: 15,
                color: context.colors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Beta',
                style: sheetHeadingStyle(
                  context,
                  size: 13,
                  color: context.colors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(text, style: sheetBodyStyle(context, size: 13)),
        ],
      ),
    );
  }
}

class _Rule extends StatelessWidget {
  const _Rule({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: context.colors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: context.colors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(text, style: sheetOptionStyle(context, size: 15)),
            ),
          ),
        ],
      ),
    );
  }
}
