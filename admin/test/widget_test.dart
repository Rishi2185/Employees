// The admin app's data contracts and provider logic are covered by
// models_test.dart, api_test.dart, and providers_test.dart. A full widget pump
// needs a live backend, so smoke-level UI tests live closer to integration.
// This file holds a minimal status-mapping guard.

import 'package:aarvy_admin/utils/status_ui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('status integer enum stays patient-app compatible (0/1/2)', () {
    expect(StatusUi.label(0), 'Upcoming');
    expect(StatusUi.label(1), 'Completed');
    expect(StatusUi.label(2), 'Cancelled');
    expect(StatusUi.label(99), 'Unknown'); // degrades, never crashes
  });
}
