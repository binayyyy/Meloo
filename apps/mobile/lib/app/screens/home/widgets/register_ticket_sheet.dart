import 'package:flutter/material.dart';
import '../../../events/event_models.dart';

class RegisterTicketSheet extends StatefulWidget {
  const RegisterTicketSheet({
    required this.ticketType,
    required this.onSubmit,
    required this.isSubmitting,
    super.key,
  });

  final TicketTypeModel ticketType;
  final Future<void> Function(int quantity) onSubmit;
  final bool isSubmitting;

  @override
  State<RegisterTicketSheet> createState() => _RegisterTicketSheetState();
}

class _RegisterTicketSheetState extends State<RegisterTicketSheet> {
  int _quantity = 1;

  @override
  Widget build(BuildContext context) {
    final maxQuantity = widget.ticketType.remaining < 5
        ? widget.ticketType.remaining
        : 5;
    final navigator = Navigator.of(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Register for ${widget.ticketType.name}',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          Text(
            widget.ticketType.isFree
                ? 'This is a free ticket. Registration confirms immediately.'
                : 'This ticket uses Stripe Checkout in test mode. You will finish payment on the hosted Stripe page and then return to the app.',
            style: const TextStyle(color: Color(0xFF5F645F), height: 1.5),
          ),
          if (!widget.ticketType.isFree) ...[
            const SizedBox(height: 12),
            Text(
              'Total: ${(double.parse(widget.ticketType.price) * _quantity).toStringAsFixed(2)}',
              style: const TextStyle(
                color: Color(0xFF0E6B5C),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(height: 20),
          DropdownButtonFormField<int>(
            initialValue: _quantity,
            items: List.generate(
              maxQuantity,
              (index) => DropdownMenuItem<int>(
                value: index + 1,
                child: Text('${index + 1} ticket${index == 0 ? '' : 's'}'),
              ),
            ),
            onChanged: widget.isSubmitting
                ? null
                : (value) {
                    if (value != null) {
                      setState(() => _quantity = value);
                    }
                  },
            decoration: const InputDecoration(
              labelText: 'Quantity',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: widget.isSubmitting
                  ? null
                  : () async {
                      await widget.onSubmit(_quantity);
                      if (mounted) {
                        navigator.pop();
                      }
                    },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Text(
                  widget.isSubmitting
                      ? 'Submitting...'
                      : widget.ticketType.isFree
                          ? 'Confirm registration'
                          : 'Continue to Stripe',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
