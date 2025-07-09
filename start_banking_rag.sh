#!/bin/bash
# Comando de inicio rápido para Banking RAG

echo "🏦 Iniciando Banking RAG System..."

# Activar entorno virtual
if [ -d "venv" ]; then
    source venv/bin/activate
    echo "✅ Entorno virtual activado"
else
    echo "❌ Entorno virtual no encontrado"
    exit 1
fi

# Verificar Weaviate
if ! curl -f http://localhost:8080/v1/.well-known/ready > /dev/null 2>&1; then
    echo "🗄️ Iniciando Weaviate..."
    if command -v "docker compose" &> /dev/null; then
        docker compose up -d weaviate
    else
        docker-compose up -d weaviate
    fi
    
    # Esperar
    echo "⏳ Esperando Weaviate..."
    sleep 10
fi

# Configurar PYTHONPATH
export PYTHONPATH="${PYTHONPATH}:$(pwd)/src"

# Iniciar aplicación
echo "🌐 Iniciando aplicación en http://localhost:8501"
streamlit run src/models/banking_rag_configurable.py --server.port=8501
