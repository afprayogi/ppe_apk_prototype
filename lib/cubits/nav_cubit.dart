import 'package:bloc/bloc.dart';

enum AppTab { dashboard, attendance, scan, employees, archive }

class NavCubit extends Cubit<AppTab> {
  NavCubit() : super(AppTab.dashboard);

  void go(AppTab tab) => emit(tab);
}

/// Employee preselected for the next scan (set from attendance / profile).
class ScanTargetCubit extends Cubit<String?> {
  ScanTargetCubit() : super(null);

  void select(String? employeeId) => emit(employeeId);
}
