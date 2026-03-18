import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/setting/controller/edit_profile_controller.dart';
import 'package:get/get.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late final String _controllerTag;
  late final EditProfileController _editController;

  @override
  void initState() {
    super.initState();
    _controllerTag = UniqueKey().toString();
    _editController = Get.put(
      EditProfileController(),
      tag: _controllerTag,
    );
  }

  @override
  void dispose() {
    if (Get.isRegistered<EditProfileController>(tag: _controllerTag)) {
      Get.delete<EditProfileController>(
        tag: _controllerTag,
        force: true,
      );
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFD),
      appBar: AppBar(
        title: const Text('Edit profile'),
      ),
      body: Obx(() {
        if (_editController.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return Form(
          key: _editController.formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _FieldCard(
                child: TextFormField(
                  controller: _editController.nameController,
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
                  initialValue: _editController.email.value,
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
                  controller: _editController.bioController,
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
                onPressed: _editController.isSaving.value
                    ? null
                    : () async {
                        final success = await _editController.save();
                        if (success) {
                          Get.back();
                        }
                      },
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  _editController.isSaving.value
                      ? 'Saving...'
                      : 'Save changes',
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
