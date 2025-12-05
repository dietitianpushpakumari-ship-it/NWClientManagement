import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AdminViewMode {
  global,   // Super Admin View (All Data)
  personal  // Dietitian View (My Data)
}

class AdminDashboardState {
  final AdminViewMode viewMode;
  AdminDashboardState({this.viewMode = AdminViewMode.personal});

  AdminDashboardState copyWith({AdminViewMode? viewMode}) {
    return AdminDashboardState(
      viewMode: viewMode ?? this.viewMode,
    );
  }
}

class AdminDashboardNotifier extends StateNotifier<AdminDashboardState> {
  AdminDashboardNotifier() : super(AdminDashboardState());

  void toggleViewMode() {
    if (state.viewMode == AdminViewMode.global) {
      state = state.copyWith(viewMode: AdminViewMode.personal);
    } else {
      state = state.copyWith(viewMode: AdminViewMode.global);
    }
  }
}

final adminDashboardProvider = StateNotifierProvider<AdminDashboardNotifier, AdminDashboardState>((ref) {
  return AdminDashboardNotifier();
});