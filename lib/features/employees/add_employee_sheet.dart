import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gearguard/cubits/safety_cubit.dart';

const departments = [
  'Construction',
  'Welding',
  'Logistics',
  'Maintenance',
  'Operations',
  'Other',
];

Future<void> showAddEmployeeSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (_) => BlocProvider.value(
      value: context.read<SafetyCubit>(),
      child: const _AddEmployeeSheet(),
    ),
  );
}

class _AddEmployeeSheet extends StatefulWidget {
  const _AddEmployeeSheet();

  @override
  State<_AddEmployeeSheet> createState() => _AddEmployeeSheetState();
}

class _AddEmployeeSheetState extends State<_AddEmployeeSheet> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _code = TextEditingController();
  String _department = departments.first;

  @override
  void dispose() {
    _name.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final name = _name.text.trim();
    await context.read<SafetyCubit>().addEmployee(
      name: name,
      department: _department,
      code: _code.text,
    );
    navigator.pop();
    messenger.showSnackBar(SnackBar(content: Text('$name added to the team')));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add employee', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(
              'Registered workers can be scanned and tracked.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _name,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Full name',
                prefixIcon: Icon(Icons.person_rounded),
              ),
              validator: (v) => (v == null || v.trim().length < 2)
                  ? 'Enter the employee name'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _code,
              textCapitalization: TextCapitalization.characters,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'Employee ID (optional)',
                hintText: 'Auto-generated if empty',
                prefixIcon: Icon(Icons.badge_rounded),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _department,
              decoration: const InputDecoration(
                labelText: 'Department',
                prefixIcon: Icon(Icons.apartment_rounded),
              ),
              items: [
                for (final d in departments)
                  DropdownMenuItem(value: d, child: Text(d)),
              ],
              onChanged: (v) => setState(() => _department = v ?? _department),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _submit,
              child: const Text('Save employee'),
            ),
          ],
        ),
      ),
    );
  }
}
