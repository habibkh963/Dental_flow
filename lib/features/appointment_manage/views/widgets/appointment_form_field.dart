import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

InputDecoration appointmentFieldDecoration({String? hint}) {
  return InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
    ),
    hintStyle: GoogleFonts.poppins(fontSize: 13),
  );
}
