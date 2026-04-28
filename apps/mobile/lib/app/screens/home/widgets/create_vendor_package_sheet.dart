import 'package:flutter/material.dart';
import '../../../vendors/vendor_models.dart';
import '../../../widgets/modal_form_scaffold.dart';

class CreateVendorPackageSheet extends StatefulWidget {
  const CreateVendorPackageSheet({
    required this.onSubmit,
    required this.isSubmitting,
    super.key,
  });

  final Future<void> Function(VendorPackageCreateRequest request) onSubmit;
  final bool isSubmitting;

  @override
  State<CreateVendorPackageSheet> createState() =>
      _CreateVendorPackageSheetState();
}

class _CreateVendorPackageSheetState extends State<CreateVendorPackageSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController(text: '0.00');

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    await widget.onSubmit(
      VendorPackageCreateRequest(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        price: _priceController.text.trim(),
      ),
    );
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ModalFormScaffold(
        title: 'Add package',
        subtitle:
            'Create a cleaner bundled offer with one headline price and a concise scope.',
        icon: Icons.widgets_rounded,
        actionLabel: 'Save package',
        submittingLabel: 'Saving package...',
        isSubmitting: widget.isSubmitting,
        onSubmit: _submit,
        children: [
          ModalFormSection(
            title: 'Package setup',
            subtitle: 'Name the bundle, set the price, and explain what is covered.',
            icon: Icons.sell_rounded,
            child: Column(
              children: [
                _field(_nameController, 'Package name'),
                const SizedBox(height: 14),
                _field(_priceController, 'Price'),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: 'Description'),
                  validator: (value) => value == null || value.trim().length < 20
                      ? 'Use at least 20 characters'
                      : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(TextEditingController controller, String label) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
      validator: (value) =>
          value == null || value.trim().isEmpty ? '$label is required' : null,
    );
  }
}
