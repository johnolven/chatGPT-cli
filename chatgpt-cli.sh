#!/bin/bash

CONFIG_DIR="$HOME/.chatgpt.config"
HISTORY_DIR="$CONFIG_DIR/history"
CONFIG_FILE="$CONFIG_DIR/config.json"

# Crear los directorios si no existen
mkdir -p "$HISTORY_DIR"

# Función para obtener la API key
get_api_key() {
    if [ -f "$CONFIG_FILE" ]; then
        API_KEY=$(jq -r '.api_key' "$CONFIG_FILE")
    else
        read -p "Introduce tu OpenAI API key: " API_KEY
        echo "{\"api_key\": \"$API_KEY\"}" > "$CONFIG_FILE"
    fi
}

# Obtener la API key
get_api_key

# Función para obtener el modelo
get_model() {
    if [ -f "$CONFIG_FILE" ]; then
        MODEL=$(jq -r '.model' "$CONFIG_FILE")
        if [ "$MODEL" == "null" ] || [ -z "$MODEL" ]; then
            select_model
        fi
    else
        select_model
    fi
}

# Función para seleccionar el modelo
select_model() {
    echo "Obteniendo lista de modelos disponibles..."
    RESPONSE=$(curl -s https://api.openai.com/v1/models \
    -H "Authorization: Bearer $API_KEY")
    MODELS=$(echo "$RESPONSE" | jq -r '.data[].id')
    echo "Modelos disponibles:"
    select MODEL in $MODELS; do
        if [ -n "$MODEL" ]; then
            echo "Modelo seleccionado: $MODEL"
            echo "{\"api_key\": \"$API_KEY\", \"model\": \"$MODEL\"}" > "$CONFIG_FILE"
            break
        else
            echo "Selección inválida. Intenta de nuevo."
        fi
    done
}

# Obtener el modelo
get_model

# Función para enviar solicitud de texto a la API
send_text_request() {
    local history=$1
    curl -s https://api.openai.com/v1/chat/completions \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $API_KEY" \
    -d '{
        "model": "'"${MODEL}"'",
        "messages": '"${history}"'
    }' | jq -r '.choices[0].message.content'
}

# Función para enviar solicitud de imagen a la API
send_image_request() {
    local prompt=$1
    curl -s https://api.openai.com/v1/images/generations \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $API_KEY" \
    -d '{
        "model": "'"${MODEL}"'",
        "prompt": "'"${prompt}"'",
        "num_images": 1
    }' | jq -r '.data[0].url'
}

# Función para obtener el timestamp en UTC
get_timestamp() {
    date -u +"%Y-%m-%dT%H:%M:%SZ"
}

# Función para guardar el historial
save_history() {
    local session_file=$1
    local history=$2
    echo "{\"model\": \"$MODEL\", \"history\": $history}" > "$session_file"
}

# Modo interactivo
interactive_mode() {
    # Crear un nuevo archivo de historial
    local session_file="$1"
    local resume_mode="$2"
    if [ -z "$session_file" ]; then
        local timestamp=$(date +%Y%m%d%H%M%S)
        session_file="$HISTORY_DIR/history_$timestamp.json"
        echo "{\"model\": \"$MODEL\", \"history\": []}" > "$session_file"
    fi

    # Leer el historial del archivo
    session_data=$(cat "$session_file")
    HISTORY=$(echo "$session_data" | jq -c '.history')

    if [ "$resume_mode" == "resume" ]; then
        echo "ChatGPT: Listo.. sigamos con la conversación."
    else
        # Añadir el prompt al historial al iniciar una nueva sesión
        SYSTEM_PROMPT='{"role": "system", "content": "Eres ChatGPT, un modelo avanzado de inteligencia artificial diseñado para asistir a programadores, desarrolladores y expertos en automatización en la terminal. Proporciona respuestas claras, concisas y técnicas a las consultas relacionadas con programación, automatización, código y otros temas avanzados. Asegúrate de incluir ejemplos de código y explicaciones detalladas cuando sea necesario."}'
        HISTORY=$(jq -n --argjson prompt "$SYSTEM_PROMPT" '[{"role": "system", "content": $prompt.content}]')
    fi

    while true; do
        echo -n "Tú: "
        read USER_MESSAGE
        if [[ "$USER_MESSAGE" == "exit" ]]; then
            echo "Hasta luego"
            break
        fi

        # Añadir el nuevo mensaje del usuario al historial con timestamp
        TIMESTAMP=$(get_timestamp)
        HISTORY=$(jq --arg content "$USER_MESSAGE" --arg timestamp "$TIMESTAMP" '. + [{"role": "user", "content": $content, "timestamp": $timestamp}]' <<< "$HISTORY")

        # Guardar el historial actualizado en el archivo
        save_history "$session_file" "$HISTORY"

        # Mostrar el mensaje de "escribiendo..." o "procesando..."
        if [[ "$MODEL" == *"dall-e"* ]]; then
            echo "ChatGPT (procesando...)"
        else
            echo "ChatGPT (escribiendo...)"
        fi

        # Enviar la solicitud y obtener la respuesta
        if [[ "$MODEL" == *"dall-e"* ]]; then
            RESPONSE_MESSAGE=$(send_image_request "$USER_MESSAGE")
        else
            RESPONSE_MESSAGE=$(send_text_request "$HISTORY")
        fi

        # Borrar la línea de "escribiendo..." o "procesando..." y mostrar la respuesta
        tput cuu1 && tput el
        echo "ChatGPT: $RESPONSE_MESSAGE"

        # Añadir la respuesta del modelo al historial con timestamp
        TIMESTAMP=$(get_timestamp)
        HISTORY=$(jq --arg content "$RESPONSE_MESSAGE" --arg timestamp "$TIMESTAMP" '. + [{"role": "assistant", "content": $content, "timestamp": $timestamp}]' <<< "$HISTORY")

        # Guardar el historial actualizado en el archivo
        save_history "$session_file" "$HISTORY"
    done

    # Generar el título del resumen de la conversación
    SUMMARY_REQUEST=$(jq -n --arg history "$HISTORY" '[{"role": "system", "content": "Resumen de la conversación en 5 palabras o menos:"}, {"role": "user", "content": $history}]')
    SUMMARY_RESPONSE=$(curl -s https://api.openai.com/v1/chat/completions \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $API_KEY" \
    -d '{
        "model": "gpt-4",
        "messages": '"${SUMMARY_REQUEST}"'
    }')
    SUMMARY=$(echo "$SUMMARY_RESPONSE" | jq -r '.choices[0].message.content' | tr ' ' '-')
    SUMMARY_TITLE=$(echo "$SUMMARY" | cut -c 1-50)

    # Renombrar el archivo con el título del resumen
    mv "$session_file" "$HISTORY_DIR/$SUMMARY_TITLE.json"
}

# Mostrar el historial
show_history() {
    echo "Historial de conversaciones:"
    files=($(ls -t "$HISTORY_DIR" | head -n 10))
    select file in "${files[@]}"; do
        if [ -n "$file" ]; then
            echo "Archivo seleccionado: $file"
            session_data=$(cat "$HISTORY_DIR/$file")
            MODEL=$(echo "$session_data" | jq -r '.model')
            echo "Modelo utilizado en esta conversación: $MODEL"
            read -p "¿Desea cambiar el modelo? (s/n): " change_model
            if [ "$change_model" == "s" ]; then
                select_model
            fi
            interactive_mode "$HISTORY_DIR/$file" "resume"
            break
        else
            echo "Selección inválida. Intenta de nuevo."
        fi
    done
}

# Verificar las opciones
while getopts ":imh" opt; do
    case ${opt} in
        i )
            interactive_mode
            ;;
        m )
            select_model
            ;;
        h )
            show_history
            ;;
        \? )
            echo "Opción inválida: $OPTARG" 1>&2
            ;;
        : )
            echo "La opción -$OPTARG requiere un argumento." 1>&2
            ;;
    esac
done

shift $((OPTIND -1))

# Modo de una sola pregunta si no se pasó ninguna opción
if [ $# -eq 0 ]; then
    exit 0
fi

USER_MESSAGE="$*"
TIMESTAMP=$(get_timestamp)

# Crear un nuevo archivo de historial para la sesión de una sola pregunta
timestamp=$(date +%Y%m%d%H%M%S)
session_file="$HISTORY_DIR/history_$timestamp.json"
echo "{\"model\": \"$MODEL\", \"history\": []}" > "$session_file"

if [[ "$MODEL" == *"dall-e"* ]]; then
    echo "ChatGPT (procesando...)"
    RESPONSE_MESSAGE=$(send_image_request "$USER_MESSAGE")
    tput cuu1 && tput el
    echo "ChatGPT: $RESPONSE_MESSAGE"

    # Añadir la interacción al historial y guardar
    HISTORY=$(jq -n --arg content "$USER_MESSAGE" --arg timestamp "$TIMESTAMP" '[{"role": "user", "content": $content, "timestamp": $timestamp}]')
    TIMESTAMP=$(get_timestamp)
    HISTORY=$(jq --arg content "$RESPONSE_MESSAGE" --arg timestamp "$TIMESTAMP" '. + [{"role": "assistant", "content": $content, "timestamp": $timestamp}]' <<< "$HISTORY")
    save_history "$session_file" "$HISTORY"
else
    HISTORY=$(jq -n --arg content "$USER_MESSAGE" --arg timestamp "$TIMESTAMP" '[{"role": "user", "content": $content, "timestamp": $timestamp}]')

    # Guardar el historial actualizado en el archivo
    save_history "$session_file" "$HISTORY"

    # Mostrar el mensaje de "escribiendo..."
    echo "ChatGPT (escribiendo...)"

    # Enviar la solicitud y obtener la respuesta
    RESPONSE_MESSAGE=$(send_text_request "$HISTORY")

    # Borrar la línea de "escribiendo..." y mostrar la respuesta
    tput cuu1 && tput el
    echo "ChatGPT: $RESPONSE_MESSAGE"

    # Añadir la respuesta del modelo al historial con timestamp
    TIMESTAMP=$(get_timestamp)
    HISTORY=$(jq --arg content "$RESPONSE_MESSAGE" --arg timestamp "$TIMESTAMP" '. + [{"role": "assistant", "content": $content, "timestamp": $timestamp}]' <<< "$HISTORY")

    # Guardar el historial actualizado en el archivo
    save_history "$session_file" "$HISTORY"
fi