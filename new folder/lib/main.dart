import 'package:flutter/material.dart';

void main() => runApp(const CalculatorApp());

class CalculatorApp extends StatelessWidget {
  const CalculatorApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Calculadora',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF7C5CFC),
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: const Color(0xFF12131A),
      useMaterial3: true,
    ),
    home: const CalculatorPage(),
  );
}

class CalculatorPage extends StatefulWidget {
  const CalculatorPage({super.key});

  @override
  State<CalculatorPage> createState() => _CalculatorPageState();
}

class _CalculatorPageState extends State<CalculatorPage> {
  String display = '0';
  String history = '';
  double? storedValue;
  String? operation;
  bool replaceDisplay = true;

  void inputDigit(String digit) => setState(() {
    if (display == 'Error' || replaceDisplay) {
      display = digit;
      replaceDisplay = false;
    } else if (display == '0') {
      display = digit;
    } else if (display.replaceAll('-', '').length < 12) {
      display += digit;
    }
  });

  void inputDecimal() => setState(() {
    if (display == 'Error' || replaceDisplay) {
      display = '0.';
      replaceDisplay = false;
    } else if (!display.contains('.')) {
      display += '.';
    }
  });

  void clear() => setState(() {
    display = '0';
    history = '';
    storedValue = null;
    operation = null;
    replaceDisplay = true;
  });

  void toggleSign() {
    if (display == '0' || display == 'Error') return;
    setState(
      () => display = display.startsWith('-')
          ? display.substring(1)
          : '-$display',
    );
  }

  void percent() {
    final value = double.tryParse(display);
    if (value == null) return;
    setState(() {
      display = format(value / 100);
      replaceDisplay = true;
    });
  }

  void chooseOperation(String nextOperation) {
    final current = double.tryParse(display);
    if (current == null) return;
    setState(() {
      if (storedValue != null && operation != null && !replaceDisplay) {
        final result = calculate(storedValue!, current, operation!);
        if (result == null) return showError();
        storedValue = result;
        display = format(result);
      } else {
        storedValue = current;
      }
      operation = nextOperation;
      history = '${format(storedValue!)} $nextOperation';
      replaceDisplay = true;
    });
  }

  void equals() {
    final current = double.tryParse(display);
    if (storedValue == null || operation == null || current == null) return;
    setState(() {
      final left = storedValue!;
      final operator = operation!;
      final result = calculate(left, current, operator);
      if (result == null) return showError();
      history = '${format(left)} $operator ${format(current)} =';
      display = format(result);
      storedValue = null;
      operation = null;
      replaceDisplay = true;
    });
  }

  double? calculate(double left, double right, String operator) =>
      switch (operator) {
        '+' => left + right,
        '−' => left - right,
        '×' => left * right,
        '÷' => right == 0 ? null : left / right,
        _ => right,
      };

  void showError() {
    display = 'Error';
    history = 'No se puede dividir entre cero';
    storedValue = null;
    operation = null;
    replaceDisplay = true;
  }

  String format(double value) {
    if (!value.isFinite) return 'Error';
    if (value == value.truncateToDouble()) return value.toInt().toString();
    return value.toStringAsFixed(8).replaceFirst(RegExp(r'0+$'), '');
  }

  void press(String label) {
    if (RegExp(r'^\d$').hasMatch(label)) return inputDigit(label);
    switch (label) {
      case 'AC':
        clear();
      case '+/−':
        toggleSign();
      case '%':
        percent();
      case '.':
        inputDecimal();
      case '=':
        equals();
      default:
        chooseOperation(label);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Calculadora',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFAFAFB9),
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Align(
                    alignment: Alignment.bottomRight,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          history,
                          key: const Key('history'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF898995),
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 8),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            display,
                            key: const Key('display'),
                            style: const TextStyle(
                              fontSize: 64,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(flex: 7, child: keypad()),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  Widget keypad() {
    const rows = [
      ['AC', '+/−', '%', '÷'],
      ['7', '8', '9', '×'],
      ['4', '5', '6', '−'],
      ['1', '2', '3', '+'],
      ['0', '.', '='],
    ];
    return Column(
      children: [
        for (final row in rows)
          Expanded(
            child: Row(
              children: [
                for (final label in row)
                  Expanded(
                    flex: label == '0' ? 2 : 1,
                    child: Padding(
                      padding: const EdgeInsets.all(5),
                      child: CalculatorButton(
                        label: label,
                        onPressed: () => press(label),
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

class CalculatorButton extends StatelessWidget {
  const CalculatorButton({
    super.key,
    required this.label,
    required this.onPressed,
  });
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final accent = ['÷', '×', '−', '+', '='].contains(label);
    final utility = ['AC', '+/−', '%'].contains(label);
    return SizedBox.expand(
      child: Material(
        color: accent
            ? const Color(0xFF7C5CFC)
            : utility
            ? const Color(0xFF353641)
            : const Color(0xFF22232D),
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          key: Key('button_$label'),
          onTap: onPressed,
          borderRadius: BorderRadius.circular(22),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 25,
                fontWeight: accent ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
