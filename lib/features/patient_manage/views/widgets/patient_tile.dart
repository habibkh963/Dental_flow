// import 'package:dental_managment_system/features/patient_manage/views/patients_page.dart';
// import 'package:flutter/material.dart';

// import '../../controller/patients_controller.dart';
// import 'patient_dialog.dart';

// class PatientTile extends StatelessWidget {
//   final Map<String, dynamic> patient;
//   final PatientsController controller;

//   const PatientTile({required this.patient, required this.controller});

//   @override
//   Widget build(BuildContext context) {
//     return ListTile(
//       title: Text(
//         '${patient['last_name']} ${patient['first_name']}',
//         style: const TextStyle(fontWeight: FontWeight.w600),
//       ),
//       subtitle: Text(patient['phone'] ?? ''),
//       trailing: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           IconButton(
//             icon: const Icon(Icons.visibility_outlined),
//             onPressed: () => openPatientProfile(context, patient),
//           ),
//           IconButton(
//             icon: const Icon(Icons.edit_outlined),
//             onPressed: () =>
//                 openPatientDialog(context, controller, existing: patient),
//           ),
//           IconButton(
//             icon: const Icon(Icons.delete_outline),
//             onPressed: () => controller.remove(patient['id']),
//           ),
//         ],
//       ),
//     );
//   }
// }
