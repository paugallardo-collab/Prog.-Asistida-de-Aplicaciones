# Arquitectura de usuarios — Semana 5

Proyecto Flutter sencillo basado en la actividad y en la clase de POO, SOLID y arquitectura limpia. La versión final utiliza memoria para funcionar sin conexión. No necesita Provider, BLoC ni paquetes de inyección.

## Cómo ejecutar

Desde esta carpeta:

```bash
flutter pub get
flutter run -d chrome
```

Aparecen **Ana** y **elena**. Carlos pertenece a los tres usuarios originales, pero el caso de uso lo descarta porque empieza con consonante.

La implementación inicial se conserva en `ejemplo/main_sin_capas.dart`. Para ejecutarla con la API:

```bash
flutter run -d chrome -t ejemplo/main_sin_capas.dart
```

Para usar la API en la versión final, cambiar únicamente en `lib/main.dart`:

```dart
import 'data/repositories/usuario_api.dart'; // reemplaza el import de memoria
// Dentro de main:
final repository = UsuarioApi(); // reemplaza UsuarioMemoria()
```

No hace falta modificar la pantalla ni el caso de uso.

## Respuestas

### 1. ¿Qué responsabilidades conviven en la pantalla inicial?

Realizar la solicitud HTTP, conocer la URL, interpretar JSON, filtrar nombres que empiezan con vocal y construir la interfaz con sus estados de carga, error y lista vacía.

### 2. ¿Por qué cambiar la URL modifica el archivo de interfaz?

Porque la URL está escrita dentro del estado de la pantalla. Una modificación de infraestructura obliga a editar una clase que también dibuja la interfaz. Esto evidencia acoplamiento con la API y una violación de responsabilidad única: hay varias razones distintas para cambiar la misma clase.

### 3. ¿Puede probarse el filtro sin ejecutar la interfaz Flutter?

En la versión inicial no puede probarse de forma aislada directamente: está dentro de un método privado del estado del widget que primero consulta HTTP. Se podría comprobar mediante una prueba del widget con HTTP simulado, o extraer la regla; copiarla a una prueba no verificaría el código original. Tras la separación, se puede ejecutar el caso de uso con un repositorio falso, sin construir widgets ni consultar la red.

### 4. ¿Qué responsabilidades reducen la cohesión?

El acceso a datos, la interpretación del formato externo y la regla de negocio están agrupados con la presentación. Comparten archivo, pero tienen propósitos diferentes. Separarlos permite que cada clase reúna tareas relacionadas con su propia responsabilidad.

### 5. ¿Qué cambiaría al pasar de HTTP a una base local?

En la pantalla inicial habría que cambiar los imports, la llamada HTTP, la URL y el procesamiento de JSON por consultas y conversión de registros locales. La lista visual podría mantenerse, pero habría que editar su misma clase. Esto indica un acoplamiento alto con la fuente de datos. Con las capas, se agrega un repositorio local y se lo conecta en `main.dart`.

### 6. ¿Dónde quedó la regla de nombres con vocal?

En `domain/usecases/obtener_usuarios_con_vocal.dart`, dentro de `ObtenerUsuariosConVocal`. Es una decisión del negocio que se mantiene aunque cambie la API o el diseño visual. `data` obtiene todos los usuarios y `presentation` muestra el resultado. Se consideran A, E, I, O y U sin distinguir mayúsculas y minúsculas, como pide la actividad.

### 7. ¿Qué dependencias concretas desaparecieron de la presentación?

Antes dependía de `http`, `jsonDecode`, la URL de JSONPlaceholder y las claves JSON `name` y `email`. Después recibe `ObtenerUsuariosConVocal` y trabaja con objetos `Usuario`. El caso de uso depende del contrato `UsuarioRepository`; `UsuarioApi` y `UsuarioMemoria` implementan ese contrato. Flutter sigue siendo una dependencia normal de la presentación.

### 8. ¿Qué propuesta de la IA se modificó y por qué?

La versión inicial generada utilizaba `List<dynamic>` y accesos como `usuario['name']` directamente en la interfaz. Se conservó así para la auditoría, pero no se mantuvo en la versión final: se reemplazó por `List<Usuario>` y propiedades como `usuario.nombre`. Esto evita que la pantalla dependa del formato JSON y permite detectar errores de tipos durante el análisis. Esta es la decisión aplicada en esta entrega; el estudiante debe revisarla y confirmar su propio criterio antes de presentar el trabajo.

## Auditoría de la versión inicial

Referencias a `ejemplo/main_sin_capas.dart`, conservado sin refactorizar:

| Líneas | Evidencia | Problema |
| --- | --- | --- |
| 1 y 4 | Imports de JSON y HTTP | La presentación depende directamente de detalles de acceso a datos. |
| 28–30 | Solicitud HTTP y URL concreta | Inversión de dependencias: el widget conoce el mecanismo y proveedor de datos, sin un contrato. |
| 34 | `jsonDecode` | Responsabilidad única: interpreta datos externos además de dibujar. |
| 35–38 | Filtro de nombres con vocal | Responsabilidad única: la regla del negocio vive en el estado del widget. |
| 42–69 | Construcción de interfaz y estados | Responsabilidad de presentación, mezclada con las anteriores. |
| 63–64 | Claves JSON en `Text` | La interfaz también está acoplada al formato de la respuesta. |

Estas observaciones se contrastaron con el archivo: no son objeciones de estilo. El problema es qué responsabilidades y dependencias tiene la clase. Usar `StatefulWidget` o `FutureBuilder` no viola SOLID por sí mismo.

## Refactorización realizada

1. **Domain:** entidad `Usuario`, contrato `UsuarioRepository` y caso de uso. Se revisó que no importara Flutter, HTTP ni JSON.
2. **Data:** `UsuarioApi` realiza HTTP, interpreta JSON y construye entidades. No filtra nombres.
3. **Presentation:** la pantalla recibe el caso de uso y maneja carga, error, lista vacía y recarga. No conoce la fuente de datos.
4. **Composición:** primero se conectó `UsuarioApi` en `main.dart`.
5. **Sustitución:** se creó `UsuarioMemoria` con tres usuarios y se cambió solamente el import y la construcción del repositorio en `main.dart`. La pantalla y el caso de uso permanecieron intactos.

```text
lib/
├── main.dart
├── domain/
│   ├── entities/usuario.dart
│   ├── repositories/usuario_repository.dart
│   └── usecases/obtener_usuarios_con_vocal.dart
├── data/repositories/
│   ├── usuario_api.dart
│   └── usuario_memoria.dart
└── presentation/pages/pantalla_usuarios.dart
```

`presentation → domain ← data`. `main.dart` construye y conecta las dependencias.

## Instrucción que habría evitado el refactor

> Crea una app Flutter sencilla que liste usuarios de JSONPlaceholder cuyo nombre empiece con A, E, I, O o U, sin distinguir mayúsculas. Separa domain, data y presentation. Coloca la entidad, el contrato del repositorio y el filtro en domain; HTTP y JSON en data; la interfaz y sus estados en presentation. Inyecta el caso de uso por constructor y conecta las implementaciones en main.dart. Incluye un repositorio en memoria intercambiable sin modificar la pantalla. No agregues librerías de estado ni capas innecesarias.

Este último punto también aparece en la diapositiva 23 de la presentación.

## Verificación

Comandos de comprobación:

```bash
flutter analyze
flutter test
flutter build web
```

Las pruebas comprueban las cinco vocales, mayúsculas y minúsculas, consonantes y nombres vacíos; además verifican la pantalla con memoria y sus estados de carga, error y lista vacía. La prueba de error usa un fallo simulado.

Resultado: **7 pruebas aprobadas**, incluyendo conversión de JSON, respuesta HTTP fallida y pantalla inicial. Las solicitudes HTTP se simularon; no se comprobó manualmente la interfaz en Chrome ni la disponibilidad de la API real. El análisis se ejecutó directamente con `dart analyze lib ejemplo test`.

La compilación `flutter build web` también terminó correctamente.

## Registro en Git

Rama de trabajo: `refactor/capas`.

Mensaje de commit solicitado: `refactor: separa la pantalla de usuarios en tres capas`.
