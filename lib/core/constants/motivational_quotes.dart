import 'dart:math';

class MotivationalQuotes {
  const MotivationalQuotes._();

  static const es = [
    '¡Hoy es un buen día para no romper la racha! 🔥',
    'Un día más, un paso más hacia quien quieres ser.',
    'Tu yo del futuro te lo agradecerá.',
    'Pequeños pasos, grandes cambios. ¡Vamos!',
    'La consistencia gana al talento.',
    'No tiene que ser perfecto, solo tiene que pasar.',
    'Dos minutos ahora valen más que una hora mañana.',
    'Las rachas se construyen un día a la vez.',
    'Hazlo por ti. Te lo mereces.',
    'El momento perfecto es ahora.',
    'Cada marca cuenta. Suma una más.',
    'La disciplina de hoy es la libertad de mañana.',
    'Sigue apareciendo. Ahí está la magia.',
    'Lo difícil es lo que lo hace valioso.',
    'Un hábito a la vez, así se cambia una vida.',
  ];

  static const en = [
    "Today's a great day to keep the streak alive! 🔥",
    'One more day, one step closer to who you want to be.',
    'Your future self will thank you.',
    'Small steps, big changes. Let\'s go!',
    'Consistency beats talent.',
    "It doesn't have to be perfect, it just has to happen.",
    'Two minutes now beat an hour tomorrow.',
    'Streaks are built one day at a time.',
    'Do it for you. You deserve it.',
    'The perfect moment is now.',
    'Every mark counts. Add one more.',
    "Today's discipline is tomorrow's freedom.",
    'Keep showing up. That\'s where the magic is.',
    'The hard part is what makes it worth it.',
    'One habit at a time — that\'s how a life changes.',
  ];

  static final _random = Random();

  static String random(String lang) {
    final list = lang == 'es' ? es : en;
    return list[_random.nextInt(list.length)];
  }
}
