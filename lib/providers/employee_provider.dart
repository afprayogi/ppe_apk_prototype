import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../core/database/employee_dao.dart';
import '../models/employee_model.dart';

const _uuid = Uuid();

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------
class EmployeeState {
  final List<EmployeeModel> employees;
  final bool isLoading;
  final String? error;

  const EmployeeState({
    this.employees = const [],
    this.isLoading = false,
    this.error,
  });

  EmployeeState copyWith({
    List<EmployeeModel>? employees,
    bool? isLoading,
    String? error,
  }) =>
      EmployeeState(
        employees: employees ?? this.employees,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------
class EmployeeNotifier extends StateNotifier<EmployeeState> {
  EmployeeNotifier(this._dao) : super(const EmployeeState(isLoading: true)) {
    _load();
  }

  final EmployeeDao _dao;

  Future<void> _load() async {
    try {
      final list = await _dao.fetchAll();
      state = state.copyWith(employees: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> reload() => _load();

  Future<void> addEmployee(EmployeeModel emp) async {
    final withId = emp.copyWith(id: emp.id.isEmpty ? _uuid.v4() : emp.id);
    await _dao.insert(withId);
    await _load();
  }

  Future<void> updateEmployee(EmployeeModel emp) async {
    await _dao.update(emp);
    await _load();
  }

  Future<void> removeEmployee(String id) async {
    await _dao.delete(id);
    state = state.copyWith(
        employees: state.employees.where((e) => e.id != id).toList());
  }

  Future<List<EmployeeModel>> search(String query) async {
    if (query.isEmpty) return state.employees;
    return _dao.search(query);
  }
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------
final employeeDaoProvider = Provider<EmployeeDao>((_) => EmployeeDao());

final employeeProvider =
    StateNotifierProvider<EmployeeNotifier, EmployeeState>((ref) {
  return EmployeeNotifier(ref.read(employeeDaoProvider));
});

final employeeSearchProvider =
    FutureProvider.family<List<EmployeeModel>, String>((ref, query) async {
  final notifier = ref.read(employeeProvider.notifier);
  return notifier.search(query);
});
