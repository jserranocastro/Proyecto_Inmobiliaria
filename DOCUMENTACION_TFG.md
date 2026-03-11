# DOCUMENTACIÓN PROYECTO INTEGRADO: INMOBILIARIA APP

**Centro:** IES Francisco de los Ríos (Fernán Núñez)
**Proyecto:** Proyecto Inmobiliaria (Flutter + Firebase)

---

## 6.2.2. TABLA DE CONTENIDOS

1. Descripción del problema.
2. Objetivos del proyecto.
3. Recursos necesarios.
4. Planificación temporal.
5. Desarrollo del proyecto.
   5.1. Requisitos de la aplicación.
   5.2. Diseño de la aplicación.
      5.2.1. Diseño de la arquitectura.
      5.2.2. Diseño de datos.
   5.3. Codificación.
   5.4. Pruebas.
   5.5. Problemas encontrados.
6. Manual de instalación.
7. Manual de usuario.
8. Valoraciones y conclusión.
   8.1. Evaluación del grado de cumplimiento de los objetivos y finalidad.
   8.2. Evaluación de la planificación temporal y de la toma de decisiones.
   8.3. Posibles mejoras a la solución.
   8.4. Conclusión final.
9. Bibliografía.
10. Anexos.
   10.1. Código fuente de la aplicación.
   10.2. Otros.

---

## 1. Descripción del problema
En el sector inmobiliario actual, existe una saturación de portales que a menudo resultan complejos o poco accesibles para usuarios que buscan una gestión rápida desde dispositivos móviles. El problema detectado es la falta de una herramienta sencilla, multiplataforma y con comunicación directa e instantánea entre particulares o profesionales para la compra y alquiler de inmuebles en zonas específicas.

## 2. Objetivos del proyecto
- Desarrollar una aplicación móvil multiplataforma (Android/iOS).
- Implementar un sistema de autenticación de usuarios seguro.
- Permitir la publicación de anuncios con imágenes y detalles técnicos (habitaciones, baños, precio, etc.).
- Facilitar la búsqueda de inmuebles mediante filtros geográficos y de características.
- Integrar un sistema de chat en tiempo real para que los interesados contacten con los anunciantes.
- Proporcionar un sistema de "Favoritos" para guardar inmuebles de interés.

## 3. Recursos necesarios
### 3.1. Recursos de desarrollo
- **Hardware:** Ordenador con procesador i5+, 16GB RAM, SSD. Dispositivo móvil Android para pruebas físicas.
- **Software:** 
  - Sistema Operativo: Windows/macOS.
  - IDE: Visual Studio Code / Android Studio.
  - SDK: Flutter SDK y Dart.
  - Backend: Firebase (Firestore, Auth, Storage).
  - Control de versiones: Git y GitHub.
  - Diseño: Figma (para prototipado).

### 3.2. Recursos de producción
- Terminal móvil con Android 6.0 o superior / iOS 12 o superior.
- Conexión a internet constante (para sincronización con Firebase).
- Cuenta de Google para acceso a servicios en la nube.

## 4. Planificación temporal
Se estima un desarrollo de 15 semanas:
- **Semanas 1-2:** Análisis de requisitos y diseño de UI/UX.
- **Semanas 3-4:** Configuración del entorno y Firebase.
- **Semanas 5-8:** Desarrollo del núcleo (Publicación y Búsqueda).
- **Semanas 9-11:** Implementación del sistema de Chat y Favoritos.
- **Semanas 12-13:** Fase de pruebas (QA) y corrección de errores.
- **Semanas 14-15:** Elaboración de documentación y manuales.

## 5. Desarrollo del proyecto
### 5.1. Requisitos de la aplicación
- **Funcionales:** Registro/Login, Subida de fotos, Búsqueda por municipio (CSV), Chat bidireccional, Gestión de perfil.
- **No funcionales:** Interfaz intuitiva (Material Design), alta disponibilidad de datos, tiempos de respuesta menores a 2 segundos en carga de listas.

### 5.2. Diseño de la aplicación
#### 5.2.1. Diseño de la arquitectura
Se utiliza una arquitectura basada en capas (Clean Architecture simplificada):
- **Capa de Presentación (Screens/Widgets):** Vistas construidas con Flutter.
- **Capa de Negocio (Models):** Definición de objetos (Property, ChatMessage).
- **Capa de Datos (Services):** `FirebaseService` gestiona la comunicación con Firestore.

*Nota: Se debe adjuntar aquí un **Diagrama de Casos de Uso** mostrando al Usuario interactuando con "Publicar Inmueble", "Buscar", "Enviar Mensaje" y "Gestionar Favoritos".*

#### 5.2.2. Diseño de datos
Base de datos NoSQL (Firestore). Estructura:
- **Colección `users`:** Documentos por UID con lista de `favorites`.
- **Colección `properties`:** Datos del inmueble (precio, ciudad, provincia, userId del dueño).
- **Colección `chat_rooms`:** ID combinado de usuarios, último mensaje y metadatos.
  - **Subcolección `messages`:** Historial de mensajes con timestamp.

*Nota: Se debe adjuntar aquí un **Diagrama Entidad-Relación** que refleje estas conexiones.*

### 5.3. Codificación
El proyecto destaca por el uso de:
- **Streams:** Para actualizaciones en tiempo real de chats y listados.
- **Firebase Auth:** Gestión de sesiones.
- **CSV Parser:** Carga de municipios españoles para el buscador.
- **Image Picker:** Acceso a la cámara y galería del dispositivo.

### 5.4. Pruebas
- **Unitarias:** Verificación de modelos de datos.
- **Integración:** Flujo completo desde que se crea un anuncio hasta que aparece en la búsqueda.
- **Usabilidad:** Pruebas con usuarios reales para validar la simplicidad del chat.

### 5.5. Problemas encontrados
- **Gestión de imágenes:** Optimización del peso de las fotos antes de subirlas.
- **Sincronización de Chat:** Manejo de estados de "leído/no leído" en tiempo real.
- **Filtros cruzados:** Complejidad en las consultas de Firestore para múltiples parámetros simultáneos (se solucionó con filtrado en cliente tras la consulta inicial).

## 6. Manual de instalación
1. Instalar Flutter SDK desde la web oficial.
2. Clonar el repositorio del proyecto.
3. Ejecutar `flutter pub get` en la terminal para descargar dependencias.
4. Crear un proyecto en Firebase Console.
5. Añadir las apps de Android/iOS en Firebase y descargar los archivos `google-services.json` y `GoogleService-Info.plist`.
6. Colocar los archivos en las carpetas correspondientes (`android/app` y `ios/Runner`).
7. Ejecutar `flutter run`.

## 7. Manual de usuario
1. **Registro:** Crear cuenta con email y contraseña.
2. **Inicio:** Explorar los últimos inmuebles publicados.
3. **Búsqueda:** Usar la lupa para filtrar por ciudad, precio o tipo.
4. **Publicar:** Pulsar el botón "+" para subir tu propio anuncio.
5. **Chat:** Desde el detalle de un inmueble, pulsar "Contactar" para abrir el chat con el vendedor.
6. **Favoritos:** Pulsar el icono del corazón para guardar anuncios.

## 8. Valoraciones y conclusión
### 8.1. Evaluación de objetivos
Se han cumplido todos los objetivos principales, logrando una app funcional que permite la gestión completa del ciclo de vida de un anuncio inmobiliario.
### 8.2. Evaluación de planificación
Se ha seguido el calendario previsto, aunque la integración del chat requirió 1 semana adicional debido a la lógica de notificaciones.
### 8.3. Posibles mejoras
- Implementación de Mapas (Google Maps API).
- Notificaciones Push externas.
- Verificación de perfiles mediante DNI.
### 8.4. Conclusión final
El proyecto demuestra que Flutter y Firebase forman un ecosistema extremadamente eficiente para prototipar y lanzar aplicaciones comerciales en tiempos reducidos.

## 9. Bibliografía
- Documentación oficial de Flutter: [https://docs.flutter.dev/](https://docs.flutter.dev/)
- Documentación de Firebase: [https://firebase.google.com/docs](https://firebase.google.com/docs)
- StackOverflow (Consultas sobre gestión de Streams y NoSQL).

## 10. Anexos
10.1. Código fuente: Disponible en el repositorio Git adjunto.
10.2. Otros: Archivo `municipios.csv` con el listado de localidades utilizado.
