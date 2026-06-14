import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../constants/app_constants.dart';
import '../../../models/employee_model.dart';
import '../../../providers/employee_provider.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';

class PersonaliaTab extends ConsumerWidget {
  const PersonaliaTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(employeeProvider);

    if (state.isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primaryGreen));
    }

    if (state.employees.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_outline, size: 56.sp, color: AppColors.divider),
            SizedBox(height: 10.h),
            Text('Belum ada karyawan terdaftar',
                style: AppTextStyles.bodyMedium),
            SizedBox(height: 12.h),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen),
              icon: const Icon(Icons.person_add, color: Colors.white),
              label: Text('Tambah Karyawan',
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: Colors.white)),
              onPressed: () =>
                  Navigator.pushNamed(context, AppConstants.routeRegister),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(14.r),
      itemCount: state.employees.length,
      itemBuilder: (_, i) {
        final emp = state.employees[i];
        return _EmployeeCard(
          emp: emp,
          onDelete: () => _confirmDelete(context, ref, emp),
          onEdit: () => Navigator.pushNamed(
            context,
            AppConstants.routeRegister,
            arguments: emp,
          ),
        );
      },
    );
  }

  void _confirmDelete(
      BuildContext context, WidgetRef ref, EmployeeModel emp) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Karyawan'),
        content: Text('Hapus "${emp.name}" dari sistem?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.progressRed),
            onPressed: () {
              Navigator.pop(context);
              ref.read(employeeProvider.notifier).removeEmployee(emp.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${emp.name} dihapus')),
              );
            },
            child: const Text('Hapus',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _EmployeeCard extends StatelessWidget {
  final EmployeeModel emp;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const _EmployeeCard(
      {required this.emp, required this.onDelete, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24.r,
            backgroundColor: AppColors.surfaceGreen,
            child: Icon(Icons.person,
                color: AppColors.primaryGreen, size: 28.sp),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(emp.name, style: AppTextStyles.titleMedium),
                Text('NIA : ${emp.nia}',
                    style: AppTextStyles.bodyMedium),
                Text('Shift : ${emp.shift}',
                    style: AppTextStyles.bodyMedium),
                SizedBox(height: 4.h),
                Wrap(
                  spacing: 4.w,
                  children: emp.requiredPpe
                      .map((p) => Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 6.w, vertical: 2.h),
                            decoration: BoxDecoration(
                              color: AppColors.primaryGreen,
                              borderRadius: BorderRadius.circular(4.r),
                            ),
                            child: Text(p,
                                style: AppTextStyles.labelSmall
                                    .copyWith(color: AppColors.white)),
                          ))
                      .toList(),
                ),
              ],
            ),
          ),
          Column(
            children: [
              IconButton(
                icon: Icon(Icons.edit_outlined,
                    color: AppColors.primaryGreen, size: 20.sp),
                onPressed: onEdit,
                tooltip: 'Edit',
              ),
              IconButton(
                icon: Icon(Icons.delete_outline,
                    color: AppColors.progressRed, size: 20.sp),
                onPressed: onDelete,
                tooltip: 'Hapus',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
