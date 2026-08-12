import 'package:flutter_bloc/flutter_bloc.dart';

class MainTabCubit extends Cubit<int> {
  MainTabCubit() : super(0);

  void selectTab(int index) {
    if (index < 0 || index >= tabCount || index == state) {
      return;
    }
    emit(index);
  }

  static const tabCount = 3;
}
