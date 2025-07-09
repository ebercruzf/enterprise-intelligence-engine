#!/bin/bash
# Deploy Banking RAG System - Corregido para python3

echo "🚀 Desplegando Banking RAG System (Stack Local)"

# Verificar archivo principal
if [ ! -f "src/models/banking_rag_configurable.py" ]; then
    echo "❌ No se encuentra banking_rag_configurable.py"
    echo "   Asegúrate de estar en el directorio raíz del proyecto"
    exit 1
fi

# Verificar Python3
if ! command -v python3 &> /dev/null; then
    echo "❌ Python3 no está instalado"
    exit 1
fi

# Verificar entorno virtual
if [ ! -d "venv" ]; then
    echo "❌ Entorno virtual no encontrado. Ejecuta primero: ./scripts/setup.sh"
    exit 1
fi

# Activar entorno virtual
echo "🐍 Activando entorno virtual..."
source venv/bin/activate

if [[ ! "$VIRTUAL_ENV" ]]; then
    echo "❌ Error activando entorno virtual"
    exit 1
fi

echo "✅ Entorno virtual activo: $VIRTUAL_ENV"

# Verificar Docker
if ! command -v docker &> /dev/null; then
    echo "❌ Docker no está instalado. Instala Docker Desktop."
    exit 1
fi

if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker no está corriendo. Inicia Docker Desktop."
    exit 1
fi

# Verificar API DeepSeek
echo "🤖 Verificando API DeepSeek..."
if curl -f --connect-timeout 5 http://localhost:11004/api/actuator/health > /dev/null 2>&1; then
    echo "✅ API DeepSeek disponible (Spring Boot Actuator)"
elif curl -f --connect-timeout 5 http://localhost:11004/health > /dev/null 2>&1; then
    echo "✅ API DeepSeek disponible (endpoint health)"
else
    echo "⚠️ API DeepSeek no disponible - el sistema usará DEEPSEEK_DIRECT (Ollama)"
fi

# Verificar Ollama como fallback
echo "🦙 Verificando Ollama (fallback)..."
if curl -f --connect-timeout 5 http://localhost:11434/api/tags > /dev/null 2>&1; then
    echo "✅ Ollama disponible como fallback"
else
    echo "⚠️ Ollama no disponible"
fi

# Iniciar Weaviate
echo "🗄️ Iniciando Weaviate..."
docker-compose up -d weaviate

# Esperar Weaviate
echo "⏳ Esperando a que Weaviate esté listo..."
timeout=120
while [ $timeout -gt 0 ]; do
    if curl -f http://localhost:8080/v1/.well-known/ready > /dev/null 2>&1; then
        echo "✅ Weaviate está listo!"
        break
    fi
    echo "   Esperando... ($timeout segundos restantes)"
    sleep 5
    timeout=$((timeout-5))
done

if [ $timeout -le 0 ]; then
    echo "❌ Timeout esperando a Weaviate"
    exit 1
fi

# Verificar dependencias
echo "🔍 Verificando dependencias..."
python -c "
import sys
try:
    import weaviate, sentence_transformers, langchain, streamlit
    print('✅ Dependencias verificadas')
except ImportError as e:
    print(f'❌ Dependencia faltante: {e}')
    sys.exit(1)
"

if [ $? -ne 0 ]; then
    echo "❌ Error en verificación de dependencias"
    exit 1
fi

# Configurar PYTHONPATH
export PYTHONPATH="${PYTHONPATH}:$(pwd)/src"

# Ejecutar aplicación
echo "🌐 Iniciando aplicación Banking RAG..."
echo ""
echo "🎯 Accede en: http://localhost:8501"
echo "🗄️ Weaviate: http://localhost:8080"
echo "🤖 DeepSeek API: http://localhost:11004/api/actuator/health"
echo ""
echo "🛑 Para detener: Ctrl+C y luego 'docker-compose down'"
echo ""

streamlit run src/models/banking_rag_configurable.py \
    --server.port=8501 \
    --server.address=0.0.0.0 \
    --server.headless=true \
    --server.fileWatcherType=none
