// lib/features/migration/models/migration_state.dart

import 'package:nutricare_client_management/admin/migration/migration_config.dart';

class MigrationTask {
  final CollectionDefinition config;
  bool isSelected;
  double progress; // 0.0 to 1.0
  String status;   // 'Idle', 'Copying...', 'Done', 'Error'

  MigrationTask({
    required this.config,
  }) : isSelected = config.isDefault,
        progress = 0.0,
        status = 'Idle';
}