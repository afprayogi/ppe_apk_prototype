import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../constants/app_constants.dart';
import '../../models/employee_model.dart';
import '../../providers/employee_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_button.dart';
import '../../widgets/ppe_item_card.dart';

class RegisterScreen extends HookConsumerWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Jika ada argument, berarti mode EDIT
    final existing = ModalRoute.of(context)?.settings.arguments as EmployeeModel?;
    final isEdit   = existing != null;

    final nameCtrl    = useTextEditingController(text: existing?.name ?? '');
    final niaCtrl     = useTextEditingController(text: existing?.nia ?? '');
    final addressCtrl = useTextEditingController(text: existing?.address ?? '');
    final selectedShift = useState(existing?.shift ?? AppConstants.shifts.first);
    final selectedPpe   = useState<Set<String>>(
      existing != null
          ? Set<String>.from(existing.requiredPpe)
          : {'Boots', 'Vest', 'Helmet', 'Gloves'},
    );

    void save() {
      if (nameCtrl.text.isEmpty || niaCtrl.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nama dan NIA wajib diisi')),
        );
        return;
      }
      final emp = EmployeeModel(
        id:          existing?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        name:        nameCtrl.text.trim().toUpperCase(),
        nia:         niaCtrl.text.trim(),
        address:     addressCtrl.text.trim(),
        shift:       selectedShift.value,
        requiredPpe: selectedPpe.value.toList(),
      );

      if (isEdit) {
        ref.read(employeeProvider.notifier).updateEmployee(emp);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data karyawan diperbarui')),
        );
      } else {
        ref.read(employeeProvider.notifier).addEmployee(emp);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Karyawan berhasil disimpan')),
        );
      }
      Navigator.pop(context);
    }

    return Scaffold(
      backgroundColor: AppColors.primaryGreen,
      appBar: AppBar(
        backgroundColor: AppColors.darkGreen,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(isEdit ? 'Edit Karyawan' : 'Register',
            style: AppTextStyles.headlineOnGreen),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 12.w),
            child: CircleAvatar(
              radius: 18.r,
              backgroundColor: AppColors.amber,
              child: Icon(Icons.person,
                  color: AppColors.darkGreen, size: 20.sp),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Green header
            Container(
              width: double.infinity,
              padding: EdgeInsets.only(top: 20.h, bottom: 24.h),
              color: AppColors.primaryGreen,
              child: Column(
                children: [
                  Text(
                    isEdit ? 'Edit Employee' : 'Add Employee',
                    style: AppTextStyles.headlineLarge
                        .copyWith(color: AppColors.white),
                  ),
                  SizedBox(height: 12.h),
                  Container(
                    width: 72.w,
                    height: 72.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.white.withValues(alpha: 0.2),
                      border: Border.all(color: AppColors.white, width: 2),
                    ),
                    child: Icon(Icons.person_outline,
                        size: 40.sp, color: AppColors.white),
                  ),
                ],
              ),
            ),
            // White form
            Container(
              decoration: const BoxDecoration(color: AppColors.white),
              padding: EdgeInsets.all(16.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FormField(
                      label: 'Nama :',
                      hint: 'Masukkan nama lengkap',
                      controller: nameCtrl),
                  SizedBox(height: 10.h),
                  _FormField(
                      label: 'NIA :',
                      hint: 'Masukkan NIA',
                      controller: niaCtrl,
                      keyboardType: TextInputType.number),
                  SizedBox(height: 10.h),
                  _FormField(
                      label: 'Alamat :',
                      hint: 'Masukkan alamat rumah',
                      controller: addressCtrl),
                  SizedBox(height: 10.h),

                  // Shift dropdown
                  Text('Shift :', style: AppTextStyles.titleMedium),
                  SizedBox(height: 4.h),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedShift.value,
                        isExpanded: true,
                        items: AppConstants.shifts
                            .map((s) => DropdownMenuItem(
                                  value: s,
                                  child: Text(s,
                                      style: AppTextStyles.bodyLarge),
                                ))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) selectedShift.value = v;
                        },
                      ),
                    ),
                  ),
                  SizedBox(height: 14.h),

                  // PPE detect options label
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: 10.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.divider),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text(
                      'Pilih APD yang wajib digunakan',
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  ),
                  SizedBox(height: 10.h),

                  // PPE grid
                  _PpeGrid(
                    selected: selectedPpe.value,
                    onToggle: (item) {
                      final updated = Set<String>.from(selectedPpe.value);
                      if (updated.contains(item)) {
                        updated.remove(item);
                      } else {
                        updated.add(item);
                      }
                      selectedPpe.value = updated;
                    },
                  ),
                  SizedBox(height: 16.h),

                  AppButton(
                    label: isEdit ? 'UPDATE' : 'SAVE',
                    onPressed: save,
                  ),
                  SizedBox(height: 20.h),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
class _FormField extends StatelessWidget {
  final String label, hint;
  final TextEditingController controller;
  final TextInputType keyboardType;

  const _FormField({
    required this.label,
    required this.hint,
    required this.controller,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.titleMedium),
        SizedBox(height: 4.h),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: AppTextStyles.bodyLarge,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTextStyles.bodyMedium,
          ),
        ),
      ],
    );
  }
}

class _PpeGrid extends StatelessWidget {
  final Set<String> selected;
  final ValueChanged<String> onToggle;

  const _PpeGrid({required this.selected, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final items = AppConstants.ppeItems;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8.w,
        mainAxisSpacing: 8.h,
        childAspectRatio: 1.0,
      ),
      itemBuilder: (_, i) {
        final item = items[i];
        return PpeItemCard(
          label: item,
          icon: ppeIconMap[item] ?? Icons.shield_outlined,
          isSelected: selected.contains(item),
          isRequired: selected.contains(item),
          onTap: () => onToggle(item),
        );
      },
    );
  }
}
