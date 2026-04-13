---
name: flutter-form-validation
description: 'Flutter form input validation, formatting, and error UX for POS apps. Use when: building or editing TextField inputs, adding validation logic, formatting currency/money/number fields, showing inline errors, designing input constraints. Covers Material Design 3, Apple HIG, and UX research best practices.'
---

# Flutter Form Validation & Input UX

Best practices for text field validation, input formatting, and error messaging in Flutter — synthesized from Material Design 3 guidelines, Apple Human Interface Guidelines, and UX research (Smashing Magazine, Baymard Institute).

## Core Validation Principles

### 1. Reward Early, Punish Late

- **When a field already has an error**: clear the error immediately on keystroke as soon as input becomes valid (reward early).
- **When a field is currently valid**: do NOT show errors while the user is still typing. Wait until they leave the field — `onBlur` / `onEditingComplete` / `onTapOutside` (punish late).
- **Never validate empty fields on focus or blur** — only flag required-field errors on Save/Submit.

### 2. Three Validation Tiers

| Tier | When | What | How in Flutter |
|------|------|------|----------------|
| **Prevent** | On every keystroke | Block structurally impossible characters | `inputFormatters` with `FilteringTextInputFormatter` |
| **Warn** | On keystroke, only for severe/unrecoverable patterns | Show red inline `errorText` immediately | `onChanged` → detect impossible structure (e.g. two decimal points) |
| **Validate** | On blur or on Save/Submit | Check full format correctness | `onEditingComplete` / `onTapOutside` / Save button handler |

### 3. Prevent vs Warn vs Validate — Decision Rules

- **Prevent (block input)**: Use when a character can NEVER be valid in this field.
  - Letters in a number-only field → use `FilteringTextInputFormatter.digitsOnly`
  - Non-numeric, non-dot in a price field → use `FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))`

- **Warn (show error immediately)**: Use when a keystroke creates an unrecoverable structural error.
  - A second decimal point in a price field (`12.3.`) → show red error, revert the bad character
  - A value that exceeds a hard max (stock > 10000) → show red error immediately

- **Validate (on blur / submit)**: Use when input is incomplete but may become valid with more typing.
  - Price is `12.3` (may become `12.30` or be auto-corrected) → do NOT warn while typing
  - Price is `12` (valid number, just not formatted) → auto-correct on blur to `12.00`

## Money / Currency Fields

### Input Formatter
Allow digits and at most one decimal point. Do NOT restrict decimal places while typing — it causes the "field clearing" problem.

```dart
inputFormatters: [
  FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
],
```

### Structural Guard (onChanged)
Detect and revert impossible patterns immediately:

```dart
onChanged: (value) {
  final dotCount = '.'.allMatches(value).length;
  if (dotCount > 1) {
    // Remove extra dots, show error
    final firstDot = value.indexOf('.');
    final corrected = value.substring(0, firstDot + 1) +
        value.substring(firstDot + 1).replaceAll('.', '');
    controller.value = TextEditingValue(
      text: corrected,
      selection: TextSelection.collapsed(offset: corrected.length),
    );
    setState(() { error = 'Only one decimal point is allowed.'; });
  } else if (error != null) {
    setState(() { error = null; });
  }
},
```

### Auto-Correct on Blur
Normalize partial input to proper money format when the user leaves the field:

```dart
void normalizePrice() {
  final text = controller.text.trim();
  if (text.isEmpty) return;
  final parsed = double.tryParse(text);
  if (parsed == null) return;
  final normalized = parsed.toStringAsFixed(2);
  if (normalized != controller.text) {
    controller.text = normalized;
    controller.selection = TextSelection.collapsed(offset: normalized.length);
  }
}
```

Hook it to blur:
```dart
onEditingComplete: () { normalizePrice(); setState(() { error = null; }); },
onTapOutside: (_) { normalizePrice(); setState(() { error = null; }); },
```

### Final Validation (on Save/Submit)
Only on Save, enforce strict format:

```dart
static final _moneyPattern = RegExp(r'^\d+\.\d{2}$');

String? validatePrice(String value) {
  if (value.isEmpty) return 'Price is required.';
  if (!_moneyPattern.hasMatch(value)) return 'Use format like 11.99.';
  return null;
}
```

## Integer Fields (Stock, Threshold)

### Input Formatter
```dart
inputFormatters: [FilteringTextInputFormatter.digitsOnly],
```

### Immediate Warning for Max Violations
```dart
onChanged: (value) {
  final parsed = int.tryParse(value);
  if (parsed != null && parsed > 10000) {
    setState(() { error = 'Must be 10000 or less.'; });
  } else if (error != null) {
    setState(() { error = null; });
  }
},
```

### Final Validation (on Save/Submit)
```dart
String? validateStock(String value) {
  if (value.isEmpty) return 'Stock is required.';
  final stock = int.tryParse(value);
  if (stock == null) return 'Must be an integer.';
  if (stock > 10000) return 'Must be 10000 or less.';
  return null;
}
```

## Error Display Rules

### Material Design 3 Guidelines
- Use `errorText` on `InputDecoration` — it turns the field border and label red automatically.
- Swap supporting/helper text with error text; do NOT stack them (causes layout shift).
- Strongly recommended: show an error icon (trailing) alongside `errorText` for accessibility.
- Error text should describe how to fix the issue, not just what's wrong.
  - Bad: "Invalid price"
  - Good: "Use format like 11.99"

### Apple HIG Guidelines
- Validate when it makes sense — for email, validate on blur; for passwords, validate before leaving.
- Use a number formatter for numeric fields to auto-format values.
- Match field size to anticipated input length.

### UX Research (Baymard Institute / Smashing Magazine)
- **Avoid premature validation**: never show errors on focus or before the user has had a chance to complete input.
- **Remove errors immediately on correction**: once the user fixes the issue, remove the red error on the very next keystroke — don't wait for blur.
- **Use positive inline validation**: show a green checkmark or valid state when input is correct (consider for future enhancement).
- **Validate empty fields only on Submit**: don't flag missing required fields until the user tries to save.
- **Support copy-paste**: don't use overly strict formatters that break pasted content. Allow permissive input, then auto-correct.

## TextField Decoration Checklist

| Field Type | prefixText | hintText | keyboardType | inputFormatters | Auto-correct on blur |
|------------|-----------|----------|--------------|-----------------|---------------------|
| Price | `$` | `0.00` | `numberWithOptions(decimal: true)` | Allow `[\d.]` | `toStringAsFixed(2)` |
| Stock | — | — | `number` | `digitsOnly` | — |
| Threshold | — | — | `number` | `digitsOnly` | — |
| Name | — | — | `text` | — | — |
| Category | — | — | `text` | — | — |

## Anti-Patterns to Avoid

1. **Strict formatter that clears input**: Using `FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}$'))` rejects the entire new value when regex match fails, which clears the field. Use a character-level allow instead: `RegExp(r'[\d.]')`.

2. **Validating format on every keystroke**: Running `!RegExp(r'^\d+\.\d{2}$').hasMatch(value)` on `onChanged` flags `11.` as invalid while the user is still typing. Only run format validation on blur or submit.

3. **SnackBar for field errors**: SnackBars disappear and don't indicate which field has the error. Always use inline `errorText` on the specific field.

4. **Blocking valid partial input**: Don't prevent typing `11.5` because it's "not money format yet". The user may intend `11.50` — let blur auto-correct handle it.

5. **Showing required-field error on blur of empty field**: User may have accidentally focused then left. Only show required errors on Submit.
