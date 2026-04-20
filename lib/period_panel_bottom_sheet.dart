import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

Future<void> showPeriodPanel({
  required TextEditingController periodRangeController,
  Future<void> Function(DateTime startDate, DateTime endDate)? onSavedRange,
  VoidCallback? onDismissWithoutSave,
}) async {
  DateTime? selectedStart;
  DateTime? selectedEnd;
  var isSaved = false;
  var isSubmitting = false;

  await Get.bottomSheet(
    StatefulBuilder(
      builder: (BuildContext context, StateSetter setStateSheet) {
        return Container(
          padding: const EdgeInsets.only(
            left: 24,
            right: 24,
            bottom: 30,
            top: 10,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 50,
                height: 5,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const Text(
                'คุณยังไม่ได้ใส่ประจำเดือนนะ คุณต้องการที่จะใส่ไหม',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF8E8E8E),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 25),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedStart ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setStateSheet(() => selectedStart = picked);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(25),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          selectedStart != null
                              ? DateFormat('dd/MM/yy').format(selectedStart!)
                              : 'วันที่เริ่ม',
                          style: TextStyle(
                            color: selectedStart != null
                                ? const Color(0xFF6A6A6A)
                                : const Color(0xFFB0B0B0),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 15),
                    child: Text(
                      '-',
                      style: TextStyle(
                        color: Color(0xFF5CC0FF),
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate:
                              selectedEnd ?? selectedStart ?? DateTime.now(),
                          firstDate: selectedStart ?? DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setStateSheet(() => selectedEnd = picked);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(25),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          selectedEnd != null
                              ? DateFormat('dd/MM/yy').format(selectedEnd!)
                              : 'วันที่สิ้นสุด',
                          style: TextStyle(
                            color: selectedEnd != null
                                ? const Color(0xFF6A6A6A)
                                : const Color(0xFFB0B0B0),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (selectedStart != null && selectedEnd != null) {
                            if (onSavedRange != null) {
                              setStateSheet(() => isSubmitting = true);
                              try {
                                await onSavedRange(
                                    selectedStart!, selectedEnd!);
                              } catch (error) {
                                if (Get.isSnackbarOpen) {
                                  Get.closeCurrentSnackbar();
                                }
                                Get.snackbar(
                                  'เกิดข้อผิดพลาด',
                                  'บันทึกข้อมูลไม่สำเร็จ: $error',
                                  backgroundColor: Colors.redAccent,
                                  colorText: Colors.white,
                                );
                                setStateSheet(() => isSubmitting = false);
                                return;
                              }
                              setStateSheet(() => isSubmitting = false);
                            }

                            final start =
                                DateFormat('dd/MM/yy').format(selectedStart!);
                            final end =
                                DateFormat('dd/MM/yy').format(selectedEnd!);
                            periodRangeController.text = '$start - $end';

                            isSaved = true;
                            Get.back();
                          } else {
                            Get.snackbar(
                              'แจ้งเตือน',
                              'กรุณาเลือกทั้งวันเริ่มต้นและวันสิ้นสุด',
                              backgroundColor: const Color(0xFF5CC0FF),
                              colorText: Colors.white,
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5CC0FF),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'บันทึก',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        );
      },
    ),
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
  ).whenComplete(() {
    if (!isSaved) {
      onDismissWithoutSave?.call();
    }
  });
}
