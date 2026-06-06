# DurangoGuía IA 🦂 - Agente de Turismo de Durango

Este proyecto es una aplicación web interactiva que utiliza la librería **AutoGen** (ahora **AG2**) y los modelos de **Google Gemini** para crear un agente de inteligencia artificial especializado en turismo, gastronomía, leyendas y negocios locales de la hermosa ciudad de **Durango, Durango, México**.

La interfaz de usuario ha sido desarrollada con un diseño web moderno y premium, utilizando técnicas de *glassmorphism* (efecto cristal), sombras neon, paletas de colores inspiradas en los atardeceres de Durango (tonos terracota y dorado cálido) y micro-animaciones fluidas.

---

## 🚀 Características Principales

1. **Agente Especializado en Durango**: Diseñado a través de `ConversableAgent` y `AssistantAgent` de AutoGen con instrucciones de sistema detalladas sobre la cultura local, leyendas coloniales (como *La Monja de la Catedral*) y orgullo duranguense.
2. **Herramienta Integrada en AutoGen (`get_durango_recommendations`)**: Un tool registrado en el flujo de AutoGen que provee datos curados sobre atracciones turísticas (Teleférico, Viejo Oeste, Túnel de Minería), gastronomía típica (Caldillo Duranguense, Chile Pasado, Mezcal Cenizo), artesanías (alacranes encapsulados en resina, Casa del Artesano) y ecoturismo en la sierra (Mexiquillo, Tres Molinos).
3. **Flujo de Ejecución Multi-Agente**: La aplicación crea un flujo donde un `UserProxyAgent` recibe la entrada del usuario, se la pasa al `AssistantAgent`, quien decide si requiere consultar la herramienta. Si el asistente realiza la llamada, el proxy la ejecuta automáticamente en segundos y devuelve la información al asistente para que la estructure en su respuesta final.
4. **Resistencia de Historial (Multi-Turn Chat)**: El backend reconstruye de forma dinámica y sin estado el historial de los mensajes anteriores en cada solicitud para que el agente tenga memoria completa del contexto.
5. **Interfaz de Usuario Web Premium**:
   - Diseño responsivo moderno para móviles y ordenadores.
   - Guardado automático y seguro de la Clave API de Gemini en `localStorage` del navegador.
   - Renderizado dinámico de código Markdown (tablas, negritas, listas ordenadas) usando la biblioteca `marked.js`.
   - Selector rápido de sugerencias y temas especiales.
   - Indicador de estado animado (pulsing online) y animaciones de escritura ("typing indicators").

---

## 🛠️ Requisitos e Instalación

### 1. Clonar o acceder al directorio del proyecto
Asegúrate de que estás en la carpeta del proyecto en tu terminal:
```bash
/home/sebastian/Proyectos/HackDays
```

### 2. Configurar el Entorno Virtual de Python
El entorno ya está creado (`.venv`). Para activarlo, ejecuta:
* En Linux/macOS:
  ```bash
  source .venv/bin/activate
  ```
* En Windows:
  ```cmd
  .venv\Scripts\activate
  ```

### 3. Instalar Dependencias
Si necesitas reinstalar o verificar las dependencias, corre:
```bash
pip install -r requirements.txt
```

---

## 🚦 Cómo Iniciar la Aplicación

1. **Ejecutar el Servidor FastAPI:**
   Con el entorno virtual activado, inicia el servidor ejecutando:
   ```bash
   python app.py
   ```
   *El servidor web se levantará en `http://localhost:8000`.*

2. **Abrir la Interfaz de Usuario:**
   Abre tu navegador de preferencia y dirígete a:
   [http://localhost:8000](http://localhost:8000)

3. **Configurar tu API Key de Gemini:**
   - Ve a la barra lateral izquierda en la aplicación web.
   - Pega tu Clave API obtenida en [Google AI Studio](https://aistudio.google.com/).
   - Haz clic en el botón de guardar (icono de disco).
   - ¡Listo! Ahora puedes comenzar a chatear con el agente.

---

## 📂 Estructura del Código

- **`app.py`** [[Enlace a app.py](file:///home/sebastian/Proyectos/HackDays/app.py)]: Servidor FastAPI que implementa la lógica de AutoGen, el registro de la herramienta de recomendación y sirve los archivos del cliente.
- **`static/`**: Carpeta contenedora de los archivos del frontend.
  - **`index.html`** [[Enlace a index.html](file:///home/sebastian/Proyectos/HackDays/static/index.html)]: Estructura del chat y barra lateral.
  - **`style.css`** [[Enlace a style.css](file:///home/sebastian/Proyectos/HackDays/static/style.css)]: Diseño de componentes, animaciones y paleta de colores.
  - **`app.js`** [[Enlace a app.js](file:///home/sebastian/Proyectos/HackDays/static/app.js)]: Controladores de eventos de la UI, peticiones AJAX y renderizado de Markdown.
- **`requirements.txt`** [[Enlace a requirements.txt](file:///home/sebastian/Proyectos/HackDays/requirements.txt)]: Lista de dependencias de Python.
