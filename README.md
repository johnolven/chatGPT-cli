
# chatgpt-cli

El proyecto chatgpt-cli proporciona una herramienta de línea de comandos (CLI) para interactuar con ChatGPT de OpenAI mediante un script de shell. Esta herramienta permite a los usuarios hacer preguntas directamente desde la terminal y recibir respuestas en tiempo real. Además, soporta un modo interactivo que guarda el historial de las conversaciones, lo que facilita continuar conversaciones previas. Los usuarios también pueden seleccionar entre diferentes modelos de ChatGPT disponibles y ver el historial de las últimas 10 conversaciones. Este proyecto está diseñado para ser fácil de configurar y usar, proporcionando una experiencia fluida para aquellos que necesitan interactuar con modelos de lenguaje avanzados directamente desde la terminal.

## Requisitos

- `curl`
- `jq`
- OpenAI API key with access to GPT-4

## Instalación

1. Clona el repositorio:

    ```bash
    git clone https://github.com/johnolven/chatGPT-cli
    cd chatGPT-cli
    ```

2. Haz que el archivo del script sea ejecutable:

    ```bash
    chmod +x chatgpt-cli.sh
    ```

3. Crea un alias en tu archivo de configuración del shell (por ejemplo, `~/.bashrc`, `~/.zshrc`):

    ```bash
    nano ~/.zshrc  # o ~/.bashrc
    ```

4. Añade la siguiente línea para crear un alias:

    ```bash
    alias GPT='~/chatgpt-cli/chatgpt-cli.sh'
    ```

5. Recarga tu archivo de configuración del shell:

    ```bash
    source ~/.zshrc  # o ~/.bashrc
    ```

## Uso

### Interacción Normal (una sola pregunta)

Para hacer una sola pregunta a ChatGPT:

```bash
GPT "¿Cuál es la capital de México?"
```

### Modo Interactivo (con historial y resumen)

Para entrar en modo interactivo:

```bash
GPT -i
```

### Seleccionar Modelo

Para seleccionar el modelo de ChatGPT:

```bash
GPT -m
```

### Mostrar Historial

Para mostrar el historial de las últimas 10 conversaciones:

```bash
GPT -h
```

## Configuración

El script `chatgpt_interactive.sh` guarda la configuración y el historial de las conversaciones en el directorio `~/.chatgpt.config`. Esta carpeta se crea automáticamente la primera vez que ejecutas el script. Dentro de este directorio, encontrarás los siguientes archivos y carpetas:

### Ruta de Configuración

- `~/.chatgpt.config/config.json`: Este archivo guarda tu API key de OpenAI y el modelo seleccionado. Si no has proporcionado una API key o seleccionado un modelo, se te pedirá que lo hagas la primera vez que ejecutes el script.

### Modelo

- Al ejecutar `GPT -m`, puedes seleccionar entre los diferentes modelos de ChatGPT disponibles. Tu selección se guarda en `~/.chatgpt.config/config.json`. Si deseas cambiar el modelo en cualquier momento, simplemente ejecuta `GPT -m` de nuevo.

### Historial

- `~/.chatgpt.config/history/`: Este directorio guarda el historial de tus conversaciones. Cada conversación se guarda en un archivo JSON con un nombre basado en un resumen de la conversación y un timestamp. Por ejemplo: `Saludo-inicial-y-oferta-de-ayuda-20240622113659.json`.

### Opciones de Ejecución

- **Interacción Normal (una sola pregunta)**: Al ejecutar `GPT "tu pregunta"`, la pregunta y la respuesta se guardan en un nuevo archivo de historial.
- **Modo Interactivo**: Al ejecutar `GPT -i`, puedes mantener una conversación continua con ChatGPT, y cada interacción se guarda automáticamente en el archivo de historial correspondiente.
- **Mostrar Historial**: Al ejecutar `GPT -h`, puedes ver los últimos 10 historiales de conversación y seleccionar uno para continuar la conversación desde donde la dejaste.
- **Seleccionar Modelo**: Al ejecutar `GPT -m`, puedes seleccionar y cambiar el modelo de ChatGPT que deseas utilizar.


Podrás seleccionar una conversación anterior y continuar desde donde la dejaste.

## Licencia

Este proyecto está licenciado bajo la Licencia MIT. Consulta el archivo `LICENSE` para más detalles.

## Contacto

Para preguntas o consultas, contacta a JohnOlven en [hola@johnolven.com](mailto:hola@johnolven.com).
