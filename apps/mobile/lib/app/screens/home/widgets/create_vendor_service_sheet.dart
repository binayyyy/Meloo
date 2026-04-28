import 'package:flutter/material.dart';
import '../../../vendors/vendor_models.dart';
import '../../../widgets/modal_form_scaffold.dart';

class CreateVendorServiceSheet extends StatefulWidget {
  const CreateVendorServiceSheet({
    required this.onSubmit,
    required this.isSubmitting,
    super.key,
  });

  final Future<void> Function(VendorServiceCreateRequest request) onSubmit;
  final bool isSubmitting;

  @override
  State<CreateVendorServiceSheet> createState() =>
      _CreateVendorServiceSheetState();
}

class _CreateVendorServiceSheetState extends State<CreateVendorServiceSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _basePriceController = TextEditingController(text: '0.00');
  final _pricingModelController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _basePriceController.dispose();
    _pricingModelController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    await widget.onSubmit(
      VendorServiceCreateRequest(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        basePrice: _basePriceController.text.trim(),
        pricingModel: _pricingModelController.text.trim(),
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
        title: 'Add service',
        subtitle:
            'Define a single offering with clear pricing so organizers understand it without extra back-and-forth.',
        icon: Icons.room_service_rounded,
        actionLabel: 'Save service',
        submittingLabel: 'Saving service...',
        isSubmitting: widget.isSubmitting,
        onSubmit: _submit,
        children: [
          ModalFormSection(
            title: 'Service details',
            subtitle: 'Name, pricing model, and what is included.',
            icon: Icons.inventory_2_rounded,
            child: Column(
              children: [
                _field(_nameController, 'Service name'),
                const SizedBox(height: 14),
                _field(_pricingModelController, 'Pricing model'),
                const SizedBox(height: 14),
                _field(_basePriceController, 'Base price'),
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
