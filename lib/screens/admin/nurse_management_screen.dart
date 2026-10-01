import 'package:flutter/material.dart';
import '../../services/app_state.dart';
import '../../models/user_model.dart';
import '../../theme/app_theme.dart';
import 'create_nurse_dialog.dart';

class NurseManagementScreen extends StatefulWidget {
  final AppState appState;

  const NurseManagementScreen({super.key, required this.appState});

  @override
  State<NurseManagementScreen> createState() => _NurseManagementScreenState();
}

class _NurseManagementScreenState extends State<NurseManagementScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<UserModel> _getFilteredNurses() {
    final list = widget.appState.nurses.where((u) => u.role == UserRole.nurse).toList();
    if (_searchQuery.isEmpty) return list;
    final q = _searchQuery.toLowerCase().trim();
    return list.where((n) {
      return n.name.toLowerCase().contains(q) ||
          n.employeeId.toLowerCase().contains(q) ||
          n.department.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final nurses = _getFilteredNurses();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Nurse Staff Directory'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1_rounded, color: AppColors.primary),
            tooltip: 'Add New Nurse',
            onPressed: () async {
              await CreateNurseDialog.show(context, widget.appState);
              setState(() {});
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await CreateNurseDialog.show(context, widget.appState);
          setState(() {});
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.person_add_rounded, color: Colors.white),
        label: const Text('Create Nurse Account', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: Column(
        children: [
          // Info Header
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: 'Search nurses by name, ID, or ward...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.primary),
                    filled: true,
                    fillColor: const Color(0xFFF1F5F9),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.borderLight),

          // Nurse cards
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              itemCount: nurses.length,
              itemBuilder: (context, index) {
                final nurse = nurses[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: AppColors.primarySurface,
                              child: Text(
                                nurse.name.substring(0, 1),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primaryDark,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        nurse.name,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textMainLight,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: nurse.isActive ? const Color(0xFFD1FAE5) : const Color(0xFFFEE2E2),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          nurse.isActive ? 'ACTIVE' : 'INACTIVE',
                                          style: TextStyle(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w800,
                                            color: nurse.isActive ? const Color(0xFF065F46) : const Color(0xFF991B1B),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${nurse.roleTitle} • ID: ${nurse.employeeId}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primaryDark,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Icon(Icons.local_hospital_outlined, size: 14, color: AppColors.textMutedLight),
                                      const SizedBox(width: 4),
                                      Text(
                                        nurse.department,
                                        style: const TextStyle(fontSize: 12, color: AppColors.textMutedLight),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Row(
                                    children: [
                                      const Icon(Icons.schedule_rounded, size: 14, color: AppColors.textMutedLight),
                                      const SizedBox(width: 4),
                                      Text(
                                        nurse.shift,
                                        style: const TextStyle(fontSize: 11.5, color: AppColors.textMutedLight),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(height: 1, color: AppColors.borderLight),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'PIN: ${nurse.pin}  •  ${nurse.email}',
                              style: const TextStyle(fontSize: 11, color: AppColors.textLight),
                            ),
                            TextButton(
                              onPressed: () {
                                widget.appState.toggleNurseActive(nurse.id);
                                setState(() {});
                              },
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                nurse.isActive ? 'Deactivate Access' : 'Activate Access',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: nurse.isActive ? Colors.red : AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
