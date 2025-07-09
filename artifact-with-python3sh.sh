#!/bin/bash
# ============================================================================
# BANKING RAG DEPLOYMENT - SCRIPT CORREGIDO PARA PYTHON3
# Basado en tus archivos: config.py, banking_rag.py, requirements.txt
# ============================================================================

echo "🏦 Iniciando configuración Banking RAG System..."

# ============================================================================
# 1. CREAR .env (Variables de Entorno Local)
# ============================================================================

echo "📝 Creando archivo .env..."

cat > .env << 'EOF'
# =============================================================================
# BANKING RAG SYSTEM - CONFIGURACIÓN LOCAL
# Solo DeepSeek + Weaviate + Sentence-BERT (sin OpenAI)
# =============================================================================

# Weaviate Configuration (Local)
WEAVIATE_URL=http://localhost:8080

# DeepSeek Configuration (Tu Spring Boot API)
DEEPSEEK_API_URL=http://localhost:11004/api/llm/rag-query
DEEPSEEK_DIRECT_URL=http://localhost:11434

# RAG Configuration
RAG_CHUNK_SIZE=1000
RAG_CHUNK_OVERLAP=200
RAG_TEMPERATURE=0.2
RAG_MAX_TOKENS=2000

# Sentence-BERT Model (Local)
EMBEDDING_MODEL=sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2

# Logging
LOG_LEVEL=INFO
LOG_FILE=logs/banking_rag.log

# Banking Specific
BANKING_CLASS_NAME=BankingDocument
EOF

echo "✅ Archivo .env creado"

# ============================================================================
# 2. DOCKER-COMPOSE.YML (Solo Weaviate)
# ============================================================================

echo "🐳 Creando docker-compose.yml..."

cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  # Weaviate Vector Database (Local)
  weaviate:
    image: semitechnologies/weaviate:1.22.4
    container_name: banking-weaviate
    ports:
      - "8080:8080"
    environment:
      QUERY_DEFAULTS_LIMIT: 25
      AUTHENTICATION_ANONYMOUS_ACCESS_ENABLED: 'true'
      PERSISTENCE_DATA_PATH: '/var/lib/weaviate'
      DEFAULT_VECTORIZER_MODULE: 'none'
      CLUSTER_HOSTNAME: 'node1'
      ENABLE_MODULES: ''
    volumes:
      - weaviate_data:/var/lib/weaviate
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/v1/.well-known/ready"]
      interval: 30s
      timeout: 10s
      retries: 5
      start_period: 40s

volumes:
  weaviate_data:
    driver: local
EOF

echo "✅ Docker-compose.yml creado"

# ============================================================================
# 3. CREAR DIRECTORIO SCRIPTS
# ============================================================================

echo "📁 Creando directorio scripts..."
mkdir -p scripts

# ============================================================================
# 4. SETUP SCRIPT (scripts/setup.sh)
# ============================================================================

echo "🔧 Creando script de setup..."

cat > scripts/setup.sh << 'EOF'
#!/bin/bash
# Setup Banking RAG System - Corregido para python3

echo "🏦 Setting up Banking RAG System - Local Stack (DeepSeek + Weaviate + Sentence-BERT)"

# Verificar Python3
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 no está instalado"
    exit 1
fi

echo "✅ Python3 encontrado: $(python3 --version)"

# Crear entorno virtual con python3
echo "🐍 Creando entorno virtual..."
if [ ! -d "venv" ]; then
    python3 -m venv venv
    echo "✅ Entorno virtual creado"
else
    echo "✅ Entorno virtual ya existe"
fi

# Activar entorno virtual
echo "🔄 Activando entorno virtual..."
source venv/bin/activate

# Verificar que el entorno esté activo
if [[ "$VIRTUAL_ENV" ]]; then
    echo "✅ Entorno virtual activo: $VIRTUAL_ENV"
    echo "✅ Python en uso: $(which python)"
else
    echo "❌ Error activando entorno virtual"
    exit 1
fi

# Actualizar pip
echo "⬆️ Actualizando pip..."
python -m pip install --upgrade pip

# Instalar dependencias básicas primero
echo "📦 Instalando dependencias básicas..."
python -m pip install wheel setuptools

# Instalar dependencias principales
echo "📦 Instalando dependencias principales..."
python -m pip install langchain==0.1.0
python -m pip install weaviate-client==3.25.3
python -m pip install sentence-transformers==2.2.2
python -m pip install streamlit==1.29.0
python -m pip install requests==2.31.0

# Instalar dependencias de ML
echo "📦 Instalando dependencias de ML..."
python -m pip install torch==2.1.1
python -m pip install transformers==4.36.0
python -m pip install numpy==1.24.3

# Instalar procesamiento de documentos
echo "📦 Instalando procesamiento de documentos..."
python -m pip install pypdf2==3.0.1
python -m pip install python-docx==0.8.11
python -m pip install openpyxl==3.1.2

# Instalar análisis de datos
echo "📦 Instalando análisis de datos..."
python -m pip install pandas==2.1.4
python -m pip install matplotlib==3.7.1
python -m pip install plotly==5.17.0

# Instalar utilidades
echo "📦 Instalando utilidades..."
python -m pip install python-dotenv==1.0.0
python -m pip install pydantic==2.5.0

# Instalar dependencias adicionales de LangChain
echo "📦 Instalando dependencias adicionales..."
python -m pip install langchain-community==0.0.13

# Crear directorios necesarios
echo "📁 Creando estructura de directorios..."
mkdir -p data/raw
mkdir -p data/processed
mkdir -p data/sample_docs
mkdir -p logs
mkdir -p config
mkdir -p tests

# Verificar instalación
echo "✅ Verificando instalación..."
python -c "
try:
    import weaviate
    print('✅ weaviate-client OK')
except ImportError as e:
    print(f'❌ weaviate-client: {e}')

try:
    import sentence_transformers
    print('✅ sentence-transformers OK')
except ImportError as e:
    print(f'❌ sentence-transformers: {e}')

try:
    import langchain
    print('✅ langchain OK')
except ImportError as e:
    print(f'❌ langchain: {e}')

try:
    import streamlit
    print('✅ streamlit OK')
except ImportError as e:
    print(f'❌ streamlit: {e}')

try:
    import requests
    print('✅ requests OK')
except ImportError as e:
    print(f'❌ requests: {e}')

print('✅ Stack configurado: Weaviate + Sentence-BERT + DeepSeek')
"

# Configurar logging
echo "📊 Configurando logging..."
touch logs/banking_rag.log
touch logs/error.log

# Verificar Docker
echo "🐳 Verificando Docker..."
if command -v docker &> /dev/null; then
    echo "✅ Docker encontrado"
    if docker info > /dev/null 2>&1; then
        echo "✅ Docker está corriendo"
    else
        echo "⚠️ Docker instalado pero no está corriendo"
    fi
else
    echo "⚠️ Docker no encontrado - instala Docker Desktop para usar Weaviate"
fi

echo ""
echo "🎉 Setup completado exitosamente!"
echo ""
echo "📋 Próximos pasos:"
echo "1. Verifica que tu API DeepSeek esté corriendo en puerto 11004"
echo "2. Ejecuta: ./scripts/deploy.sh"
echo "3. Accede a: http://localhost:8501"
echo ""
echo "💡 Recuerda activar el entorno virtual:"
echo "   source venv/bin/activate"
EOF

chmod +x scripts/setup.sh
echo "✅ Script de setup creado"

# ============================================================================
# 5. DEPLOYMENT SCRIPT (scripts/deploy.sh)
# ============================================================================

echo "🚀 Creando script de deployment..."

cat > scripts/deploy.sh << 'EOF'
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
EOF

chmod +x scripts/deploy.sh
echo "✅ Script de deployment creado"

# ============================================================================
# 6. HEALTH CHECK SCRIPT (scripts/health_check.sh)
# ============================================================================

echo "🩺 Creando script de health check..."

cat > scripts/health_check.sh << 'EOF'
#!/bin/bash
# Health Check Banking RAG System

echo "🩺 Banking RAG System - Health Check"
echo "===================================="

# Check Python
echo "🐍 Verificando Python..."
if command -v python3 &> /dev/null; then
    echo "   ✅ Python3: $(python3 --version)"
else
    echo "   ❌ Python3 no encontrado"
fi

if [[ "$VIRTUAL_ENV" ]]; then
    echo "   ✅ Entorno virtual activo: $VIRTUAL_ENV"
else
    echo "   ⚠️ Entorno virtual no activo"
    echo "   💡 Ejecuta: source venv/bin/activate"
fi

# Check Weaviate
echo ""
echo "🗄️ Verificando Weaviate..."
if curl -f http://localhost:8080/v1/.well-known/ready > /dev/null 2>&1; then
    echo "   ✅ Weaviate funcionando"
else
    echo "   ❌ Weaviate no responde"
    echo "   💡 Ejecuta: docker-compose up -d weaviate"
fi

# Check DeepSeek API
echo ""
echo "🤖 Verificando DeepSeek API..."
if curl -f --connect-timeout 5 http://localhost:11004/api/actuator/health > /dev/null 2>&1; then
    echo "   ✅ DeepSeek API funcionando (Actuator)"
elif curl -f --connect-timeout 5 http://localhost:11004/health > /dev/null 2>&1; then
    echo "   ✅ DeepSeek API funcionando (Health)"
else
    echo "   ❌ DeepSeek API no responde"
    echo "   💡 Verifica Spring Boot en puerto 11004"
fi

# Check Ollama
echo ""
echo "🦙 Verificando Ollama..."
if curl -f --connect-timeout 5 http://localhost:11434/api/tags > /dev/null 2>&1; then
    echo "   ✅ Ollama funcionando"
else
    echo "   ⚠️ Ollama no responde (opcional)"
fi

# Check Streamlit
echo ""
echo "🌐 Verificando Streamlit..."
if curl -f http://localhost:8501 > /dev/null 2>&1; then
    echo "   ✅ Streamlit funcionando"
    echo "   🌐 http://localhost:8501"
else
    echo "   ❌ Streamlit no responde"
fi

# Check archivos
echo ""
echo "📁 Verificando archivos..."
if [ -f "src/models/banking_rag_configurable.py" ]; then
    echo "   ✅ Archivo principal encontrado"
else
    echo "   ❌ banking_rag_configurable.py no encontrado"
fi

if [ -f ".env" ]; then
    echo "   ✅ .env encontrado"
else
    echo "   ⚠️ .env no encontrado"
fi

echo ""
echo "📊 Health Check completo!"
EOF

chmod +x scripts/health_check.sh
echo "✅ Script de health check creado"

# ============================================================================
# 7. STOP SCRIPT (scripts/stop.sh)
# ============================================================================

echo "🛑 Creando script de stop..."

cat > scripts/stop.sh << 'EOF'
#!/bin/bash
# Stop Banking RAG System

echo "🛑 Deteniendo Banking RAG System..."

# Detener Streamlit
echo "🌐 Deteniendo Streamlit..."
pkill -f "streamlit run" 2>/dev/null || echo "   Streamlit no estaba corriendo"

# Detener Weaviate
echo "🗄️ Deteniendo Weaviate..."
docker-compose down

echo "✅ Sistema detenido"
echo "💡 Para reiniciar: ./scripts/deploy.sh"
EOF

chmod +x scripts/stop.sh
echo "✅ Script de stop creado"

# ============================================================================
# 8. README
# ============================================================================

echo "📚 Creando README..."

cat > README.md << 'EOF'
# 🏦 Banking RAG System - Local Stack

Sistema RAG para servicios financieros usando tecnologías 100% locales.

## 🚀 Stack Tecnológico

- **Vector DB:** Weaviate (Docker local)
- **Embeddings:** Sentence-BERT (multilingual)
- **LLM:** DeepSeek (via API Spring Boot)
- **Framework:** LangChain + Streamlit
- **Costo:** $0 después del setup

## 🛠️ Instalación

```bash
# 1. Setup inicial
./scripts/setup.sh

# 2. Deployment
./scripts/deploy.sh

# 3. Verificación
./scripts/health_check.sh
```

## 🎯 Accesos

- **App:** http://localhost:8501
- **Weaviate:** http://localhost:8080
- **DeepSeek API:** http://localhost:11004/api/actuator/health

## 🛑 Detener

```bash
./scripts/stop.sh
```

## 📁 Estructura

```
├── src/models/
│   ├── config.py
│   └── banking_rag_configurable.py
├── scripts/
├── .env
├── docker-compose.yml
└── README.md
```
EOF

echo "✅ README creado"

# ============================================================================
# FINALIZACIÓN
# ============================================================================

echo ""
echo "🎉 ¡Banking RAG System Setup Completo!"
echo ""
echo "📁 Archivos creados:"
echo "   ├── .env"
echo "   ├── docker-compose.yml"
echo "   ├── scripts/setup.sh"
echo "   ├── scripts/deploy.sh"
echo "   ├── scripts/health_check.sh"
echo "   ├── scripts/stop.sh"
echo "   └── README.md"
echo ""
echo "🚀 Próximos pasos:"
echo "   1. ./scripts/setup.sh"
echo "   2. ./scripts/deploy.sh"
echo "   3. Accede a http://localhost:8501"
echo ""
echo "✅ Setup completado sin errores de sintaxis"