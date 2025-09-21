# WillCooks 👩‍🍳

Aplicación Flutter para organizar pedidos de comedores con backend en Firebase (Auth + Firestore).

## 🚀 Funcionalidades
- Login con Google (Firebase Auth).
- Gestión de usuarios con campo `isPremium` en Firestore.
- Usuarios **Premium**:
    - Crear y guardar recetas con ingredientes.
    - Programar pedidos.
    - Gestionar inventario.
- Usuarios **No Premium**:
    - Ven una pantalla informativa sobre las ventajas de WillCooks Premium.

---

## 🛠️ Requisitos
- Flutter 3.x o superior
- Dart 3.x
- Firebase configurado en el proyecto

---

## 📦 Instalación

1. Clona este repositorio:

   ```bash
   git clone https://github.com/TU_USUARIO/willcooks.git
   cd willcooks

2. Instala las dependencias:

   ```bash
    flutter pub get
   
3. Añade los archivos de configuración de Firebase (⚠️ no incluidos en el repo):

Android: android/app/google-services.json

iOS: ios/Runner/GoogleService-Info.plist

👉 Estos archivos se descargan desde la Consola de Firebase

4. Ejecuta la app en un emulador o dispositivo:

   ```bash
   flutter run

---

## 🔒 Notas de seguridad

Los archivos google-services.json, GoogleService-Info.plist y android/key.properties están excluidos en .gitignore para no filtrar claves sensibles.

Si clonas este repo en otro equipo, recuerda añadir tus propios archivos de Firebase.

---

## 👨‍💻 AUTOR

    Guillermo Pichaco Panal