import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/setting/controller/edit_profile_controller.dart';
import 'package:get/get.dart';

class EditProfilePage extends GetView<EditProfileController> {
  const EditProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final editController = Get.put(EditProfileController());

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFD),
      appBar: AppBar(
        title: const Text('Edit profile'),
      ),
      body: Obx(() {
        if (editController.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return Form(
          key: editController.formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _FieldCard(
                child: TextFormField(
                  controller: editController.nameController,
                  decoration: const InputDecoration(
                    labelText: 'Display name',
                    border: InputBorder.none,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a display name';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 14),
              _FieldCard(
                child: TextFormField(
                  initialValue: editController.email.value,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              _FieldCard(
                child: TextFormField(
                  controller: editController.bioController,
                  minLines: 3,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Bio',
                    hintText: 'Write a short intro',
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: editController.isSaving.value
                    ? null
                    : () async {
                        final success = await editController.save();
                        if (success) {
                          Get.back();
                        }
                      },
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  editController.isSaving.value ? 'Saving...' : 'Save changes',
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _FieldCard extends StatelessWidget {
  const _FieldCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD8E7F4)),
      ),
      child: child,
    );
  }
}
