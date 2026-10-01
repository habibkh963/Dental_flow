import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

class DatabaseService {
  DatabaseService._();
  static final DatabaseService instance = DatabaseService._();

  final _uuid = const Uuid();

  Future<void> init() async {
    // No-op for web preview. Uses in-memory store.
  }

  // In-memory stores
  final List<Map<String, dynamic>> _patients = [];
  final List<Map<String, dynamic>> _appointments = [];
  final List<Map<String, dynamic>> _inventory = [];
  final List<Map<String, dynamic>> _invoices = [];
  final List<Map<String, dynamic>> _invoiceLines = [];
  final List<Map<String, dynamic>> _appointmentMaterials = [];
  final Map<String, String> _settings = {};
  final List<Map<String, dynamic>> _payments = [];
  final List<Map<String, dynamic>> _patientFiles = [];
  final List<Map<String, dynamic>> _inventoryOutputs = [];

  // Patients CRUD
  Future<List<Map<String, dynamic>>> getPatients() async {
    final list = List<Map<String, dynamic>>.from(_patients);
    list.sort(
      (a, b) => ('${a['last_name']}${a['first_name']}').compareTo(
        '${b['last_name']}${b['first_name']}',
      ),
    );
    return list;
  }

  Future<String> addPatient(Map<String, dynamic> patient) async {
    final id = patient['id'] ?? _uuid.v4();
    final now = DateTime.now().toIso8601String();
    final data = {
      'id': id,
      'first_name': patient['first_name'] ?? '',
      'last_name': patient['last_name'] ?? '',
      'phone': patient['phone'] ?? '',
      'email': patient['email'] ?? '',
      'dob': patient['dob'] ?? '',
      'address': patient['address'] ?? '',
      'created_at': now,
      'updated_at': now,
    };
    _patients.add(data);
    return id;
  }

  Future<int> updatePatient(String id, Map<String, dynamic> updates) async {
    final idx = _patients.indexWhere((e) => e['id'] == id);
    if (idx == -1) return 0;
    updates['updated_at'] = DateTime.now().toIso8601String();
    _patients[idx] = {..._patients[idx], ...updates};
    return 1;
  }

  Future<int> deletePatient(String id) async {
    final before = _patients.length;
    _patients.removeWhere((e) => e['id'] == id);
    return before - _patients.length;
  }

  // Appointments CRUD
  Future<List<Map<String, dynamic>>> getAppointments({
    String? patientId,
  }) async {
    final list = List<Map<String, dynamic>>.from(
      _appointments.where(
        (e) => patientId == null || e['patient_id'] == patientId,
      ),
    );
    list.sort(
      (a, b) =>
          ('${b['date']} ${b['time']}').compareTo('${a['date']} ${a['time']}'),
    );
    return list;
  }

  Future<String> addAppointment(Map<String, dynamic> appointment) async {
    final id = appointment['id'] ?? _uuid.v4();
    final now = DateTime.now().toIso8601String();
    final data = {
      'id': id,
      'patient_id': appointment['patient_id'],
      'date': appointment['date'],
      'time': appointment['time'] ?? '',
      'status': appointment['status'] ?? 'scheduled',
      'notes': appointment['notes'] ?? '',
      'created_at': now,
      'updated_at': now,
    };
    _appointments.add(data);
    return id;
  }

  Future<int> updateAppointment(String id, Map<String, dynamic> updates) async {
    final idx = _appointments.indexWhere((e) => e['id'] == id);
    if (idx == -1) return 0;
    updates['updated_at'] = DateTime.now().toIso8601String();
    _appointments[idx] = {..._appointments[idx], ...updates};
    return 1;
  }

  Future<int> deleteAppointment(String id) async {
    final before = _appointments.length;
    _appointments.removeWhere((e) => e['id'] == id);
    _appointmentMaterials.removeWhere((e) => e['appointment_id'] == id);
    return before - _appointments.length;
  }

  Future<List<Map<String, dynamic>>> getAppointmentMaterials(
    String appointmentId,
  ) async {
    return List<Map<String, dynamic>>.from(
      _appointmentMaterials.where((e) => e['appointment_id'] == appointmentId),
    );
  }

  Future<String> addAppointmentMaterial(
    String appointmentId,
    String materialId,
    int quantity,
  ) async {
    final id = _uuid.v4();
    _appointmentMaterials.add({
      'id': id,
      'appointment_id': appointmentId,
      'material_id': materialId,
      'quantity': quantity,
    });
    return id;
  }

  Future<int> deleteAppointmentMaterials(String appointmentId) async {
    final before = _appointmentMaterials.length;
    _appointmentMaterials.removeWhere(
      (e) => e['appointment_id'] == appointmentId,
    );
    return before - _appointmentMaterials.length;
  }

  Future<int> countPatients() async => _patients.length;

  Future<int> countAppointmentsToday() async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return _appointments.where((e) => e['date'] == today).length;
  }

  Future<int> countPendingInvoices() async =>
      _invoices.where((e) => e['status'] == 'pending').length;

  Future<int> countLowStock({int threshold = 5}) async =>
      _inventory.where((e) => (e['qty'] ?? 0) <= threshold).length;

  // Inventory CRUD
  Future<List<Map<String, dynamic>>> getInventory() async {
    final list = List<Map<String, dynamic>>.from(_inventory);
    list.sort((a, b) => ('${a['name']}').compareTo('${b['name']}'));
    return list;
  }

  Future<String> addInventoryItem(Map<String, dynamic> item) async {
    final id = item['id'] ?? _uuid.v4();
    final data = {
      'id': id,
      'name': item['name'] ?? '',
      'qty': item['qty'] ?? 0,
      'threshold': item['threshold'] ?? 0,
      'unit': item['unit'] ?? 'وحدة',
    };
    _inventory.add(data);
    return id;
  }

  Future<int> updateInventoryItem(
    String id,
    Map<String, dynamic> updates,
  ) async {
    final idx = _inventory.indexWhere((e) => e['id'] == id);
    if (idx == -1) return 0;
    _inventory[idx] = {..._inventory[idx], ...updates};
    return 1;
  }

  Future<int> deleteInventoryItem(String id) async {
    final before = _inventory.length;
    _inventory.removeWhere((e) => e['id'] == id);
    return before - _inventory.length;
  }

  // Invoices CRUD
  Future<List<Map<String, dynamic>>> getInvoices({String? patientId}) async {
    final list = List<Map<String, dynamic>>.from(
      _invoices.where((e) => patientId == null || e['patient_id'] == patientId),
    );
    list.sort((a, b) => ('${b['issued_at']}').compareTo('${a['issued_at']}'));
    return list;
  }

  Future<String> addInvoice(Map<String, dynamic> invoice) async {
    final id = invoice['id'] ?? _uuid.v4();
    final now = DateTime.now().toIso8601String();
    final data = {
      'id': id,
      'patient_id': invoice['patient_id'],
      'total': invoice['total'] ?? 0.0,
      'status': invoice['status'] ?? 'pending',
      'type_of_treatment': invoice['type_of_treatment'] ?? '',
      'issued_at': invoice['issued_at'] ?? now,
    };
    _invoices.add(data);
    return id;
  }

  Future<Map<String, dynamic>?> getInvoice(String id) async {
    for (final invoice in _invoices) {
      if (invoice['id'] == id) return Map<String, dynamic>.from(invoice);
    }
    return null;
  }

  Future<Map<String, dynamic>?> getLatestInvoiceByPatientId(
    String patientId,
  ) async {
    final list = _invoices.where((e) => e['patient_id'] == patientId).toList();
    if (list.isEmpty) return null;
    list.sort((a, b) => ('${b['issued_at']}').compareTo('${a['issued_at']}'));
    return Map<String, dynamic>.from(list.first);
  }

  Future<List<Map<String, dynamic>>> getInvoiceLines(String invoiceId) async {
    return List<Map<String, dynamic>>.from(
      _invoiceLines.where((e) => e['invoice_id'] == invoiceId),
    );
  }

  Future<int> updateInvoice(String id, Map<String, dynamic> updates) async {
    final idx = _invoices.indexWhere((e) => e['id'] == id);
    if (idx == -1) return 0;
    _invoices[idx] = {..._invoices[idx], ...updates};
    return 1;
  }

  Future<int> deleteInvoice(String id) async {
    final before = _invoices.length;
    _invoices.removeWhere((e) => e['id'] == id);
    return before - _invoices.length;
  }

  // Settings key-value
  Future<String?> getSetting(String key) async => _settings[key];

  Future<void> setSetting(String key, String value) async {
    _settings[key] = value;
  }

  // Payments CRUD and helpers
  Future<List<Map<String, dynamic>>> getPayments(String invoiceId) async {
    final list = List<Map<String, dynamic>>.from(
      _payments.where((e) => e['invoice_id'] == invoiceId),
    );
    list.sort((a, b) => ('${b['paid_at']}').compareTo('${a['paid_at']}'));
    return list;
  }

  Future<String> addPayment(Map<String, dynamic> payment) async {
    final id = payment['id'] ?? _uuid.v4();
    final now = DateTime.now().toIso8601String();
    final data = {
      'id': id,
      'invoice_id': payment['invoice_id'],
      'amount': payment['amount'] ?? 0.0,
      'method': payment['method'] ?? 'cash',
      'note': payment['note'] ?? '',
      'paid_at': payment['paid_at'] ?? now,
    };
    _payments.add(data);
    await _syncInvoicePaymentStatus(payment['invoice_id']);
    return id;
  }

  Future<void> _syncInvoicePaymentStatus(String invoiceId) async {
    final balance = await getInvoiceBalance(invoiceId);
    final idx = _invoices.indexWhere((e) => e['id'] == invoiceId);
    if (idx == -1) return;
    if (balance <= 0) {
      _invoices[idx] = {..._invoices[idx], 'status': 'paid'};
    } else if (_invoices[idx]['status'] == 'paid') {
      _invoices[idx] = {..._invoices[idx], 'status': 'pending'};
    }
  }

  Future<int> deletePayment(String id) async {
    final payment = _payments.firstWhere(
      (e) => e['id'] == id,
      orElse: () => {},
    );
    final invoiceId = payment['invoice_id']?.toString();
    final before = _payments.length;
    _payments.removeWhere((e) => e['id'] == id);
    if (invoiceId != null && invoiceId.isNotEmpty) {
      await _syncInvoicePaymentStatus(invoiceId);
    }
    return before - _payments.length;
  }

  Future<double> getInvoiceBalance(String invoiceId) async {
    final inv = _invoices.firstWhere(
      (e) => e['id'] == invoiceId,
      orElse: () => {},
    );
    final total = (inv['total'] ?? 0.0) as double;
    final paid = _payments
        .where((e) => e['invoice_id'] == invoiceId)
        .fold<double>(0.0, (sum, e) => sum + ((e['amount'] ?? 0.0) as double));
    return total - paid;
  }

  // Patient files CRUD
  Future<List<Map<String, dynamic>>> getPatientFiles(String patientId) async {
    final list = List<Map<String, dynamic>>.from(
      _patientFiles.where((e) => e['patient_id'] == patientId),
    );
    list.sort(
      (a, b) => ('${b['uploaded_at']}').compareTo('${a['uploaded_at']}'),
    );
    return list;
  }

  Future<String> addPatientFile(Map<String, dynamic> fileRec) async {
    final id = fileRec['id'] ?? _uuid.v4();
    final now = DateTime.now().toIso8601String();
    final data = {
      'id': id,
      'patient_id': fileRec['patient_id'],
      'file_name': fileRec['file_name'] ?? '',
      'file_path': fileRec['file_path'] ?? '',
      'uploaded_at': fileRec['uploaded_at'] ?? now,
    };
    _patientFiles.add(data);
    return id;
  }

  Future<int> deletePatientFile(String id) async {
    final before = _patientFiles.length;
    _patientFiles.removeWhere((e) => e['id'] == id);
    return before - _patientFiles.length;
  }

  // Web stub: copying local files is not supported on web. Return empty path.
  Future<String> copyPatientFile(String sourcePath, String patientId) async {
    return '';
  }

  // Helpers
  Future<List<Map<String, dynamic>>> getTodayAppointments() async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final appointments = _appointments
        .where((e) => e['date'] == today)
        .toList();
    appointments.sort((a, b) => ('${a['time']}').compareTo('${b['time']}'));
    return appointments;
  }

  Future<List<Map<String, dynamic>>> getLowStockItems({
    int threshold = 3,
  }) async {
    final items = _inventory
        .where((e) => (e['qty'] ?? 0) <= threshold)
        .toList();
    items.sort((a, b) => (a['qty'] ?? 0).compareTo(b['qty'] ?? 0));
    return items;
  }

  Future<Map<String, dynamic>?> getPatientById(String id) async {
    try {
      return _patients.firstWhere((e) => e['id'] == id);
    } catch (_) {
      return null;
    }
  }

  // Inventory Outputs (Daily Inventory Tracking)
  Future<List<Map<String, dynamic>>> getInventoryOutputs() async {
    return List<Map<String, dynamic>>.from(
      _inventoryOutputs..sort(
        (a, b) => ('${b['created_at']}').compareTo('${a['created_at']}'),
      ),
    );
  }

  Future<String> addInventoryOutput(Map<String, dynamic> data) async {
    final id = data['id'] ?? _uuid.v4();
    final now = DateTime.now().toIso8601String();
    final output = {
      'id': id,
      'item_id': data['item_id'] ?? '',
      'item_name': data['item_name'] ?? '',
      'quantity': data['quantity'] ?? 0.0,
      'unit': data['unit'] ?? 'وحدة',
      'price': data['price'] ?? 0.0,
      'date': data['date'] ?? now,
      'created_at': data['created_at'] ?? now,
    };
    _inventoryOutputs.add(output);
    return id;
  }

  Future<int> deleteInventoryOutput(String id) async {
    final before = _inventoryOutputs.length;
    _inventoryOutputs.removeWhere((e) => e['id'] == id);
    return before - _inventoryOutputs.length;
  }

  Future<void> clearInventoryOutputs() async {
    _inventoryOutputs.clear();
  }

  Future<List<Map<String, dynamic>>> getAllPayments() async {
    return List<Map<String, dynamic>>.from(
      _payments
        ..sort((a, b) => ('${b['paid_at']}').compareTo('${a['paid_at']}')),
    );
  }
}
