import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/area.dart';
import '../models/package.dart';
import '../models/client.dart';

class FirebaseService {
  // --- STREAM CACHE SYSTEM FOR INSTANT LOADING ---
  static DashboardStats? lastStats;
  static List<AreaModel>? lastAreas;
  static List<ClientModel>? lastClients;
  static List<Map<String, dynamic>>? lastPayments;

  static Stream<DashboardStats>? _statsStream;
  static Stream<List<AreaModel>>? _areasStream;
  static Stream<List<ClientModel>>? _clientsStream;
  static Stream<List<Map<String, dynamic>>>? _paymentsStream;

  // Check if Firebase is initialized
  static bool get isInitialized => Firebase.apps.isNotEmpty;

  // Background synchronizer to keep Firestore streams alive and eliminate time buffers
  static void startSyncing() {
    if (!isInitialized) return;

    // Subscribe permanently to keep the broadcast streams active and caching data
    FirebaseService().getDashboardStats().listen((_) {});
    FirebaseService().getAreas().listen((_) {});
    FirebaseService().getClients().listen((_) {});
    FirebaseService().getPayments().listen((_) {});
  }

  FirebaseAuth get auth {
    if (!isInitialized) {
      throw StateError('Firebase is not initialized.');
    }
    return FirebaseAuth.instance;
  }

  FirebaseFirestore get db {
    if (!isInitialized) {
      throw StateError('Firebase is not initialized.');
    }
    return FirebaseFirestore.instance;
  }

  // --- MOCK / OFFLINE ENGINE DATA ---
  
  static final StreamController<List<AreaModel>> _mockAreasController = 
      StreamController<List<AreaModel>>.broadcast();

  static final List<AreaModel> _mockAreas = [
    AreaModel(id: '1', name: 'Samanabad', clientCount: 3, createdAt: DateTime.now().subtract(const Duration(days: 30))),
    AreaModel(id: '2', name: 'Batala Colony', clientCount: 2, createdAt: DateTime.now().subtract(const Duration(days: 20))),
    AreaModel(id: '3', name: 'Peoples Colony', clientCount: 1, createdAt: DateTime.now().subtract(const Duration(days: 10))),
  ];

  static final List<PackageModel> _mockPackages = [
    PackageModel(id: 'p1', name: '10 Mbps', price: 1500.0),
    PackageModel(id: 'p2', name: '20 Mbps', price: 2500.0),
    PackageModel(id: 'p3', name: '30 Mbps', price: 3500.0),
    PackageModel(id: 'p4', name: '50 Mbps', price: 5000.0),
  ];

  static final List<ClientModel> _mockClients = [
    ClientModel(
      id: 'c1',
      name: 'Ali Raza',
      phone: '03001234567',
      area: 'Samanabad',
      packageId: 'p1',
      packageName: '10 Mbps',
      connectionDate: DateTime.now().subtract(const Duration(days: 25)),
      status: 'active',
      totalBill: 1500.0,
      totalPaid: 1500.0,
      remaining: 0.0,
      createdAt: DateTime.now().subtract(const Duration(days: 25)),
    ),
    ClientModel(
      id: 'c2',
      name: 'Muhammad Usman',
      phone: '03217654321',
      area: 'Batala Colony',
      packageId: 'p2',
      packageName: '20 Mbps',
      connectionDate: DateTime.now().subtract(const Duration(days: 45)),
      status: 'expired',
      totalBill: 2500.0,
      totalPaid: 1000.0,
      remaining: 1500.0,
      createdAt: DateTime.now().subtract(const Duration(days: 45)),
    ),
    ClientModel(
      id: 'c3',
      name: 'Hamza Khan',
      phone: '03339876543',
      area: 'Samanabad',
      packageId: 'p1',
      packageName: '10 Mbps',
      connectionDate: DateTime.now().subtract(const Duration(days: 5)),
      status: 'active',
      totalBill: 1500.0,
      totalPaid: 500.0,
      remaining: 1000.0,
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
    ClientModel(
      id: 'c4',
      name: 'Zainab Bibi',
      phone: '03454567890',
      area: 'Peoples Colony',
      packageId: 'p3',
      packageName: '30 Mbps',
      connectionDate: DateTime.now().subtract(const Duration(days: 12)),
      status: 'active',
      totalBill: 3500.0,
      totalPaid: 3500.0,
      remaining: 0.0,
      createdAt: DateTime.now().subtract(const Duration(days: 12)),
    ),
    ClientModel(
      id: 'c5',
      name: 'Ahmad Shah',
      phone: '03123456789',
      area: 'Samanabad',
      packageId: 'p2',
      packageName: '20 Mbps',
      connectionDate: DateTime.now().subtract(const Duration(days: 35)),
      status: 'expired',
      totalBill: 2500.0,
      totalPaid: 0.0,
      remaining: 2500.0,
      createdAt: DateTime.now().subtract(const Duration(days: 35)),
    ),
    ClientModel(
      id: 'c6',
      name: 'Fatima Nisar',
      phone: '03019876543',
      area: 'Batala Colony',
      packageId: 'p4',
      packageName: '50 Mbps',
      connectionDate: DateTime.now().subtract(const Duration(days: 2)),
      status: 'active',
      totalBill: 5000.0,
      totalPaid: 4000.0,
      remaining: 1000.0,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
  ];

  static final StreamController<DashboardStats> _mockStatsController = 
      StreamController<DashboardStats>.broadcast();

  static void _notifyMockAreas() {
    if (!_mockAreasController.isClosed) {
      _mockAreasController.add(List.unmodifiable(_mockAreas));
    }
  }

  static void _notifyMockStats() {
    if (!_mockStatsController.isClosed) {
      final total = _mockClients.length;
      final active = _mockClients.where((c) => c.status == 'active').length;
      final expired = _mockClients.where((c) => c.status == 'expired').length;
      final pending = _mockClients.map((c) => c.remaining).fold(0.0, (acc, val) => acc + val);
      _mockStatsController.add(DashboardStats(
        totalClients: total,
        activeClients: active,
        expiredClients: expired,
        totalPendingDues: pending,
      ));
    }
  }

  // --- SERVICES LOGIC ---

  // Admin Authentication helper with fallback for demo/mock login
  Future<UserCredential?> signInAdmin(String email, String password) async {
    if (!isInitialized) {
      // Simulate network request delay
      await Future.delayed(const Duration(milliseconds: 800));
      if (email == 'admin@lyallpur.com' && password == 'admin123') {
        return null; // Return null to represent successful demo bypass
      } else {
        throw FirebaseAuthException(
          code: 'wrong-password',
          message: 'Invalid admin credentials. Hint: use admin@lyallpur.com and password admin123 for Demo Mode.',
        );
      }
    }
    
    final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return credential;
  }

  // Logout admin helper
  Future<void> signOutAdmin() async {
    if (isInitialized) {
      await FirebaseAuth.instance.signOut();
    }
  }

  // Get real-time stats stream with fallback for Demo Mode
  Stream<DashboardStats> getDashboardStats() {
    if (!isInitialized) {
      Future.microtask(() => _notifyMockStats());
      return _mockStatsController.stream;
    }

    _statsStream ??= FirebaseFirestore.instance
        .collection('clients')
        .snapshots()
        .map((snapshot) {
      int total = snapshot.docs.length;
      int active = 0;
      int expired = 0;
      double pending = 0.0;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final status = data['status']?.toString().toLowerCase() ?? '';
        if (status == 'active') {
          active++;
        } else if (status == 'expired') {
          expired++;
        }

        final remaining = data.containsKey('remaining')
            ? (double.tryParse(data['remaining'].toString()) ?? 0.0)
            : 0.0;
        pending += remaining;
      }

      final stats = DashboardStats(
        totalClients: total,
        activeClients: active,
        expiredClients: expired,
        totalPendingDues: pending,
      );
      lastStats = stats;
      return stats;
    }).asBroadcastStream();

    return _statsStream!;
  }

  // Check duplicate area names (case-insensitive)
  Future<bool> isAreaNameDuplicate(String name, {String? excludeId}) async {
    final cleanName = name.trim().toLowerCase();
    
    if (!isInitialized) {
      return _mockAreas.any((a) => 
          a.name.trim().toLowerCase() == cleanName && a.id != excludeId);
    }

    final query = await FirebaseFirestore.instance
        .collection('areas')
        .where('name', isEqualTo: name.trim())
        .get();

    return query.docs.any((doc) => doc.id != excludeId);
  }

  // Stream lists of areas
  Stream<List<AreaModel>> getAreas() {
    if (!isInitialized) {
      Future.microtask(() => _notifyMockAreas());
      return _mockAreasController.stream;
    }

    _areasStream ??= FirebaseFirestore.instance
        .collection('areas')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) {
        final data = doc.data();
        return AreaModel(
          id: doc.id,
          name: data['name']?.toString() ?? '',
          clientCount: int.tryParse(data['clientCount']?.toString() ?? '') ?? 0,
          createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        );
      }).toList();
      lastAreas = list;
      return list;
    }).asBroadcastStream();

    return _areasStream!;
  }

  // Add new area
  Future<void> addArea(String name) async {
    if (await isAreaNameDuplicate(name)) {
      throw Exception('An area with the name "$name" already exists.');
    }

    if (!isInitialized) {
      await Future.delayed(const Duration(milliseconds: 200));
      _mockAreas.add(AreaModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name.trim(),
        clientCount: 0,
        createdAt: DateTime.now(),
      ));
      _notifyMockAreas();
      return;
    }

    await FirebaseFirestore.instance.collection('areas').add({
      'name': name.trim(),
      'clientCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Edit existing area
  Future<void> updateArea(String id, String newName) async {
    if (await isAreaNameDuplicate(newName, excludeId: id)) {
      throw Exception('An area with the name "$newName" already exists.');
    }

    if (!isInitialized) {
      await Future.delayed(const Duration(milliseconds: 200));
      final index = _mockAreas.indexWhere((a) => a.id == id);
      if (index != -1) {
        final existing = _mockAreas[index];
        _mockAreas[index] = AreaModel(
          id: existing.id,
          name: newName.trim(),
          clientCount: existing.clientCount,
          createdAt: existing.createdAt,
        );
        _notifyMockAreas();
      }
      return;
    }

    await FirebaseFirestore.instance.collection('areas').doc(id).update({
      'name': newName.trim(),
    });
  }

  // Delete existing area
  Future<void> deleteArea(String id) async {
    if (!isInitialized) {
      await Future.delayed(const Duration(milliseconds: 200));
      _mockAreas.removeWhere((a) => a.id == id);
      _notifyMockAreas();
      return;
    }

    await FirebaseFirestore.instance.collection('areas').doc(id).delete();
  }

  // Stream lists of broadband packages
  Stream<List<PackageModel>> getPackages() {
    if (!isInitialized) {
      return Stream.value(_mockPackages);
    }

    return FirebaseFirestore.instance
        .collection('packages')
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) {
        // Fallback default packages if database collection is empty
        return _mockPackages;
      }
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return PackageModel(
          id: doc.id,
          name: data['name']?.toString() ?? '',
          price: double.tryParse(data['price']?.toString() ?? '') ?? 0.0,
        );
      }).toList();
    });
  }

  // Create new client record with transaction/batch updates
  Future<void> addClient({
    required String name,
    required String phone,
    required String area,
    required String packageId,
    required String packageName,
    required double totalBill,
    required double initialPayment,
    required DateTime connectionDate,
  }) async {
    final remaining = totalBill - initialPayment;

    if (!isInitialized) {
      await Future.delayed(const Duration(milliseconds: 300));
      final newId = 'cli_${DateTime.now().millisecondsSinceEpoch}';

      // 1. Create mock client
      final newClient = ClientModel(
        id: newId,
        name: name.trim(),
        phone: phone.trim(),
        area: area,
        packageId: packageId,
        packageName: packageName,
        connectionDate: connectionDate,
        status: 'active',
        totalBill: totalBill,
        totalPaid: initialPayment,
        remaining: remaining,
        createdAt: DateTime.now(),
      );
      _mockClients.add(newClient);

      // 2. Increment client count of selected mock area
      final areaIndex = _mockAreas.indexWhere((a) => a.name == area);
      if (areaIndex != -1) {
        final existing = _mockAreas[areaIndex];
        _mockAreas[areaIndex] = AreaModel(
          id: existing.id,
          name: existing.name,
          clientCount: existing.clientCount + 1,
          createdAt: existing.createdAt,
        );
        _notifyMockAreas();
      }

      // 3. Broadcast updated stats
      _notifyMockStats();
      return;
    }

    // ONLINE TRANSACTION BATCH WRITES
    final clientRef = FirebaseFirestore.instance.collection('clients').doc();
    final batch = FirebaseFirestore.instance.batch();

    // 1. Write client document
    batch.set(clientRef, {
      'name': name.trim(),
      'phone': phone.trim(),
      'area': area,
      'packageId': packageId,
      'packageName': packageName,
      'connectionDate': connectionDate,
      'status': 'active',
      'totalBill': totalBill,
      'totalPaid': initialPayment,
      'remaining': remaining,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // 2. Write payment log if initialPayment > 0
    if (initialPayment > 0) {
      final paymentRef = FirebaseFirestore.instance.collection('payments').doc();
      batch.set(paymentRef, {
        'clientId': clientRef.id,
        'clientName': name.trim(),
        'amount': initialPayment,
        'date': connectionDate,
        'method': 'cash',
        'note': 'Initial payment',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    // 3. Increment area client count if area is not blank
    if (area.trim().isNotEmpty) {
      final areaQuery = await FirebaseFirestore.instance
          .collection('areas')
          .where('name', isEqualTo: area.trim())
          .limit(1)
          .get();

      if (areaQuery.docs.isNotEmpty) {
        final areaDoc = areaQuery.docs.first;
        batch.update(areaDoc.reference, {
          'clientCount': FieldValue.increment(1),
        });
      }
    }

    await batch.commit();
  }

  // Register admin helper with fallback for demo/mock mode
  Future<UserCredential?> registerAdmin(String email, String password) async {
    if (!isInitialized) {
      await Future.delayed(const Duration(milliseconds: 800));
      return null;
    }
    
    final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    
    if (credential.user != null) {
      await FirebaseFirestore.instance.collection('users').doc(credential.user!.uid).set({
        'email': email,
        'role': 'admin',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    return credential;
  }

  // Stream lists of clients, optionally filtered by status
  Stream<List<ClientModel>> getClients({String? status}) {
    if (!isInitialized) {
      if (status != null) {
        return Stream.value(_mockClients.where((c) => c.status == status).toList());
      }
      return Stream.value(_mockClients);
    }

    if (status != null) {
      return FirebaseFirestore.instance
          .collection('clients')
          .where('status', isEqualTo: status)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          final data = doc.data();
          
          DateTime connDate = DateTime.now();
          if (data['connectionDate'] != null) {
            if (data['connectionDate'] is Timestamp) {
              connDate = (data['connectionDate'] as Timestamp).toDate();
            } else {
              connDate = DateTime.tryParse(data['connectionDate'].toString()) ?? DateTime.now();
            }
          }

          DateTime createDate = DateTime.now();
          if (data['createdAt'] != null) {
            if (data['createdAt'] is Timestamp) {
              createDate = (data['createdAt'] as Timestamp).toDate();
            } else {
              createDate = DateTime.tryParse(data['createdAt'].toString()) ?? DateTime.now();
            }
          }

          return ClientModel(
            id: doc.id,
            name: data['name']?.toString() ?? '',
            phone: data['phone']?.toString() ?? '',
            area: data['area']?.toString() ?? '',
            packageId: data['packageId']?.toString() ?? '',
            packageName: data['packageName']?.toString() ?? '',
            connectionDate: connDate,
            status: data['status']?.toString() ?? 'active',
            totalBill: double.tryParse(data['totalBill']?.toString() ?? '') ?? 0.0,
            totalPaid: double.tryParse(data['totalPaid']?.toString() ?? '') ?? 0.0,
            remaining: double.tryParse(data['remaining']?.toString() ?? '') ?? 0.0,
            createdAt: createDate,
          );
        }).toList();
      });
    }

    _clientsStream ??= FirebaseFirestore.instance
        .collection('clients')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) {
        final data = doc.data();
        
        DateTime connDate = DateTime.now();
        if (data['connectionDate'] != null) {
          if (data['connectionDate'] is Timestamp) {
            connDate = (data['connectionDate'] as Timestamp).toDate();
          } else {
            connDate = DateTime.tryParse(data['connectionDate'].toString()) ?? DateTime.now();
          }
        }

        DateTime createDate = DateTime.now();
        if (data['createdAt'] != null) {
          if (data['createdAt'] is Timestamp) {
            createDate = (data['createdAt'] as Timestamp).toDate();
          } else {
            createDate = DateTime.tryParse(data['createdAt'].toString()) ?? DateTime.now();
          }
        }

        return ClientModel(
          id: doc.id,
          name: data['name']?.toString() ?? '',
          phone: data['phone']?.toString() ?? '',
          area: data['area']?.toString() ?? '',
          packageId: data['packageId']?.toString() ?? '',
          packageName: data['packageName']?.toString() ?? '',
          connectionDate: connDate,
          status: data['status']?.toString() ?? 'active',
          totalBill: double.tryParse(data['totalBill']?.toString() ?? '') ?? 0.0,
          totalPaid: double.tryParse(data['totalPaid']?.toString() ?? '') ?? 0.0,
          remaining: double.tryParse(data['remaining']?.toString() ?? '') ?? 0.0,
          createdAt: createDate,
        );
      }).toList();
      lastClients = list;
      return list;
    }).asBroadcastStream();

    return _clientsStream!;
  }

  // Get detailed client stream
  Stream<ClientModel?> getClientById(String id) {
    if (!isInitialized) {
      return Stream.value(_mockClients.firstWhere(
        (c) => c.id == id,
        orElse: () => _mockClients.first,
      ));
    }

    return FirebaseFirestore.instance.collection('clients').doc(id).snapshots().map((doc) {
      if (!doc.exists) return null;
      final data = doc.data() as Map<String, dynamic>;
      
      DateTime connDate = DateTime.now();
      if (data['connectionDate'] != null) {
        if (data['connectionDate'] is Timestamp) {
          connDate = (data['connectionDate'] as Timestamp).toDate();
        } else {
          connDate = DateTime.tryParse(data['connectionDate'].toString()) ?? DateTime.now();
        }
      }

      DateTime createDate = DateTime.now();
      if (data['createdAt'] != null) {
        if (data['createdAt'] is Timestamp) {
          createDate = (data['createdAt'] as Timestamp).toDate();
        } else {
          createDate = DateTime.tryParse(data['createdAt'].toString()) ?? DateTime.now();
        }
      }

      return ClientModel(
        id: doc.id,
        name: data['name']?.toString() ?? '',
        phone: data['phone']?.toString() ?? '',
        area: data['area']?.toString() ?? '',
        packageId: data['packageId']?.toString() ?? '',
        packageName: data['packageName']?.toString() ?? '',
        connectionDate: connDate,
        status: data['status']?.toString() ?? 'active',
        totalBill: double.tryParse(data['totalBill']?.toString() ?? '') ?? 0.0,
        totalPaid: double.tryParse(data['totalPaid']?.toString() ?? '') ?? 0.0,
        remaining: double.tryParse(data['remaining']?.toString() ?? '') ?? 0.0,
        createdAt: createDate,
      );
    });
  }

  // Renew client subscription
  Future<void> renewClient(String id, double paymentAmount) async {
    if (!isInitialized) {
      await Future.delayed(const Duration(milliseconds: 200));
      final index = _mockClients.indexWhere((c) => c.id == id);
      if (index != -1) {
        final existing = _mockClients[index];
        _mockClients[index] = ClientModel(
          id: existing.id,
          name: existing.name,
          phone: existing.phone,
          area: existing.area,
          packageId: existing.packageId,
          packageName: existing.packageName,
          connectionDate: DateTime.now(),
          status: 'active',
          totalBill: existing.totalBill,
          totalPaid: paymentAmount,
          remaining: existing.totalBill - paymentAmount,
          createdAt: existing.createdAt,
        );
        _notifyMockStats();
      }
      return;
    }

    final clientDoc = await FirebaseFirestore.instance.collection('clients').doc(id).get();
    if (!clientDoc.exists) return;
    
    final data = clientDoc.data()!;
    final name = data['name']?.toString() ?? '';
    final totalBill = double.tryParse(data['totalBill']?.toString() ?? '') ?? 0.0;
    
    final batch = FirebaseFirestore.instance.batch();
    
    batch.update(clientDoc.reference, {
      'status': 'active',
      'connectionDate': FieldValue.serverTimestamp(),
      'totalPaid': paymentAmount,
      'remaining': totalBill - paymentAmount,
    });

    final paymentRef = FirebaseFirestore.instance.collection('payments').doc();
    batch.set(paymentRef, {
      'clientId': id,
      'clientName': name,
      'amount': paymentAmount,
      'date': FieldValue.serverTimestamp(),
      'method': 'cash',
      'note': 'Subscription Renewal',
      'createdAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  // Suspend client subscription
  Future<void> suspendClient(String id) async {
    if (!isInitialized) {
      await Future.delayed(const Duration(milliseconds: 200));
      final index = _mockClients.indexWhere((c) => c.id == id);
      if (index != -1) {
        final existing = _mockClients[index];
        _mockClients[index] = ClientModel(
          id: existing.id,
          name: existing.name,
          phone: existing.phone,
          area: existing.area,
          packageId: existing.packageId,
          packageName: existing.packageName,
          connectionDate: existing.connectionDate,
          status: 'expired',
          totalBill: existing.totalBill,
          totalPaid: existing.totalPaid,
          remaining: existing.remaining,
          createdAt: existing.createdAt,
        );
        _notifyMockStats();
      }
      return;
    }

    await FirebaseFirestore.instance.collection('clients').doc(id).update({
      'status': 'expired',
    });
  }

  // Stream list of payment logs
  Stream<List<Map<String, dynamic>>> getPayments() {
    if (!isInitialized) {
      return Stream.value([
        {
          'clientName': 'Ali Raza',
          'amount': 1500.0,
          'note': 'Initial payment',
          'date': DateTime.now().subtract(const Duration(days: 25)),
          'type': 'payment',
        },
        {
          'clientName': 'Muhammad Usman',
          'amount': 1000.0,
          'note': 'Partial payment',
          'date': DateTime.now().subtract(const Duration(days: 45)),
          'type': 'payment',
        },
        {
          'clientName': 'Hamza Khan',
          'amount': 500.0,
          'note': 'Initial payment',
          'date': DateTime.now().subtract(const Duration(days: 5)),
          'type': 'payment',
        },
      ]);
    }

    _paymentsStream ??= FirebaseFirestore.instance
        .collection('payments')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) {
        final data = doc.data();
        DateTime dateVal = DateTime.now();
        if (data['date'] != null) {
          if (data['date'] is Timestamp) {
            dateVal = (data['date'] as Timestamp).toDate();
          } else {
            dateVal = DateTime.tryParse(data['date'].toString()) ?? DateTime.now();
          }
        }
        return {
          'id': doc.id,
          'clientId': data['clientId']?.toString() ?? '',
          'clientName': data['clientName']?.toString() ?? '',
          'amount': double.tryParse(data['amount']?.toString() ?? '') ?? 0.0,
          'note': data['note']?.toString() ?? '',
          'date': dateVal,
          'type': 'payment',
        };
      }).toList();
      lastPayments = list;
      return list;
    }).asBroadcastStream();

    return _paymentsStream!;
  }
}

class DashboardStats {
  final int totalClients;
  final int activeClients;
  final int expiredClients;
  final double totalPendingDues;

  DashboardStats({
    required this.totalClients,
    required this.activeClients,
    required this.expiredClients,
    required this.totalPendingDues,
  });
}
