# Arquitectura de usuarios

Actividad de Flutter con una versión inicial sin capas y una versión final con domain, data y presentation.

La pantalla actual consulta `https://jsonplaceholder.typicode.com/users` y permite buscar por nombre con un campo de texto. La búsqueda ignora mayúsculas y minúsculas y encuentra coincidencias en cualquier parte del nombre. Un campo vacío muestra todos los usuarios.

Para ejecutar en el emulador Android:

```bash
flutter run -d emulator-5554
```

Las respuestas, la auditoría y las instrucciones están en [Respuestas_Semana5.md](Respuestas_Semana5.md).

```bash
flutter pub get
flutter run -d chrome
```
