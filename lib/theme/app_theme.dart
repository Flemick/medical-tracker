import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/equipment.dart';
import '../models/complaint.dart';

class AppColors {
  // Brand Colors
  static const Color primary = Color(0xFF0D9488); // Teal 600
  static const Color primaryDark = Color(0xFF0F766E); // Teal 700
  static const Color primaryLight = Color(0xFF2DD4BF); // Teal 400
  static const Color primarySurface = Color(0xFFCCFBF1); // Teal 100
  
  static const Color secondary = Color(0xFF0284C7); // Sky 600
  static const Color accent = Color(0xFF6366F1); // Indigo 500

  // Background & Surfaces
  static const Color backgroundLight = Color(0xFFF8FAFC); // Slate 50
  static const Color surfaceLight = Colors.white;
  static const Color surfaceCardLight = Color(0xFFFFFFFF);
  static const Color borderLight = Color(0xFFE2E8F0); // Slate 200
  
  static const Color backgroundDark = Color(0xFF0B1120); // Slate 950
  static const Color surfaceDark = Color(0xFF1E293B); // Slate 800
  static const Color surfaceCardDark = Color(0xFF131D31);
  static const Color borderDark = Color(0xFF334155); // Slate 700

  // Text Colors
  static const Color textMainLight = Color(0xFF0F172A); // Slate 900
  static const Color textMutedLight = Color(0xFF64748B); // Slate 500
  static const Color textLight = Color(0xFF94A3B8); // Slate 400

  static const Color textMainDark = Color(0xFFF1F5F9);
  static const Color textMutedDark = Color(0xFF94A3B8);

  // Status Colors
  static const Color statusAvailable = Color(0xFF10B981); // Emerald 500
  static const Color statusAvailableBg = Color(0xFFD1FAE5); // Emerald 100
  static const Color statusInUse = Color(0xFF0284C7); // Sky 600
  static const Color statusInUseBg = Color(0xFFE0F2FE); // Sky 100
  static const Color statusReserved = Color(0xFF8B5CF6); // Purple 500
  static const Color statusReservedBg = Color(0xFFEDE9FE); // Purple 100
  static const Color statusMaintenance = Color(0xFFF59E0B); // Amber 500
  static const Color statusMaintenanceBg = Color(0xFFFEF3C7); // Amber 100
  static const Color statusMissing = Color(0xFFEF4444); // Red 500
  static const Color statusMissingBg = Color(0xFFFEE2E2); // Red 100
  static const Color statusOutOfService = Color(0xFF64748B); // Slate 500
  static const Color statusOutOfServiceBg = Color(0xFFF1F5F9); // Slate 100

  // Severity Colors
  static const Color severityLow = Color(0xFF10B981);
  static const Color severityMed = Color(0xFFF59E0B);
  static const Color severityHigh = Color(0xFFF97316);
  static const Color severityEmergency = Color(0xFFEF4444);
}

class AppTheme {
  static ThemeData get lightTheme {
    final baseTextTheme = GoogleFonts.plusJakartaSansTextTheme(ThemeData.light().textTheme);
    
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.backgroundLight,
      colorScheme: ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.surfaceLight,
        error: AppColors.statusMissing,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.textMainLight,
      ),
      textTheme: baseTextTheme.copyWith(
        displayLarge: GoogleFonts.plusJakartaSans(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: AppColors.textMainLight,
          letterSpacing: -0.5,
        ),
        headlineMedium: GoogleFonts.plusJakartaSans(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.textMainLight,
          letterSpacing: -0.3,
        ),
        titleLarge: GoogleFonts.plusJakartaSans(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: AppColors.textMainLight,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: AppColors.textMainLight,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: AppColors.textMutedLight,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: AppColors.textMainLight),
        titleTextStyle: TextStyle(
          color: AppColors.textMainLight,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceCardLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.borderLight, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.statusMissing),
        ),
      ),
    );
  }

  static Color getAvailabilityColor(EquipmentAvailability availability) {
    switch (availability) {
      case EquipmentAvailability.available:
        return AppColors.statusAvailable;
      case EquipmentAvailability.inUse:
        return AppColors.statusInUse;
      case EquipmentAvailability.reserved:
        return AppColors.statusReserved;
      case EquipmentAvailability.underMaintenance:
        return AppColors.statusMaintenance;
      case EquipmentAvailability.missing:
        return AppColors.statusMissing;
      case EquipmentAvailability.outOfService:
        return AppColors.statusOutOfService;
    }
  }

  static Color getAvailabilityBg(EquipmentAvailability availability) {
    switch (availability) {
      case EquipmentAvailability.available:
        return AppColors.statusAvailableBg;
      case EquipmentAvailability.inUse:
        return AppColors.statusInUseBg;
      case EquipmentAvailability.reserved:
        return AppColors.statusReservedBg;
      case EquipmentAvailability.underMaintenance:
        return AppColors.statusMaintenanceBg;
      case EquipmentAvailability.missing:
        return AppColors.statusMissingBg;
      case EquipmentAvailability.outOfService:
        return AppColors.statusOutOfServiceBg;
    }
  }

  static String getAvailabilityLabel(EquipmentAvailability availability) {
    switch (availability) {
      case EquipmentAvailability.available:
        return 'Available';
      case EquipmentAvailability.inUse:
        return 'In Use';
      case EquipmentAvailability.reserved:
        return 'Reserved';
      case EquipmentAvailability.underMaintenance:
        return 'Maintenance';
      case EquipmentAvailability.missing:
        return 'Missing';
      case EquipmentAvailability.outOfService:
        return 'Out of Service';
    }
  }

  static Color getComplaintStatusColor(ComplaintStatus status) {
    switch (status) {
      case ComplaintStatus.submitted:
        return const Color(0xFF6366F1); // Indigo
      case ComplaintStatus.underReview:
        return const Color(0xFF0284C7); // Sky
      case ComplaintStatus.assignedToTech:
        return const Color(0xFF8B5CF6); // Purple
      case ComplaintStatus.inProgress:
        return const Color(0xFFF59E0B); // Amber
      case ComplaintStatus.resolved:
        return const Color(0xFF10B981); // Emerald
      case ComplaintStatus.escalated:
        return const Color(0xFFEF4444); // Red
      case ComplaintStatus.rejected:
        return const Color(0xFF64748B); // Slate
    }
  }

  static String getComplaintStatusLabel(ComplaintStatus status) {
    switch (status) {
      case ComplaintStatus.submitted:
        return 'Submitted';
      case ComplaintStatus.underReview:
        return 'Under Review';
      case ComplaintStatus.assignedToTech:
        return 'Tech Assigned';
      case ComplaintStatus.inProgress:
        return 'In Progress';
      case ComplaintStatus.resolved:
        return 'Resolved';
      case ComplaintStatus.escalated:
        return 'Escalated';
      case ComplaintStatus.rejected:
        return 'Closed/Rejected';
    }
  }

  static Color getSeverityColor(ComplaintSeverity severity) {
    switch (severity) {
      case ComplaintSeverity.low:
        return AppColors.severityLow;
      case ComplaintSeverity.medium:
        return AppColors.severityMed;
      case ComplaintSeverity.high:
        return AppColors.severityHigh;
      case ComplaintSeverity.emergency:
        return AppColors.severityEmergency;
    }
  }
}
