import 'package:flutter/material.dart';
import '../models/area.dart';
import '../models/package.dart';
import '../services/firebase_service.dart';
import '../widgets/responsive_scaffold.dart';

class NewClientScreen extends StatefulWidget {
  const NewClientScreen({super.key});

  @override
  State<NewClientScreen> createState() => _NewClientScreenState();
}

class _NewClientScreenState extends State<NewClientScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _totalBillController = TextEditingController();
  final _initialPaymentController = TextEditingController(text: '0');

  String? _selectedArea;
  PackageModel? _selectedPackage;
  DateTime _connectionDate = DateTime.now();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Listen to bill and payment changes to rebuild the auto-calculated remaining field
    _totalBillController.addListener(_onAmountChanged);
    _initialPaymentController.addListener(_onAmountChanged);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _totalBillController.dispose();
    _initialPaymentController.dispose();
    super.dispose();
  }

  void _onAmountChanged() {
    setState(() {});
  }

  double get _remainingAmount {
    final bill = double.tryParse(_totalBillController.text) ?? 0.0;
    final paid = double.tryParse(_initialPaymentController.text) ?? 0.0;
    return bill - paid;
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _connectionDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: Theme.of(context).colorScheme.secondary, // Accent #185FA5
              onPrimary: Colors.white,
              surface: const Color(0xFF161B22),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _connectionDate) {
      setState(() {
        _connectionDate = picked;
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedArea == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an area')),
      );
      return;
    }
    if (_selectedPackage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a broadband package')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final bill = double.tryParse(_totalBillController.text) ?? 0.0;
      final paid = double.tryParse(_initialPaymentController.text) ?? 0.0;

      await FirebaseService().addClient(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        area: _selectedArea!,
        packageId: _selectedPackage!.id,
        packageName: _selectedPackage!.name,
        totalBill: bill,
        initialPayment: paid,
        connectionDate: _connectionDate,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Client added successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushReplacementNamed(context, '/dashboard');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding client: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ResponsiveScaffold(
      title: 'New Client',
      currentIndex: 3,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Register Broadband Subscriber',
                style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.tertiary,
                      fontWeight: FontWeight.w500,
                    ),
              ),
              const SizedBox(height: 24),

              // Full Name field
              TextFormField(
                controller: _nameController,
                enabled: !_isSaving,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Client Full Name *',
                  prefixIcon: Icon(Icons.person_outline),
                  hintText: 'e.g. Ali Raza',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter the client\'s name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Phone Number field
              TextFormField(
                controller: _phoneController,
                enabled: !_isSaving,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number *',
                  prefixIcon: Icon(Icons.phone_outlined),
                  hintText: 'e.g. 03001234567',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a phone number';
                  }
                  final cleanPhone = value.replaceAll(RegExp(r'\D'), '');
                  if (cleanPhone.length < 10 || cleanPhone.length > 11) {
                    return 'Phone number must be 10 or 11 digits';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Area Dropdown field
              StreamBuilder<List<AreaModel>>(
                stream: FirebaseService().getAreas(),
                builder: (context, snapshot) {
                  final areas = snapshot.data ?? [];
                  return DropdownButtonFormField<String>(
                    initialValue: _selectedArea,
                    decoration: const InputDecoration(
                      labelText: 'Select Area *',
                      prefixIcon: Icon(Icons.map_outlined),
                    ),
                    items: areas.map((area) {
                      return DropdownMenuItem<String>(
                        value: area.name,
                        child: Text(area.name),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedArea = val;
                      });
                    },
                    validator: (val) => val == null ? 'Please select an area' : null,
                  );
                },
              ),
              const SizedBox(height: 20),

              // Package Dropdown field
              StreamBuilder<List<PackageModel>>(
                stream: FirebaseService().getPackages(),
                builder: (context, snapshot) {
                  final packages = snapshot.data ?? [];
                  return DropdownButtonFormField<PackageModel>(
                    initialValue: _selectedPackage,
                    decoration: const InputDecoration(
                      labelText: 'Select Package *',
                      prefixIcon: Icon(Icons.speed_outlined),
                    ),
                    items: packages.map((pkg) {
                      return DropdownMenuItem<PackageModel>(
                        value: pkg,
                        child: Text('${pkg.name} - Rs. ${pkg.price.toStringAsFixed(0)}'),
                      );
                    }).toList(),
                    onChanged: (pkg) {
                      setState(() {
                        _selectedPackage = pkg;
                        if (pkg != null) {
                          _totalBillController.text = pkg.price.toStringAsFixed(0);
                        }
                      });
                    },
                    validator: (val) => val == null ? 'Please select a package' : null,
                  );
                },
              ),
              const SizedBox(height: 20),

              // Total Bill field
              TextFormField(
                controller: _totalBillController,
                enabled: !_isSaving,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Total Bill (PKR) *',
                  prefixIcon: Icon(Icons.payments_outlined),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter total bill amount';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid numeric value';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Initial Payment field
              TextFormField(
                controller: _initialPaymentController,
                enabled: !_isSaving,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Initial Paid Amount (PKR)',
                  prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return null;
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid numeric value';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Connection Date picker field
              TextFormField(
                readOnly: true,
                controller: TextEditingController(
                  text: "${_connectionDate.toLocal()}".split(' ')[0],
                ),
                enabled: !_isSaving,
                decoration: InputDecoration(
                  labelText: 'Connection Date *',
                  prefixIcon: const Icon(Icons.calendar_today_outlined),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.edit_calendar_outlined),
                    onPressed: () => _selectDate(context),
                  ),
                ),
                onTap: () => _selectDate(context),
              ),
              const SizedBox(height: 20),

              // Remaining Dues (Read Only auto calculated)
              TextFormField(
                readOnly: true,
                controller: TextEditingController(
                  text: _remainingAmount.toStringAsFixed(0),
                ),
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white70),
                decoration: const InputDecoration(
                  labelText: 'Remaining Balance (Auto-Calculated)',
                  prefixIcon: Icon(Icons.money_off_csred_outlined),
                  fillColor: Color(0xFF161B22),
                  filled: true,
                ),
              ),
              const SizedBox(height: 36),

              // Save Submit Button
              ElevatedButton(
                onPressed: _isSaving ? null : _handleSubmit,
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Add Client'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
