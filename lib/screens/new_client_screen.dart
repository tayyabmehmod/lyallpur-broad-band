import 'package:flutter/material.dart';
import '../models/area.dart';
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
  final _initialPaymentController = TextEditingController();
  final _customPackageNameController = TextEditingController();

  String? _selectedArea;
  String? _selectedPackageName;
  DateTime _connectionDate = DateTime.now();
  bool _isSaving = false;

  final List<Map<String, String>> _packageOptions = [
    {'value': '2mb', 'label': '2 Mbps'},
    {'value': '4mb', 'label': '4 Mbps'},
    {'value': '6mb', 'label': '6 Mbps'},
    {'value': '8mb', 'label': '8 Mbps'},
    {'value': '10mb', 'label': '10 Mbps'},
    {'value': 'custom', 'label': 'Custom (Add Manually)'},
  ];

  bool get _isCustomPackage => _selectedPackageName == 'custom';

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
    _customPackageNameController.dispose();
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
    if (_selectedPackageName == null) {
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

      String pId;
      String pName;
      if (_isCustomPackage) {
        pId = 'custom';
        pName = _customPackageNameController.text.trim();
      } else {
        pId = _selectedPackageName!;
        pName = _packageOptions.firstWhere((opt) => opt['value'] == _selectedPackageName)['label']!;
      }

      await FirebaseService().addClient(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        area: _selectedArea ?? '',
        packageId: pId,
        packageName: pName,
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 750;

              final nameWidget = TextFormField(
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
              );

              final phoneWidget = TextFormField(
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
              );

              final areaWidget = StreamBuilder<List<AreaModel>>(
                stream: FirebaseService().getAreas(),
                initialData: FirebaseService.lastAreas,
                builder: (context, snapshot) {
                  final areas = snapshot.data ?? [];
                  return DropdownButtonFormField<String>(
                    value: _selectedArea,
                    decoration: const InputDecoration(
                      labelText: 'Select Area',
                      prefixIcon: Icon(Icons.map_outlined),
                    ),
                    items: [
                      const DropdownMenuItem<String>(
                        value: '',
                        child: Text('-- None / Blank --'),
                      ),
                      ...areas.map((area) {
                        return DropdownMenuItem<String>(
                          value: area.name,
                          child: Text(area.name),
                        );
                      }),
                    ],
                    onChanged: (val) {
                      setState(() {
                        _selectedArea = val;
                      });
                    },
                  );
                },
              );

              final packageWidget = DropdownButtonFormField<String>(
                value: _selectedPackageName,
                decoration: const InputDecoration(
                  labelText: 'Select Package *',
                  prefixIcon: Icon(Icons.speed_outlined),
                ),
                items: _packageOptions.map((opt) {
                  return DropdownMenuItem<String>(
                    value: opt['value']!,
                    child: Text(opt['label']!),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedPackageName = val;
                  });
                },
                validator: (val) => val == null ? 'Please select a package' : null,
              );

              final customPackageNameWidget = TextFormField(
                controller: _customPackageNameController,
                enabled: !_isSaving,
                decoration: const InputDecoration(
                  labelText: 'Custom Package Name *',
                  prefixIcon: Icon(Icons.speed_outlined),
                  hintText: 'e.g. 15 Mbps',
                ),
                validator: (value) {
                  if (_isCustomPackage && (value == null || value.trim().isEmpty)) {
                    return 'Please enter the custom package name';
                  }
                  return null;
                },
              );

              final totalBillWidget = TextFormField(
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
              );

              final initialPaymentWidget = TextFormField(
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
              );

              final dateWidget = TextFormField(
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
              );

              final remainingWidget = TextFormField(
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
              );

              return Column(
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

                  if (isWide) ...[
                    // First line: name, phone number, and area
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: nameWidget),
                        const SizedBox(width: 16),
                        Expanded(child: phoneWidget),
                        const SizedBox(width: 16),
                        Expanded(child: areaWidget),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Second line: package, total bill, paid or pending
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: packageWidget),
                        const SizedBox(width: 16),
                        Expanded(child: totalBillWidget),
                        const SizedBox(width: 16),
                        Expanded(child: initialPaymentWidget),
                      ],
                    ),
                    const SizedBox(height: 20),

                    if (_isCustomPackage) ...[
                      customPackageNameWidget,
                      const SizedBox(height: 20),
                    ],

                    // Third line: connection date, remaining dues
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: dateWidget),
                        const SizedBox(width: 16),
                        Expanded(child: remainingWidget),
                      ],
                    ),
                  ] else ...[
                    // Mobile single-column stacked layout
                    nameWidget,
                    const SizedBox(height: 20),
                    phoneWidget,
                    const SizedBox(height: 20),
                    areaWidget,
                    const SizedBox(height: 20),
                    packageWidget,
                    const SizedBox(height: 20),
                    if (_isCustomPackage) ...[
                      customPackageNameWidget,
                      const SizedBox(height: 20),
                    ],
                    totalBillWidget,
                    const SizedBox(height: 20),
                    initialPaymentWidget,
                    const SizedBox(height: 20),
                    dateWidget,
                    const SizedBox(height: 20),
                    remainingWidget,
                  ],

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
              );
            },
          ),
        ),
      ),
    );
  }
}
