import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/font_provider.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final fontProvider = Provider.of<FontProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Ajustes")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Tamaño de fuente:",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // 🔹 Slider para ajustar escala
            Slider(
              value: fontProvider.scaleFactor,
              min: 0.8,
              max: 1.6,
              divisions: 8, // pasos intermedios
              label: "${(fontProvider.scaleFactor * 100).round()}%",
              onChanged: (val) => fontProvider.setScale(val),
            ),

            const SizedBox(height: 20),

            // 🔹 Vista previa
            Center(
              child: Text(
                "Vista previa del texto",
                style: TextStyle(
                  fontSize: 18 * fontProvider.scaleFactor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            const SizedBox(height: 40),

            // 🔹 Opciones rápidas (por si prefiere botones)
            Wrap(
              spacing: 10,
              children: [
                ElevatedButton(
                  onPressed: () => fontProvider.setScale(0.9),
                  child: const Text("Pequeño"),
                ),
                ElevatedButton(
                  onPressed: () => fontProvider.setScale(1.0),
                  child: const Text("Normal"),
                ),
                ElevatedButton(
                  onPressed: () => fontProvider.setScale(1.3),
                  child: const Text("Grande"),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
