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
