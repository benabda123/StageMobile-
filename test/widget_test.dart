import 'package:flutter_test/flutter_test.dart';

import 'package:keystone_mobile/core/theme/app_theme.dart';

void main() {
  test('app theme uses keystone brand colors', () {
    final theme = AppTheme.light;
    expect(theme.colorScheme.primary.toARGB32(), 0xFF003366);
  });
}
