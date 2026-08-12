import 'package:flutter_test/flutter_test.dart';
import 'package:fund_nexus/features/main_shell/state/main_tab_cubit.dart';

void main() {
  test('changes to valid tab indexes only', () {
    final cubit = MainTabCubit();
    addTearDown(cubit.close);

    expect(cubit.state, 0);
    cubit.selectTab(2);
    expect(cubit.state, 2);
    cubit.selectTab(-1);
    expect(cubit.state, 2);
    cubit.selectTab(3);
    expect(cubit.state, 2);
  });

  test('reselecting the current tab does not emit', () async {
    final cubit = MainTabCubit();
    addTearDown(cubit.close);

    expect(cubit.stream, emitsInOrder(<int>[1]));
    cubit.selectTab(0);
    cubit.selectTab(1);
  });
}
