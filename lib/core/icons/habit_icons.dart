import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Catálogo de iconos para hábitos, organizados por categorías.
/// Cada categoría es una lista de nombres; [all] resuelve nombre -> IconData.
class HabitIcons {
  const HabitIcons._();

  static const defaultIcon = 'target';

  static const Map<String, List<String>> categories = {
    'Fitness': [
      'dumbbell', 'bike', 'footprints', 'activity', 'heartPulse', 'mountain',
      'waves', 'timer', 'trophy', 'medal', 'award', 'flame', 'zap',
      'stretch', 'flag',
    ],
    'Study': [
      'book', 'bookOpen', 'graduationCap', 'pencil', 'pen', 'ruler',
      'calculator', 'microscope', 'brain', 'lightbulb', 'notebookPen',
      'library', 'languages', 'compass', 'telescope', 'atom',
    ],
    'Home': [
      'house', 'bed', 'bath', 'lamp', 'utensils', 'coffee', 'key',
      'hammer', 'wrench', 'trash', 'recycle', 'shirt', 'plug',
    ],
    'Mind': [
      'heart', 'smile', 'sun', 'moon', 'star', 'cloud', 'wind', 'leaf',
      'sparkles', 'flame', 'snowflake', 'music', 'sunrise',
    ],
    'Food': [
      'apple', 'salad', 'glassWater', 'droplet', 'coffee', 'pill',
      'egg', 'fish', 'carrot', 'cookie', 'utensils', 'wine', 'banana',
    ],
    'Work': [
      'briefcase', 'target', 'clock', 'calendarDays', 'mail', 'phone',
      'presentation', 'clipboardCheck', 'inbox', 'rocket', 'code',
      'chartBar', 'badge',
    ],
    'Social': [
      'users', 'handshake', 'messageCircle', 'gift', 'phone', 'mail',
      'heartHandshake', 'partyPopper', 'smile', 'userPlus',
    ],
    'Finance': [
      'dollar', 'piggyBank', 'trendingUp', 'coins', 'creditCard',
      'wallet', 'banknote', 'receipt', 'landmark', 'percent',
    ],
    'Nature': [
      'trees', 'sprout', 'leaf', 'flower', 'globe', 'recycle', 'sun',
      'cloudRain', 'mountain', 'waves', 'bird', 'tent',
    ],
    'Tech': [
      'laptop', 'smartphone', 'headphones', 'camera', 'gamepad',
      'code', 'terminal', 'bug', 'wifi', 'keyboard', 'monitor', 'database',
    ],
    'Art': [
      'palette', 'paintbrush', 'guitar', 'music', 'film', 'pen',
      'camera', 'mic', 'brush', 'scissors', 'image',
    ],
  };

  static const Map<String, IconData> all = {
    // Fitness
    'dumbbell': LucideIcons.dumbbell,
    'bike': LucideIcons.bike,
    'footprints': LucideIcons.footprints,
    'activity': LucideIcons.activity,
    'heartPulse': LucideIcons.heartPulse,
    'mountain': LucideIcons.mountain,
    'waves': LucideIcons.waves,
    'timer': LucideIcons.timer,
    'trophy': LucideIcons.trophy,
    'medal': LucideIcons.medal,
    'award': LucideIcons.award,
    'flame': LucideIcons.flame,
    'zap': LucideIcons.zap,
    'stretch': LucideIcons.stretchHorizontal,
    'flag': LucideIcons.flag,
    // Study
    'book': LucideIcons.book,
    'bookOpen': LucideIcons.bookOpen,
    'graduationCap': LucideIcons.graduationCap,
    'pencil': LucideIcons.pencil,
    'pen': LucideIcons.pen,
    'ruler': LucideIcons.ruler,
    'calculator': LucideIcons.calculator,
    'microscope': LucideIcons.microscope,
    'brain': LucideIcons.brain,
    'lightbulb': LucideIcons.lightbulb,
    'notebookPen': LucideIcons.notebookPen,
    'library': LucideIcons.library,
    'languages': LucideIcons.languages,
    'compass': LucideIcons.compass,
    'telescope': LucideIcons.telescope,
    'atom': LucideIcons.atom,
    // Home
    'house': LucideIcons.house,
    'bed': LucideIcons.bed,
    'bath': LucideIcons.bath,
    'lamp': LucideIcons.lamp,
    'utensils': LucideIcons.utensils,
    'coffee': LucideIcons.coffee,
    'key': LucideIcons.key,
    'hammer': LucideIcons.hammer,
    'wrench': LucideIcons.wrench,
    'trash': LucideIcons.trash2,
    'recycle': LucideIcons.recycle,
    'shirt': LucideIcons.shirt,
    'plug': LucideIcons.plug,
    // Mind
    'heart': LucideIcons.heart,
    'smile': LucideIcons.smile,
    'sun': LucideIcons.sun,
    'moon': LucideIcons.moon,
    'star': LucideIcons.star,
    'cloud': LucideIcons.cloud,
    'wind': LucideIcons.wind,
    'leaf': LucideIcons.leaf,
    'sparkles': LucideIcons.sparkles,
    'snowflake': LucideIcons.snowflake,
    'music': LucideIcons.music,
    'sunrise': LucideIcons.sunrise,
    // Food
    'apple': LucideIcons.apple,
    'salad': LucideIcons.salad,
    'glassWater': LucideIcons.glassWater,
    'droplet': LucideIcons.droplet,
    'pill': LucideIcons.pill,
    'egg': LucideIcons.egg,
    'fish': LucideIcons.fish,
    'carrot': LucideIcons.carrot,
    'cookie': LucideIcons.cookie,
    'wine': LucideIcons.wine,
    'banana': LucideIcons.banana,
    // Work
    'briefcase': LucideIcons.briefcase,
    'target': LucideIcons.target,
    'clock': LucideIcons.clock,
    'calendarDays': LucideIcons.calendarDays,
    'mail': LucideIcons.mail,
    'phone': LucideIcons.phone,
    'presentation': LucideIcons.presentation,
    'clipboardCheck': LucideIcons.clipboardCheck,
    'inbox': LucideIcons.inbox,
    'rocket': LucideIcons.rocket,
    'code': LucideIcons.code,
    'chartBar': LucideIcons.chartColumn,
    'badge': LucideIcons.badge,
    // Social
    'users': LucideIcons.users,
    'handshake': LucideIcons.handshake,
    'messageCircle': LucideIcons.messageCircle,
    'gift': LucideIcons.gift,
    'heartHandshake': LucideIcons.heartHandshake,
    'partyPopper': LucideIcons.partyPopper,
    'userPlus': LucideIcons.userPlus,
    // Finance
    'dollar': LucideIcons.dollarSign,
    'piggyBank': LucideIcons.piggyBank,
    'trendingUp': LucideIcons.trendingUp,
    'coins': LucideIcons.coins,
    'creditCard': LucideIcons.creditCard,
    'wallet': LucideIcons.wallet,
    'banknote': LucideIcons.banknote,
    'receipt': LucideIcons.receipt,
    'landmark': LucideIcons.landmark,
    'percent': LucideIcons.percent,
    // Nature
    'trees': LucideIcons.trees,
    'sprout': LucideIcons.sprout,
    'flower': LucideIcons.flower,
    'globe': LucideIcons.globe,
    'cloudRain': LucideIcons.cloudRain,
    'bird': LucideIcons.bird,
    'tent': LucideIcons.tent,
    // Tech
    'laptop': LucideIcons.laptop,
    'smartphone': LucideIcons.smartphone,
    'headphones': LucideIcons.headphones,
    'camera': LucideIcons.camera,
    'gamepad': LucideIcons.gamepad2,
    'terminal': LucideIcons.terminal,
    'bug': LucideIcons.bug,
    'wifi': LucideIcons.wifi,
    'keyboard': LucideIcons.keyboard,
    'monitor': LucideIcons.monitor,
    'database': LucideIcons.database,
    // Art
    'palette': LucideIcons.palette,
    'paintbrush': LucideIcons.paintbrush,
    'guitar': LucideIcons.guitar,
    'film': LucideIcons.film,
    'mic': LucideIcons.mic,
    'brush': LucideIcons.brush,
    'scissors': LucideIcons.scissors,
    'image': LucideIcons.image,
  };

  static List<String> get names => all.keys.toList();

  static IconData resolve(String name) => all[name] ?? all[defaultIcon]!;

  static bool isIcon(String name) => all.containsKey(name);
}
