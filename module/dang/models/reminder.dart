class Reminder {
  String name;
  int amount;
  String unit;
  String time;
  bool afterMeal;
  bool beforeMeal;
  int duration;
  String durationUnit;

  Reminder({
    required this.name,
    required this.amount,
    required this.unit,
    required this.time,
    required this.afterMeal,
    required this.beforeMeal,
    required this.duration,
    required this.durationUnit,
  });
}
