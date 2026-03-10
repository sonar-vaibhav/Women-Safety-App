import 'package:flutter/material.dart';

/// Lightweight manual contact entry screen that replaces the old
/// native contacts plugin so the feature works on all builds.

class SimplePhone {
  final String? value;
  SimplePhone(this.value);
}

class SimpleContact {
  final String? displayName;
  final List<SimplePhone>? phones;

  SimpleContact({this.displayName, this.phones});
}

class ContactsFetcher extends StatefulWidget {
  const ContactsFetcher({super.key});

  @override
  State<ContactsFetcher> createState() => _ContactsFetcherState();
}

class _ContactsFetcherState extends State<ContactsFetcher> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) return;

    final contact = SimpleContact(
      displayName: _nameController.text.trim(),
      phones: [SimplePhone(_phoneController.text.trim())],
    );

    Navigator.of(context).pop(contact);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Contact'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter contact details',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    (value == null || value.trim().isEmpty)
                        ? 'Please enter a name'
                        : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone number',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    (value == null || value.trim().isEmpty)
                        ? 'Please enter a phone number'
                        : null,
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submit,
                  child: const Text('Save'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

