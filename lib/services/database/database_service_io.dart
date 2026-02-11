import 'dart:developer';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

class DatabaseService {
  DatabaseService._();
  static final DatabaseService instance = DatabaseService._();

  Database? _db;
  final _uuid = const Uuid();

  Future<void> init() async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    _db = await _openDb();
    // await db.execute("PRAGMA foreign_keys = ON;");
    await _createTables();
  }

  Future<Database> _openDb() async {
    final appDoc = await getApplicationSupportDirectory();
    final dbPath = p.join(appDoc.path, 'dental_clinic.db');
    final factory = databaseFactoryFfi;
    return await factory.openDatabase(dbPath);
  }

  Database get db {
    final database = _db;
    if (database == null) {
      throw StateError(
        'Database not initialized. Call DatabaseService.instance.init() first.',
      );
    }
    return database;
  }

  Future<void> _createTables() async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS patients (
        id TEXT PRIMARY KEY,
        first_name TEXT,
        last_name TEXT,
        phone TEXT,
        email TEXT,
        dob TEXT,
        address TEXT,
        diseases TEXT,
        created_at TEXT,
        updated_at TEXT
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS appointments (
        id TEXT PRIMARY KEY,
        patient_id TEXT,
        date TEXT,
        time TEXT,
        status TEXT,
        notes TEXT,
        materials_used TEXT,
        created_at TEXT,
        updated_at TEXT,
        FOREIGN KEY(patient_id) REFERENCES patients(id) ON DELETE CASCADE
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS treatments (
        id TEXT PRIMARY KEY,
        appointment_id TEXT,
        description TEXT,
        cost REAL,
        FOREIGN KEY(appointment_id) REFERENCES appointments(id) ON DELETE CASCADE
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS appointment_materials (
        id TEXT PRIMARY KEY,
        appointment_id TEXT,
        material_id TEXT,
        quantity INTEGER,
        FOREIGN KEY(appointment_id) REFERENCES appointments(id) ON DELETE CASCADE,
        FOREIGN KEY(material_id) REFERENCES inventory(id) ON DELETE CASCADE
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS invoices (
        id TEXT PRIMARY KEY,
        patient_id TEXT,
        total REAL,
        status TEXT,
        issued_at TEXT, 
         type_of_treatment TEXT,
        FOREIGN KEY(patient_id) REFERENCES patients(id)
      );
    ''');

    // Invoice lines: each invoice can have multiple line items with optional material reference
    await db.execute('''
      CREATE TABLE IF NOT EXISTS invoice_lines (
        id TEXT PRIMARY KEY,
        invoice_id TEXT,
        material_id TEXT,
        description TEXT,
        quantity INTEGER,
        unit_price REAL,
        line_total REAL,
        FOREIGN KEY(invoice_id) REFERENCES invoices(id) ON DELETE CASCADE,
        FOREIGN KEY(material_id) REFERENCES inventory(id) ON DELETE SET NULL
      );
    ''');

    // New: payments per invoice
    await db.execute('''
      CREATE TABLE IF NOT EXISTS payments (
        id TEXT PRIMARY KEY,
        invoice_id TEXT,
        amount REAL,
        method TEXT,
        note TEXT,
        paid_at TEXT,
        FOREIGN KEY(invoice_id) REFERENCES invoices(id) ON DELETE CASCADE
      );
    ''');

    // New: patient files storage
    await db.execute('''
      CREATE TABLE IF NOT EXISTS patient_files (
        id TEXT PRIMARY KEY,
        patient_id TEXT,
        file_name TEXT,
        file_path TEXT,
        uploaded_at TEXT,
        FOREIGN KEY(patient_id) REFERENCES patients(id) ON DELETE CASCADE
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS inventory (
        id TEXT PRIMARY KEY,
        name TEXT,
        qty INTEGER,
        threshold INTEGER
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS staff (
        id TEXT PRIMARY KEY,
        name TEXT,
        role TEXT,
        phone TEXT,
        email TEXT
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS kv_settings (
        key TEXT PRIMARY KEY,
        value TEXT
      );
    ''');

    // Inventory outputs (used/delivered items) - for daily inventory tracking
    await db.execute('''
      CREATE TABLE IF NOT EXISTS inventory_outputs (
        id TEXT PRIMARY KEY,
        item_id TEXT,
        item_name TEXT,
        quantity REAL,
        unit TEXT,
        price REAL,
        date TEXT,
        created_at TEXT,
        FOREIGN KEY(item_id) REFERENCES inventory(id) ON DELETE SET NULL
      );
    ''');

    // Migration: ensure appointments table has 'materials_used' column (for older DBs)
    try {
      final cols = await db.rawQuery("PRAGMA table_info('appointments');");
      final hasMaterials = cols.any((c) => c['name'] == 'materials_used');
      if (!hasMaterials) {
        await db.execute(
          'ALTER TABLE appointments ADD COLUMN materials_used TEXT;',
        );
      }
    } catch (_) {
      // ignore migration errors; table may not exist yet or PRAGMA unsupported
    }
    // Migration: ensure inventory_outputs table has 'price' column (for older DBs)
    try {
      final cols = await db.rawQuery("PRAGMA table_info('inventory_outputs');");
      final hasPrice = cols.any((c) => c['name'] == 'price');
      if (!hasPrice) {
        await db.execute(
          'ALTER TABLE inventory_outputs ADD COLUMN price REAL DEFAULT 0.0;',
        );
      }
    } catch (_) {
      // ignore migration errors
    }
    // Migration: ensure patients table has 'diseases' column (for older DBs)
    try {
      final cols = await db.rawQuery("PRAGMA table_info('patients');");
      final hasDiseases = cols.any((c) => c['name'] == 'diseases');
      if (!hasDiseases) {
        await db.execute('ALTER TABLE patients ADD COLUMN diseases TEXT;');
      }
    } catch (_) {
      // ignore migration errors
    }

    // Migration: ensure invoice_lines table has 'material_id' column (for older DBs)
    try {
      final cols = await db.rawQuery("PRAGMA table_info('invoice_lines');");
      final hasMaterialId = cols.any((c) => c['name'] == 'material_id');
      if (!hasMaterialId) {
        await db.execute(
          'ALTER TABLE invoice_lines ADD COLUMN material_id TEXT;',
        );
      }
    } catch (_) {
      // ignore migration errors
    }
  }

  // Patients CRUD
  Future<List<Map<String, dynamic>>> getPatients() async {
    return await db.query('patients', orderBy: 'last_name, first_name');
  }

  Future<int> getPatientsCount() async {
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM patients');
    return result.isNotEmpty ? result.first['count'] as int : 0;
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
      'diseases': patient['diseases'] ?? '',
      'created_at': now,
      'updated_at': now,
    };
    await db.insert('patients', data);
    return id;
  }

  Future<int> updatePatient(String id, Map<String, dynamic> updates) async {
    updates['updated_at'] = DateTime.now().toIso8601String();
    return await db.update(
      'patients',
      updates,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deletePatient(String id) async {
    return await db.delete('patients', where: 'id = ?', whereArgs: [id]);
  }

  // Appointments CRUD
  Future<List<Map<String, dynamic>>> getAppointments({
    String? patientId,
  }) async {
    if (patientId != null) {
      return await db.query(
        'appointments',
        where: 'patient_id = ?',
        whereArgs: [patientId],
        orderBy: 'date DESC, time DESC',
      );
    }
    return await db.query('appointments', orderBy: 'date DESC, time DESC');
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
      'materials_used': appointment['materials_used'] ?? '',
      'created_at': now,
      'updated_at': now,
    };
    await db.insert('appointments', data);
    return id;
  }

  Future<int> updateAppointment(String id, Map<String, dynamic> updates) async {
    updates['updated_at'] = DateTime.now().toIso8601String();
    return await db.update(
      'appointments',
      updates,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteAppointment(String id) async {
    return await db.delete('appointments', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> countPatients() async {
    final res = await db.rawQuery('SELECT COUNT(*) as c FROM patients');
    return (res.first['c'] as int?) ?? 0;
  }

  Future<int> countAppointmentsToday() async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final res = await db.rawQuery(
      'SELECT COUNT(*) as c FROM appointments WHERE date = ?',
      [today],
    );
    return (res.first['c'] as int?) ?? 0;
  }

  Future<int> countPendingInvoices() async {
    final res = await db.rawQuery(
      "SELECT COUNT(*) as c FROM invoices WHERE status = 'pending'",
    );
    return (res.first['c'] as int?) ?? 0;
  }

  Future<int> countLowStock({int threshold = 5}) async {
    final res = await db.rawQuery(
      'SELECT COUNT(*) as c FROM inventory WHERE qty <= ?',
      [threshold],
    );
    return (res.first['c'] as int?) ?? 0;
  }

  // Inventory CRUD
  Future<List<Map<String, dynamic>>> getInventory() async {
    return await db.query('inventory', orderBy: 'name');
  }

  Future<String> addInventoryItem(Map<String, dynamic> item) async {
    final id = item['id'] ?? _uuid.v4();
    final data = {
      'id': id,
      'name': item['name'] ?? '',
      'qty': item['qty'] ?? 0,
      'threshold': item['threshold'] ?? 0,
    };
    await db.insert('inventory', data);
    return id;
  }

  Future<int> updateInventoryItem(
    String id,
    Map<String, dynamic> updates,
  ) async {
    return await db.update(
      'inventory',
      updates,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteInventoryItem(String id) async {
    return await db.delete('inventory', where: 'id = ?', whereArgs: [id]);
  }

  // Appointment Materials CRUD
  Future<List<Map<String, dynamic>>> getAppointmentMaterials(
    String appointmentId,
  ) async {
    return await db.rawQuery(
      '''
      SELECT am.id, am.material_id, am.quantity, i.name, i.qty as stock_qty
      FROM appointment_materials am
      JOIN inventory i ON am.material_id = i.id
      WHERE am.appointment_id = ?
    ''',
      [appointmentId],
    );
  }

  Future<String> addAppointmentMaterial(
    String appointmentId,
    String materialId,
    int quantity,
  ) async {
    final id = _uuid.v4();
    final data = {
      'id': id,
      'appointment_id': appointmentId,
      'material_id': materialId,
      'quantity': quantity,
    };
    await db.insert('appointment_materials', data);
    return id;
  }

  Future<int> deleteAppointmentMaterial(String id) async {
    return await db.delete(
      'appointment_materials',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteAppointmentMaterials(String appointmentId) async {
    return await db.delete(
      'appointment_materials',
      where: 'appointment_id = ?',
      whereArgs: [appointmentId],
    );
  }

  // Invoices CRUD
  Future<List<Map<String, dynamic>>> getInvoices({String? patientId}) async {
    if (patientId != null) {
      return await db.query(
        'invoices',
        where: 'patient_id = ?',
        whereArgs: [patientId],
        orderBy: 'issued_at DESC',
      );
    }
    return await db.query('invoices', orderBy: 'issued_at DESC');
  }

  Future<String> addInvoice(Map<String, dynamic> invoice) async {
    final id = invoice['id'] ?? _uuid.v4();
    final now = DateTime.now().toIso8601String();

    final data = {
      'id': id,
      'patient_id': invoice['patient_id'],
      'total': invoice['total'] ?? 0.0,
      'type_of_treatment': invoice['type_of_treatment'] ?? '',
      'issued_at': invoice['issued_at'] ?? now,
    };

    final existing = await db.query(
      'invoices',
      where: 'patient_id = ?',
      whereArgs: [invoice['patient_id']],
      limit: 1,
    );

    if (existing.isNotEmpty) {
      final invoiceHere = Map<String, dynamic>.from(existing.first);

      final oldTotal = (invoiceHere['total'] as num?) ?? 0;
      final newTotal = (invoice['total'] as num?) ?? 0;

      invoiceHere['total'] = oldTotal + newTotal;
      invoiceHere['type_of_treatment'] = invoice['type_of_treatment'];

      await db.update(
        'invoices',
        invoiceHere,
        where: 'id = ?',
        whereArgs: [invoiceHere['id']],
      );

      return invoiceHere['id'];
    } else {
      // ✅ إضافة جديدة
      await db.insert('invoices', data);
      return id;
    }
  }

  // Future<String> addInvoice(Map<String, dynamic> invoice) async {
  //   final id = invoice['id'] ?? _uuid.v4();
  //   final now = DateTime.now().toIso8601String();
  //   final data = {
  //     'id': id,
  //     'patient_id': invoice['patient_id'],
  //     'total': invoice['total'] ?? 0.0,
  //     'status': invoice['status'] ?? 'pending',
  //     'issued_at': now,
  //   };
  //   await db.insert('invoices', data);
  //   return id;
  // }

  // Future<int> updateInvoice(String id, Map<String, dynamic> updates) async {
  //   return await db.update(
  //     'invoices',
  //     updates,
  //     where: 'id = ?',
  //     whereArgs: [id],
  //   );
  // }
  Future<Map<String, dynamic>?> getInvoice(String id) async {
    final result = await db.query(
      'invoices',
      where: 'patient_id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (result.isNotEmpty) {
      return result.first;
    }
    return null;
  }

  Future<int> deleteInvoice(String id) async {
    return await db.delete('invoices', where: 'id = ?', whereArgs: [id]);
  }

  // Invoice lines CRUD
  Future<List<Map<String, dynamic>>> getInvoiceLines(String invoiceId) async {
    final lines = await db.rawQuery(
      '''
      SELECT 
        il.id, 
        il.invoice_id, 
        il.material_id, 
        il.description, 
        il.quantity, 
        il.unit_price, 
        il.line_total,
        i.name as material_name,
        i.qty as material_stock
      FROM invoice_lines il
      LEFT JOIN inventory i ON il.material_id = i.id
      WHERE il.invoice_id = ?
      ORDER BY il.rowid
    ''',
      [invoiceId],
    );
    return lines;
  }

  Future<String> addInvoiceLine(Map<String, dynamic> line) async {
    final id = line['id'] ?? _uuid.v4();
    final quantity = (line['quantity'] ?? 1) as int;
    final unitPrice = (line['unit_price'] ?? 0) as num;
    final lineTotal = quantity * unitPrice.toDouble();
    final data = {
      'id': id,
      'invoice_id': line['invoice_id'],
      // 'material_id': line['material_id'],
      'description': line['description'] ?? '',
      // 'quantity': quantity,
      // 'unit_price': unitPrice,
      'line_total': lineTotal,
    };
    await db.insert('invoice_lines', data);
    // Recalculate invoice total
    await _recalculateInvoiceTotal(line['invoice_id']);
    return id;
  }

  Future<int> updateInvoiceLine(String id, Map<String, dynamic> updates) async {
    if (updates.containsKey('quantity') || updates.containsKey('unit_price')) {
      final current = await db.query(
        'invoice_lines',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (current.isNotEmpty) {
        final existing = current.first;
        final qty = updates['quantity'] ?? existing['quantity'];
        final unit = updates['unit_price'] ?? existing['unit_price'];
        updates['line_total'] =
            (qty as num).toDouble() * (unit as num).toDouble();
      }
    }
    final res = await db.update(
      'invoice_lines',
      updates,
      where: 'id = ?',
      whereArgs: [id],
    );
    // find invoice id and recalc
    final row = await db.query(
      'invoice_lines',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (row.isNotEmpty)
      await _recalculateInvoiceTotal(row.first['invoice_id'] as String);
    return res;
  }

  Future<int> deleteInvoiceLine(String id) async {
    // get invoice id before delete
    final row = await db.query(
      'invoice_lines',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (row.isEmpty) return 0;
    final invoiceId = row.first['invoice_id'] as String;
    final res = await db.delete(
      'invoice_lines',
      where: 'id = ?',
      whereArgs: [id],
    );
    await _recalculateInvoiceTotal(invoiceId);
    return res;
  }

  Future<int> deleteInvoiceLines(String invoiceId) async {
    return await db.delete(
      'invoice_lines',
      where: 'invoice_id = ?',
      whereArgs: [invoiceId],
    );
  }

  Future<void> _recalculateInvoiceTotal(String invoiceId) async {
    final res = await db.rawQuery(
      'SELECT COALESCE(SUM(line_total),0) as total FROM invoice_lines WHERE invoice_id = ?',
      [invoiceId],
    );
    final total = (res.first['total'] as num?)?.toDouble() ?? 0.0;
    await db.update(
      'invoices',
      {'total': total},
      where: 'id = ?',
      whereArgs: [invoiceId],
    );
  }

  // Settings key-value
  Future<String?> getSetting(String key) async {
    final res = await db.query(
      'kv_settings',
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (res.isEmpty) return null;
    return res.first['value'] as String?;
  }

  Future<void> setSetting(String key, String value) async {
    await db.insert('kv_settings', {
      'key': key,
      'value': value,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // Payments CRUD and helpers
  Future<List<Map<String, dynamic>>> getPayments(String invoiceId) async {
    return await db.query(
      'payments',
      where: 'invoice_id = ?',
      whereArgs: [invoiceId],
      orderBy: 'paid_at DESC',
    );
  }

  Future<String> addPayment(Map<String, dynamic> payment) async {
    final id = payment['id'] ?? _uuid.v4();
    final now = DateTime.now().toIso8601String();
    final data = {
      'id': id,
      'invoice_id': payment['invoice_id'],
      'amount': payment['amount'] ?? 0.0,
      'method': payment['method'] ?? 'نقدي',
      'note': payment['note'] ?? '',
      'paid_at': payment['paid_at'] ?? now,
    };
    await db.insert('payments', data);
    return id;
  }

  Future<int> deletePayment(String id) async {
    return await db.delete('payments', where: 'id = ?', whereArgs: [id]);
  }

  Future<double> getInvoiceBalance(String invoiceId) async {
    final totalRes = await db.query(
      'invoices',
      columns: ['total'],
      where: 'id = ?',
      whereArgs: [invoiceId],
    );
    final total =
        (totalRes.isNotEmpty ? (totalRes.first['total'] as num?) : 0) ?? 0;
    final paidRes = await db.rawQuery(
      'SELECT COALESCE(SUM(amount),0) as paid FROM payments WHERE invoice_id = ?',
      [invoiceId],
    );
    final paid = (paidRes.first['paid'] as num?) ?? 0;
    return (total.toDouble() - paid.toDouble());
  }

  // Return all payments (useful for reporting)
  Future<List<Map<String, dynamic>>> getAllPayments() async {
    return await db.query('payments', orderBy: 'paid_at DESC');
  }

  // Patient files CRUD
  Future<List<Map<String, dynamic>>> getPatientFiles(String patientId) async {
    return await db.query(
      'patient_files',
      where: 'patient_id = ?',
      whereArgs: [patientId],
      orderBy: 'uploaded_at DESC',
    );
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
    await db.insert('patient_files', data);
    return id;
  }

  Future<int> deletePatientFile(String id) async {
    return await db.delete('patient_files', where: 'id = ?', whereArgs: [id]);
  }

  Future<String> copyPatientFile(String sourcePath, String patientId) async {
    final appDoc = await getApplicationSupportDirectory();
    final dir = Directory(p.join(appDoc.path, 'patient_files', patientId));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    final src = File(sourcePath);
    final destPath = p.join(dir.path, p.basename(sourcePath));
    await src.copy(destPath);
    return destPath;
  }

  // Helpers
  Future<List<Map<String, dynamic>>> getTodayAppointments() async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final appointments = await db.rawQuery(
      '''
      SELECT 
        a.id, 
        a.patient_id, 
        a.date, 
        a.time, 
        a.status, 
        a.notes,
        p.first_name,
        p.last_name,
        p.phone
      FROM appointments a
      JOIN patients p ON a.patient_id = p.id
      WHERE a.date = ?
      ORDER BY a.time
    ''',
      [today],
    );
    return appointments;
  }

  Future<List<Map<String, dynamic>>> getLowStockItems({
    int threshold = 3,
  }) async {
    final items = await db.rawQuery(
      '''
      SELECT 
        id,
        name,
        qty,
        threshold
      FROM inventory
      WHERE qty <= ?
      ORDER BY qty ASC
    ''',
      [threshold],
    );
    return items;
  }

  Future<void> deleteAllData() async {
    await db.transaction((txn) async {
      await txn.delete('invoice_lines');
      await txn.delete('invoices');
      await txn.delete('appointment_materials');
      await txn.delete('appointments');
      await txn.delete('inventory');

      await txn.delete('patients');
    });
  }

  Future<String?> exportDB() async {
    // إذا كان Windows/Linux/Mac نتعامل مع sqflite_common_ffi
    String dbFullPath;

    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      final projectDir = await getApplicationSupportDirectory();
      log(projectDir.path);
      dbFullPath = '${projectDir.path}/dental_clinic.db';
    } else {
      // موبايل
      var dbPath = await getDatabasesPath();
      dbFullPath = '$dbPath/dental_clinic.db';
    }

    final source = File(dbFullPath);

    if (!await source.exists()) {
      throw Exception("Database file not found at: $dbFullPath");
    }

    final dir = await FilePicker.platform.getDirectoryPath();
    if (dir == null) return null;

    final dest = File('$dir/clinic_backup.db');
    await source.copy(dest.path);

    return dest.path;
  }

  Future<bool> importDB() async {
    final result = await FilePicker.platform.pickFiles();
    if (result == null) return false;
    final projectDir = await getApplicationSupportDirectory();

    var dbFullPath = '${projectDir.path}/dental_clinic.db';
    final destFile = File(dbFullPath);

    await db.close();
    if (await destFile.exists()) {
      await destFile.delete();
    }

    await File(result.files.single.path!).copy(dbFullPath);
    _db = await _openDb();
    return true;
  }

  Future<Map<String, dynamic>?> getPatientById(String id) async {
    final rows = await db.query('patients', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return rows.first;
  }

  // Inventory Outputs (Daily Inventory Tracking)
  Future<List<Map<String, dynamic>>> getInventoryOutputs() async {
    return await db.query('inventory_outputs', orderBy: 'created_at DESC');
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
    await db.insert('inventory_outputs', output);
    return id;
  }

  Future<int> deleteInventoryOutput(String id) async {
    return await db.delete(
      'inventory_outputs',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> clearInventoryOutputs() async {
    await db.delete('inventory_outputs');
  }

  // Simplified getAllPayments if not already present
  Future<List<Map<String, dynamic>>> getAllPaymentsForReport() async {
    return await db.query('payments', orderBy: 'paid_at DESC');
  }
}
