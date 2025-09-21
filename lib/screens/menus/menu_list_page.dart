import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/menu.dart';
import '../../services/menu_service.dart';
import 'weekly_menu_page.dart';

class MenuListPage extends StatelessWidget {
  final MenuService _menuService = MenuService();
  final String userId = FirebaseAuth.instance.currentUser!.uid;

  MenuListPage({super.key});

  String _formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/"
        "${date.month.toString().padLeft(2, '0')}/"
        "${date.year}";
  }

  Future<DateTime?> _pickDate(BuildContext context, DateTime initial) async {
    return await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      locale: const Locale('es', 'ES'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Mis menús")),
      body: StreamBuilder<QuerySnapshot>(
        stream: _menuService.menusRef
            .where("userId", isEqualTo: userId)
            .orderBy("weekStart", descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No hay menús todavía"));
          }

          final menus = snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            try {
              return Menu.fromMap(data);
            } catch (e) {
              debugPrint("⚠️ Error parseando menú: $e");
              return null;
            }
          }).whereType<Menu>().toList();

          return ListView.builder(
            itemCount: menus.length,
            itemBuilder: (context, index) {
              final menu = menus[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(menu.name),
                  subtitle: Text(
                    "Del ${_formatDate(menu.feInicio)} al ${_formatDate(menu.feFin)}",
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => WeeklyMenuPage(menu: menu),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final nameCtrl = TextEditingController();
          DateTime? feInicio;
          DateTime? feFin;

          await showDialog(
            context: context,
            builder: (context) => StatefulBuilder(
              builder: (context, setState) {
                return AlertDialog(
                  title: const Text("Nuevo menú"),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(
                          labelText: "Nombre del menú",
                          hintText: "Ej: 22-26 septiembre",
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () async {
                                final picked = await _pickDate(context, DateTime.now());
                                if (picked != null) {
                                  setState(() => feInicio = picked);
                                }
                              },
                              child: Text(
                                feInicio == null
                                    ? "Fecha inicio"
                                    : _formatDate(feInicio!),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () async {
                                final picked = await _pickDate(
                                    context, feInicio ?? DateTime.now());
                                if (picked != null) {
                                  setState(() => feFin = picked);
                                }
                              },
                              child: Text(
                                feFin == null
                                    ? "Fecha fin"
                                    : _formatDate(feFin!),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Cancelar"),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        if (feInicio == null || feFin == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Debes elegir ambas fechas")),
                          );
                          return;
                        }

                        if (feInicio!.isAfter(feFin!)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("La fecha de inicio no puede ser posterior a la fecha fin")),
                          );
                          return;
                        }

                        // ✅ Calcular lunes de esa semana para weekStart
                        final weekStart = feInicio!.subtract(Duration(days: feInicio!.weekday - 1));

                        final name = nameCtrl.text.trim().isEmpty
                            ? "Menú ${_formatDate(feInicio!)}"
                            : nameCtrl.text.trim();

                        await _menuService.createEmptyMenu(
                          userId: userId,
                          weekStart: weekStart,
                          name: name,
                          feInicio: feInicio!,
                          feFin: feFin!,
                        );

                        if (context.mounted) Navigator.pop(context);
                      },
                      child: const Text("Crear"),
                    ),
                  ],
                );
              },
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
