# نظام الجرد اليومي والشهري - Daily & Monthly Inventory System

## نظرة عامة / Overview

تمت إضافة نظام شامل للجرد اليومي والشهري يتتبع:

### المميزات / Features:

1. **لوحة معلومات الجرد** - Inventory Dashboard
   - عرض إجمالي الفواتير
   - عرض المبالغ المدفوعة  
   - عرض المبالغ المتبقية (غير المدفوعة)

2. **تتبع الدفعات اليومية** - Daily Payments Tracking
   - عرض جميع الدفعات المستلمة يومياً
   - تصفية حسب نطاق التاريخ
   - عرض طريقة الدفع (نقدي، شيك، إلخ)
   - عرض اليوم والتاريخ لكل دفعة

3. **تسجيل المخرجات** - Inventory Outputs
   - تسجيل المواد المستخدمة/المسلمة يومياً
   - حفظ معلومات المادة والكمية والوحدة
   - تتبع تاريخ المخرجات

4. **الجرد النهائي** - Final Inventory Count
   - زر لتنفيذ الجرد النهائي
   - مسح جميع المخرجات بعد الجرد
   - تأكيد من المستخدم قبل الحذف

5. **عرض اليوم على الصفحة الرئيسية** - Daily Summary Widget
   - عرض إجمالي الدفعات لليوم
   - عرض عدد الدفعات المستلمة
   - واجهة مرئية مميزة على الصفحة الرئيسية

## الملفات المضافة / Added Files:

### 1. Controllers
- **`lib/features/inventory_manage/controller/daily_inventory_controller.dart`**
  - التحكم في منطق الجرد اليومي
  - حساب الإحصائيات والملخصات
  - إدارة حالة البيانات

### 2. Views
- **`lib/features/inventory_manage/views/daily_inventory_page.dart`**
  - الصفحة الرئيسية للجرد اليومي
  - عرض الملخصات والإحصائيات
  - واجهة الدفعات والمخرجات

- **`lib/features/inventory_manage/views/widgets/daily_payment_summary_widget.dart`**
  - عنصر واجهة يعرض ملخص دفعات اليوم
  - يُعرض على الصفحة الرئيسية (Dashboard)

### 3. Database Updates
- **`lib/services/database/database_service_io.dart`**
  - إضافة جدول `inventory_outputs`
  - إضافة الدوال اللازمة لإدارة المخرجات

- **`lib/services/database/database_service_web.dart`**
  - دعم نفس الميزات على الويب
  - تخزين في الذاكرة للنماذج الاختبارية

## كيفية الاستخدام / How to Use:

### 1. الوصول للجرد اليومي
- انقر على **"الجرد اليومي"** في قائمة التنقل العلوية

### 2. عرض ملخص اليوم
- الصفحة الرئيسية تعرض عنصر واجهة يُظهر إجمالي الدفعات لليوم

### 3. تسجيل الدفعات والمخرجات
- استخدم نطاق التاريخ لتصفية البيانات
- عرض جميع الدفعات في الفترة المحددة
- عرض جميع المخرجات المسجلة

### 4. الجرد النهائي
- انقر على زر **"الجرد النهائي"** عند الانتهاء
- أكد العملية
- سيتم مسح جميع المخرجات

## البيانات المحفوظة / Stored Data:

### جدول `inventory_outputs`
```sql
CREATE TABLE inventory_outputs (
  id TEXT PRIMARY KEY,
  item_id TEXT,
  item_name TEXT,
  quantity REAL,
  unit TEXT,
  date TEXT,
  created_at TEXT,
  FOREIGN KEY(item_id) REFERENCES inventory(id)
);
```

### جدول `payments` (موجود مسبقاً)
```sql
CREATE TABLE payments (
  id TEXT PRIMARY KEY,
  invoice_id TEXT,
  amount REAL,
  method TEXT,
  note TEXT,
  paid_at TEXT,
  FOREIGN KEY(invoice_id) REFERENCES invoices(id)
);
```

## التكامل مع النظام / System Integration:

1. **صفحة الرئيسية**: تعرض عنصر الدفعات اليومية
2. **قائمة التنقل**: رابط مباشر للجرد اليومي
3. **قاعدة البيانات**: تخزين كامل للتاريخ والتقارير
4. **التقارير**: يمكن توليد تقارير يومية وشهرية

## ملاحظات مهمة / Important Notes:

- جميع المبالغ مخزنة بدقة عالية (double)
- التواريخ تُخزن بصيغة ISO 8601
- جميع العمليات تدعم اللغة العربية
- النظام يحفظ نسخة احتياطية من البيانات

---

**تاريخ الإنشاء**: 15 يناير 2026
**الإصدار**: 1.0
