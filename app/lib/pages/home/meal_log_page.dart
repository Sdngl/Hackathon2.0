import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../theme/apptheme.dart';

class MealLogPage extends StatefulWidget {
  const MealLogPage({super.key});

  @override
  State<MealLogPage> createState() => _MealLogPageState();
}

class _MealLogPageState extends State<MealLogPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  DateTime _selectedDate = DateTime.now();
  bool _loading = true;

  List<_MealEntry> _meals = [];

  int _dailyCalorieGoal = 0;

  @override
  void initState() {
    super.initState();
    _loadMeals();
  }

  Future<void> _loadMeals() async {
    final user = _auth.currentUser;

    if (user == null) {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
      return;
    }

    try {
      final userRef = _firestore.collection('users').doc(user.uid);

      final results = await Future.wait([
        userRef.get(),
        userRef.collection('meals').get(),
      ]);

      final userSnapshot =
      results[0] as DocumentSnapshot<Map<String, dynamic>>;
      final mealSnapshot =
      results[1] as QuerySnapshot<Map<String, dynamic>>;

      final userData = userSnapshot.data() ?? <String, dynamic>{};

      final dailyGoal =
          _asInt(userData['dailyCalorieGoal']) ??
              _asInt(userData['daily_calorie_goal']) ??
              0;

      final selectedStart = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
      );

      final selectedEnd = selectedStart.add(
        const Duration(days: 1),
      );

      final meals = <_MealEntry>[];

      for (final doc in mealSnapshot.docs) {
        final data = doc.data();

        final createdAt = _toDateTime(
          data['createdAt'],
        );

        if (createdAt == null) {
          continue;
        }

        if (createdAt.isBefore(selectedStart) ||
            !createdAt.isBefore(selectedEnd)) {
          continue;
        }

        final analysisRaw = data['analysis'];

        if (analysisRaw is! Map) {
          continue;
        }

        final analysis =
        Map<String, dynamic>.from(
          analysisRaw,
        );

        meals.add(
          _MealEntry.fromFirestore(
            id: doc.id,
            rawData: data,
            analysis: analysis,
            createdAt: createdAt,
          ),
        );
      }

      meals.sort(
            (a, b) =>
            b.createdAt.compareTo(
              a.createdAt,
            ),
      );

      if (!mounted) return;

      setState(() {
        _dailyCalorieGoal = dailyGoal;
        _meals = meals;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Could not load meal log: $e',
          ),
        ),
      );
    }
  }

  DateTime? _toDateTime(
      dynamic value,
      ) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    return null;
  }

  int? _asInt(
      dynamic value,
      ) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.round();
    }

    if (value == null) {
      return null;
    }

    return int.tryParse(
      value.toString(),
    );
  }

  int get _totalCalories {
    return _meals.fold(
      0,
          (
          total,
          meal,
          ) =>
      total +
          meal.calories.round(),
    );
  }

  double get _totalProtein {
    return _meals.fold(
      0,
          (
          total,
          meal,
          ) =>
      total + meal.protein,
    );
  }

  double get _totalCarbs {
    return _meals.fold(
      0,
          (
          total,
          meal,
          ) =>
      total + meal.carbs,
    );
  }

  double get _totalFat {
    return _meals.fold(
      0,
          (
          total,
          meal,
          ) =>
      total + meal.fat,
    );
  }

  List<DateTime> get _weekDates {
    final selected =
        _selectedDate;

    final monday =
    selected.subtract(
      Duration(
        days:
        selected.weekday - 1,
      ),
    );

    return List.generate(
      7,
          (index) =>
          DateTime(
            monday.year,
            monday.month,
            monday.day + index,
          ),
    );
  }

  void _selectDate(
      DateTime date,
      ) {
    setState(() {
      _selectedDate = date;
      _loading = true;
    });

    _loadMeals();
  }

  bool _isSameDay(
      DateTime a,
      DateTime b,
      ) {
    return a.year == b.year &&
        a.month == b.month &&
        a.day == b.day;
  }

  Future<void> _openDatePicker() async {
    final picked =
    await showDatePicker(
      context: context,
      initialDate:
      _selectedDate,
      firstDate:
      DateTime(2024),
      lastDate:
      DateTime.now(),
    );

    if (picked == null) {
      return;
    }

    _selectDate(picked);
  }

  String _dayLetter(
      DateTime date,
      ) {
    const labels = [
      'M',
      'T',
      'W',
      'T',
      'F',
      'S',
      'S',
    ];

    return labels[
    date.weekday - 1];
  }

  @override
  Widget build(
      BuildContext context,
      ) {
    final latestMeal =
    _meals.isEmpty
        ? null
        : _meals.first;

    return Scaffold(
      backgroundColor:
      AppColors.background,
      appBar: AppBar(
        backgroundColor:
        AppColors.background,
        elevation: 0,
        centerTitle: true,
        leadingWidth: 72,
        leading: Padding(
          padding:
          const EdgeInsets.only(
            left: 20,
          ),
          child: Material(
            color: Colors.white,
            shape:
            const CircleBorder(),
            child: InkWell(
              customBorder:
              const CircleBorder(),
              onTap: () =>
                  Navigator.of(
                    context,
                  ).pop(),
              child:
              const SizedBox(
                width: 44,
                height: 44,
                child: Icon(
                  Icons
                      .arrow_back_rounded,
                  color:
                  AppColors
                      .textDark,
                ),
              ),
            ),
          ),
        ),
        title: const Text(
          'Meal log',
          style: TextStyle(
            fontSize: 19,
            fontWeight:
            FontWeight.w800,
            color:
            AppColors.textDark,
          ),
        ),
        actions: [
          Padding(
            padding:
            const EdgeInsets.only(
              right: 20,
            ),
            child: Material(
              color: Colors.white,
              shape:
              const CircleBorder(),
              child: InkWell(
                customBorder:
                const CircleBorder(),
                onTap:
                _openDatePicker,
                child:
                const SizedBox(
                  width: 44,
                  height: 44,
                  child: Icon(
                    Icons
                        .filter_list_rounded,
                    color:
                    AppColors
                        .textDark,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(
        child:
        CircularProgressIndicator(),
      )
          : RefreshIndicator(
        onRefresh: _loadMeals,
        child:
        SingleChildScrollView(
          physics:
          const AlwaysScrollableScrollPhysics(),
          padding:
          const EdgeInsets.fromLTRB(
            20,
            10,
            20,
            40,
          ),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment
                .start,
            children: [
              _WeekSelector(
                dates:
                _weekDates,
                selectedDate:
                _selectedDate,
                dayLetter:
                _dayLetter,
                isSameDay:
                _isSameDay,
                onSelect:
                _selectDate,
              ),

              const SizedBox(
                height: 16,
              ),

              _DailySummaryCard(
                calories:
                _totalCalories,
                goal:
                _dailyCalorieGoal,
                protein:
                _totalProtein,
                carbs:
                _totalCarbs,
                fat:
                _totalFat,
              ),

              if (latestMeal !=
                  null) ...[
                const SizedBox(
                  height: 16,
                ),

                _LatestMealCard(
                  meal:
                  latestMeal,
                ),
              ],

              const SizedBox(
                height: 20,
              ),

              const Text(
                'Meals',
                style:
                TextStyle(
                  fontSize:
                  18,
                  fontWeight:
                  FontWeight
                      .w800,
                  color:
                  AppColors
                      .textDark,
                ),
              ),

              const SizedBox(
                height: 12,
              ),

              if (_meals
                  .isEmpty)
                const _EmptyMealsCard()
              else
                _MealListCard(
                  meals:
                  _meals,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MealEntry {
  final String id;
  final String name;
  final String mealType;
  final String? imageBase64;

  final double calories;
  final double protein;
  final double carbs;
  final double fat;

  final List<String> tags;

  final DateTime createdAt;

  const _MealEntry({
    required this.id,
    required this.name,
    required this.mealType,
    required this.imageBase64,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.tags,
    required this.createdAt,
  });

  factory _MealEntry
      .fromFirestore({
    required String id,
    required Map<String, dynamic>
    rawData,
    required Map<String, dynamic>
    analysis,
    required DateTime createdAt,
  }) {
    final nutritionRaw =
    analysis['nutrition'];

    final nutrition =
    nutritionRaw is Map
        ? Map<String, dynamic>.from(
      nutritionRaw,
    )
        : <String, dynamic>{};

    final name =
        _firstString([
          analysis['meal_name'],
          analysis['name'],
          analysis['title'],
          analysis['dish_name'],
          analysis['food_name'],
        ]) ??
            'Scanned meal';

    final type =
        _firstString([
          analysis['meal_type'],
          analysis['mealType'],
          rawData['mealType'],
          rawData['meal_type'],
        ]) ??
            _mealTypeFromTime(
              createdAt,
            );

    final tags =
    _extractTags(
      analysis,
    );

    return _MealEntry(
      id: id,
      name: name,
      mealType: type,
      imageBase64:
      rawData['imageBase64']
          ?.toString(),
      calories:
      _extractNumber(
        nutrition,
        analysis,
        const [
          'estimated_calories_kcal',
          'calories_kcal',
          'calories',
          'estimatedCalories',
        ],
      ),
      protein:
      _extractNumber(
        nutrition,
        analysis,
        const [
          'protein_g',
          'protein',
          'estimated_protein_g',
        ],
      ),
      carbs:
      _extractNumber(
        nutrition,
        analysis,
        const [
          'carbs_g',
          'carbohydrates_g',
          'carbs',
          'carbohydrates',
        ],
      ),
      fat:
      _extractNumber(
        nutrition,
        analysis,
        const [
          'fat_g',
          'fat',
          'estimated_fat_g',
        ],
      ),
      tags: tags,
      createdAt: createdAt,
    );
  }

  static String? _firstString(
      List<dynamic> values,
      ) {
    for (final value in values) {
      final text =
      value
          ?.toString()
          .trim();

      if (text != null &&
          text.isNotEmpty &&
          text.toLowerCase() !=
              'null') {
        return text;
      }
    }

    return null;
  }

  static double _extractNumber(
      Map<String, dynamic> nutrition,
      Map<String, dynamic> analysis,
      List<String> keys,
      ) {
    for (final key in keys) {
      final value =
      nutrition[key];

      if (value is num) {
        return value.toDouble();
      }

      if (value != null) {
        final parsed =
        double.tryParse(
          value.toString(),
        );

        if (parsed != null) {
          return parsed;
        }
      }
    }

    for (final key in keys) {
      final value =
      analysis[key];

      if (value is num) {
        return value.toDouble();
      }

      if (value != null) {
        final parsed =
        double.tryParse(
          value.toString(),
        );

        if (parsed != null) {
          return parsed;
        }
      }
    }

    return 0;
  }

  static List<String> _extractTags(
      Map<String, dynamic> analysis,
      ) {
    for (final key in [
      'foods',
      'ingredients',
      'items',
      'food_items',
      'detected_foods',
    ]) {
      final value =
      analysis[key];

      if (value is List) {
        final result =
        <String>[];

        for (final item in value) {
          if (item is String) {
            final text =
            item.trim();

            if (text.isNotEmpty) {
              result.add(text);
            }
          } else if (item is Map) {
            final name =
            item['name']
                ?.toString()
                .trim();

            if (name != null &&
                name.isNotEmpty) {
              result.add(name);
            }
          }
        }

        if (result.isNotEmpty) {
          return result
              .take(5)
              .toList();
        }
      }
    }

    return [];
  }

  static String _mealTypeFromTime(
      DateTime date,
      ) {
    if (date.hour < 11) {
      return 'Breakfast';
    }

    if (date.hour < 15) {
      return 'Lunch';
    }

    if (date.hour < 18) {
      return 'Snack';
    }

    return 'Dinner';
  }
}

class _WeekSelector
    extends StatelessWidget {
  final List<DateTime> dates;
  final DateTime selectedDate;
  final String Function(
      DateTime date,
      ) dayLetter;
  final bool Function(
      DateTime a,
      DateTime b,
      ) isSameDay;
  final ValueChanged<DateTime>
  onSelect;

  const _WeekSelector({
    required this.dates,
    required this.selectedDate,
    required this.dayLetter,
    required this.isSameDay,
    required this.onSelect,
  });

  @override
  Widget build(
      BuildContext context,
      ) {
    return Row(
      children: [
        for (var i = 0;
        i < dates.length;
        i++) ...[
          if (i > 0)
            const SizedBox(
              width: 7,
            ),
          Expanded(
            child: _DateChip(
              date: dates[i],
              selected:
              isSameDay(
                dates[i],
                selectedDate,
              ),
              dayLetter:
              dayLetter(
                dates[i],
              ),
              onTap: () =>
                  onSelect(
                    dates[i],
                  ),
            ),
          ),
        ],
      ],
    );
  }
}

class _DateChip
    extends StatelessWidget {
  final DateTime date;
  final bool selected;
  final String dayLetter;
  final VoidCallback onTap;

  const _DateChip({
    required this.date,
    required this.selected,
    required this.dayLetter,
    required this.onTap,
  });

  @override
  Widget build(
      BuildContext context,
      ) {
    return Material(
      color: selected
          ? AppColors.textDark
          : Colors.white,
      borderRadius:
      BorderRadius.circular(
        18,
      ),
      child: InkWell(
        borderRadius:
        BorderRadius.circular(
          18,
        ),
        onTap: onTap,
        child: Padding(
          padding:
          const EdgeInsets.symmetric(
            vertical: 10,
          ),
          child: Column(
            children: [
              Text(
                dayLetter,
                style: TextStyle(
                  fontSize: 11,
                  color: selected
                      ? Colors.white
                      : AppColors
                      .textMuted,
                ),
              ),
              const SizedBox(
                height: 2,
              ),
              Text(
                '${date.day}',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight:
                  FontWeight.w800,
                  color: selected
                      ? Colors.white
                      : AppColors
                      .textDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DailySummaryCard
    extends StatelessWidget {
  final int calories;
  final int goal;
  final double protein;
  final double carbs;
  final double fat;

  const _DailySummaryCard({
    required this.calories,
    required this.goal,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  @override
  Widget build(
      BuildContext context,
      ) {
    final remaining =
    goal > 0
        ? (goal - calories)
        .clamp(
      0,
      goal,
    )
        : null;

    return Container(
      padding:
      const EdgeInsets.all(
        16,
      ),
      decoration:
      _cardDecoration(),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          const Text(
            'Eaten today',
            style: TextStyle(
              fontSize: 12.5,
              color:
              AppColors.textMuted,
            ),
          ),
          const SizedBox(
            height: 2,
          ),
          Row(
            crossAxisAlignment:
            CrossAxisAlignment.end,
            children: [
              Text(
                '$calories',
                style:
                const TextStyle(
                  fontSize: 32,
                  fontWeight:
                  FontWeight.w800,
                  letterSpacing:
                  -0.8,
                  color:
                  AppColors.textDark,
                ),
              ),
              const SizedBox(
                width: 5,
              ),
              const Padding(
                padding:
                EdgeInsets.only(
                  bottom: 4,
                ),
                child: Text(
                  'kcal',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors
                        .textMuted,
                  ),
                ),
              ),
              const Spacer(),
              if (remaining != null)
                Container(
                  padding:
                  const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 6,
                  ),
                  decoration:
                  BoxDecoration(
                    color:
                    const Color(
                      0xFFE3F5EF,
                    ),
                    borderRadius:
                    BorderRadius.circular(
                      20,
                    ),
                  ),
                  child: Text(
                    '$remaining left',
                    style:
                    const TextStyle(
                      fontSize:
                      11.5,
                      fontWeight:
                      FontWeight.w700,
                      color:
                      Color(
                        0xFF0F7B64,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(
            height: 14,
          ),
          Row(
            children: [
              Expanded(
                child:
                _MacroItem(
                  label:
                  'Protein',
                  value:
                  protein,
                  barColor:
                  const Color(
                    0xFF3B82F6,
                  ),
                ),
              ),
              const SizedBox(
                width: 12,
              ),
              Expanded(
                child:
                _MacroItem(
                  label:
                  'Carbs',
                  value:
                  carbs,
                  barColor:
                  const Color(
                    0xFFF59E0B,
                  ),
                ),
              ),
              const SizedBox(
                width: 12,
              ),
              Expanded(
                child:
                _MacroItem(
                  label: 'Fat',
                  value: fat,
                  barColor:
                  const Color(
                    0xFFF26B4E,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MacroItem
    extends StatelessWidget {
  final String label;
  final double value;
  final Color barColor;

  const _MacroItem({
    required this.label,
    required this.value,
    required this.barColor,
  });

  @override
  Widget build(
      BuildContext context,
      ) {
    final progress =
    (value / 200)
        .clamp(
      0.0,
      1.0,
    );

    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style:
                const TextStyle(
                  fontSize: 12,
                  color: AppColors
                      .textMuted,
                ),
              ),
            ),
            Text(
              '${value.round()} g',
              style:
              const TextStyle(
                fontSize: 12,
                fontWeight:
                FontWeight.w700,
                color:
                AppColors.textDark,
              ),
            ),
          ],
        ),
        const SizedBox(
          height: 6,
        ),
        ClipRRect(
          borderRadius:
          BorderRadius.circular(
            4,
          ),
          child:
          LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor:
            barColor.withOpacity(
              0.15,
            ),
            valueColor:
            AlwaysStoppedAnimation(
              barColor,
            ),
          ),
        ),
      ],
    );
  }
}

class _LatestMealCard
    extends StatelessWidget {
  final _MealEntry meal;

  const _LatestMealCard({
    required this.meal,
  });

  Uint8List? _decodeImage(
      String? base64String,
      ) {
    if (base64String == null ||
        base64String.trim().isEmpty) {
      return null;
    }

    try {
      var value =
      base64String.trim();

      if (value.contains(',')) {
        value = value
            .split(',')
            .last;
      }

      return base64Decode(
        value,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(
      BuildContext context,
      ) {
    final bytes =
    _decodeImage(
      meal.imageBase64,
    );

    return Container(
      padding:
      const EdgeInsets.all(
        16,
      ),
      decoration:
      _cardDecoration(),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius:
                BorderRadius.circular(
                  16,
                ),
                child: SizedBox(
                  width: 84,
                  height: 84,
                  child: bytes != null
                      ? Image.memory(
                    bytes,
                    fit:
                    BoxFit.cover,
                    gaplessPlayback:
                    true,
                  )
                      : Container(
                    color: AppColors
                        .accentLight,
                    alignment:
                    Alignment.center,
                    child:
                    const Icon(
                      Icons
                          .restaurant_rounded,
                      size: 34,
                      color: AppColors
                          .primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(
                width: 14,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
                  children: [
                    Container(
                      padding:
                      const EdgeInsets.symmetric(
                        horizontal:
                        9,
                        vertical: 4,
                      ),
                      decoration:
                      BoxDecoration(
                        color:
                        const Color(
                          0xFFEDE9FE,
                        ),
                        borderRadius:
                        BorderRadius.circular(
                          20,
                        ),
                      ),
                      child: Text(
                        '✦ Scanned · ${meal.mealType}',
                        style:
                        const TextStyle(
                          fontSize:
                          10.5,
                          fontWeight:
                          FontWeight.w600,
                          color:
                          Color(
                            0xFF7C5CE0,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 5,
                    ),
                    Text(
                      meal.name,
                      maxLines: 2,
                      overflow:
                      TextOverflow
                          .ellipsis,
                      style:
                      const TextStyle(
                        fontSize:
                        17,
                        fontWeight:
                        FontWeight.w800,
                        color: AppColors
                            .textDark,
                      ),
                    ),
                    const SizedBox(
                      height: 3,
                    ),
                    Text(
                      '${meal.calories.round()} kcal · ${meal.protein.round()} g protein',
                      style:
                      const TextStyle(
                        fontSize:
                        12.5,
                        color: AppColors
                            .textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (meal.tags
              .isNotEmpty) ...[
            const SizedBox(
              height: 12,
            ),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children:
              meal.tags.map(
                    (tag) {
                  return Container(
                    padding:
                    const EdgeInsets.symmetric(
                      horizontal:
                      10,
                      vertical: 6,
                    ),
                    decoration:
                    BoxDecoration(
                      color:
                      const Color(
                        0xFFF4F7F6,
                      ),
                      borderRadius:
                      BorderRadius.circular(
                        20,
                      ),
                    ),
                    child: Text(
                      tag,
                      style:
                      const TextStyle(
                        fontSize:
                        11.5,
                        color: AppColors
                            .textDark,
                      ),
                    ),
                  );
                },
              ).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _MealListCard
    extends StatelessWidget {
  final List<_MealEntry> meals;

  const _MealListCard({
    required this.meals,
  });

  @override
  Widget build(
      BuildContext context,
      ) {
    return Container(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 16,
      ),
      decoration:
      _cardDecoration(),
      child: Column(
        children: [
          for (var i = 0;
          i < meals.length;
          i++) ...[
            if (i > 0)
              const Divider(
                height: 1,
                color:
                Color(
                  0xFFE8ECEA,
                ),
              ),
            _MealRow(
              meal: meals[i],
            ),
          ],
        ],
      ),
    );
  }
}

class _MealRow
    extends StatelessWidget {
  final _MealEntry meal;

  const _MealRow({
    required this.meal,
  });

  IconData get _icon {
    switch (
    meal.mealType
        .toLowerCase()) {
      case 'breakfast':
        return Icons
            .wb_sunny_outlined;
      case 'lunch':
        return Icons
            .restaurant_rounded;
      case 'snack':
        return Icons
            .egg_alt_outlined;
      case 'dinner':
        return Icons
            .dinner_dining_outlined;
      default:
        return Icons
            .restaurant_menu_rounded;
    }
  }

  Color get _bg {
    switch (
    meal.mealType
        .toLowerCase()) {
      case 'breakfast':
        return const Color(
          0xFFFFF3D6,
        );
      case 'lunch':
        return const Color(
          0xFFFDE8E2,
        );
      case 'snack':
        return const Color(
          0xFFE5EEFD,
        );
      case 'dinner':
        return const Color(
          0xFFE3F5EF,
        );
      default:
        return const Color(
          0xFFF0F2F1,
        );
    }
  }

  Color get _fg {
    switch (
    meal.mealType
        .toLowerCase()) {
      case 'breakfast':
        return const Color(
          0xFFD98E04,
        );
      case 'lunch':
        return const Color(
          0xFFF26B4E,
        );
      case 'snack':
        return const Color(
          0xFF3B74E0,
        );
      case 'dinner':
        return const Color(
          0xFF0F7B64,
        );
      default:
        return const Color(
          0xFF6B7572,
        );
    }
  }

  @override
  Widget build(
      BuildContext context,
      ) {
    final subtitle =
    meal.tags.isNotEmpty
        ? meal.tags
        .take(3)
        .join(', ')
        : meal.name;

    return Padding(
      padding:
      const EdgeInsets.symmetric(
        vertical: 12,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration:
            BoxDecoration(
              color: _bg,
              borderRadius:
              BorderRadius.circular(
                12,
              ),
            ),
            child: Icon(
              _icon,
              size: 20,
              color: _fg,
            ),
          ),
          const SizedBox(
            width: 12,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment
                  .start,
              children: [
                Text(
                  meal.mealType,
                  style:
                  const TextStyle(
                    fontSize: 15,
                    fontWeight:
                    FontWeight.w700,
                    color:
                    AppColors.textDark,
                  ),
                ),
                const SizedBox(
                  height: 2,
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow:
                  TextOverflow
                      .ellipsis,
                  style:
                  const TextStyle(
                    fontSize: 12,
                    color: AppColors
                        .textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(
            width: 10,
          ),
          Text(
            '${meal.calories.round()}',
            style:
            const TextStyle(
              fontSize: 15,
              fontWeight:
              FontWeight.w800,
              color:
              AppColors.textDark,
            ),
          ),
          const SizedBox(
            width: 3,
          ),
          const Text(
            'kcal',
            style: TextStyle(
              fontSize: 11.5,
              color:
              AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyMealsCard
    extends StatelessWidget {
  const _EmptyMealsCard();

  @override
  Widget build(
      BuildContext context,
      ) {
    return Container(
      width:
      double.infinity,
      padding:
      const EdgeInsets.all(
        22,
      ),
      decoration:
      _cardDecoration(),
      child: const Column(
        children: [
          Icon(
            Icons
                .restaurant_menu_rounded,
            size: 42,
            color:
            AppColors.primary,
          ),
          SizedBox(
            height: 10,
          ),
          Text(
            'No meals for this day',
            style: TextStyle(
              fontSize: 16,
              fontWeight:
              FontWeight.w700,
              color:
              AppColors.textDark,
            ),
          ),
          SizedBox(
            height: 5,
          ),
          Text(
            'Analyze a meal and it will appear here automatically.',
            textAlign:
            TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              color:
              AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

BoxDecoration _cardDecoration() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius:
    BorderRadius.circular(
      24,
    ),
    boxShadow: [
      BoxShadow(
        color:
        Colors.black.withOpacity(
          0.035,
        ),
        blurRadius: 18,
        offset:
        const Offset(
          0,
          6,
        ),
      ),
    ],
  );
}
