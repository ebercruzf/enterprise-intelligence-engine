#!/bin/bash
# Script de verificación y solución rápida - Versión 2 (Docker Compose v2)

echo "🔧 Banking RAG - Diagnóstico y Solución v2"
echo "=========================================="

# 1. Verificar directorio actual
echo "📍 Directorio actual: $(pwd)"

# 2. Verificar estructura src/
echo ""
echo "📂 Verificando estructura src/..."
if [ -d "src" ]; then
    echo "✅ Directorio src/ existe"
    if [ -d "src/models" ]; then
        echo "✅ Directorio src/models/ existe"
    else
        echo "❌ Directorio src/models/ no existe"
        echo "🔧 Creando src/models/..."
        mkdir -p src/models
        echo "✅ Directorio src/models/ creado"
    fi
else
    echo "❌ Directorio src/ no existe"
    echo "🔧 Creando estructura completa..."
    mkdir -p src/models
    echo "✅ Estructura creada"
fi

# 3. Verificar entorno virtual
echo ""
echo "🐍 Verificando entorno virtual..."
if [ -d "venv" ]; then
    echo "✅ Entorno virtual existe"
    if [[ "$VIRTUAL_ENV" ]]; then
        echo "✅ Entorno virtual activo: $VIRTUAL_ENV"
    else
        echo "⚠️ Entorno virtual no activo"
        echo "🔧 Activando entorno virtual..."
        source venv/bin/activate
        if [[ "$VIRTUAL_ENV" ]]; then
            echo "✅ Entorno virtual activado"
        else
            echo "❌ Error activando entorno virtual"
        fi
    fi
else
    echo "❌ Entorno virtual no existe"
    echo "🔧 Creando entorno virtual..."
    python3 -m venv venv
    source venv/bin/activate
    echo "✅ Entorno virtual creado y activado"
fi

# 4. Verificar dependencias críticas
echo ""
echo "📦 Verificando dependencias críticas..."
if [[ "$VIRTUAL_ENV" ]]; then
    python -c "
import sys
packages = ['streamlit', 'weaviate', 'langchain', 'requests', 'sentence_transformers']
missing = []
for pkg in packages:
    try:
        __import__(pkg)
        print(f'✅ {pkg} disponible')
    except ImportError:
        missing.append(pkg)
        print(f'❌ {pkg} faltante')

if missing:
    print(f'📦 Instalar: pip install {\" \".join(missing)}')
    " 2>/dev/null
else
    echo "⚠️ Entorno virtual no activo, no se pueden verificar dependencias"
fi

# 5. Verificar Docker y Weaviate (NUEVA SINTAXIS)
echo ""
echo "🐳 Verificando Docker..."
if command -v docker &> /dev/null; then
    echo "✅ Docker encontrado"
    if docker info > /dev/null 2>&1; then
        echo "✅ Docker corriendo"
        
        # Verificar sintaxis Docker Compose
        if command -v "docker compose" &> /dev/null; then
            echo "✅ Docker Compose v2 disponible"
            COMPOSE_CMD="docker compose"
        elif command -v docker-compose &> /dev/null; then
            echo "✅ Docker Compose v1 disponible"
            COMPOSE_CMD="docker-compose"
        else
            echo "❌ Docker Compose no encontrado"
            COMPOSE_CMD=""
        fi
        
        # Verificar Weaviate
        if [ ! -z "$COMPOSE_CMD" ]; then
            echo "🗄️ Verificando Weaviate..."
            if docker ps | grep -q weaviate; then
                echo "✅ Weaviate container corriendo"
            else
                echo "❌ Weaviate container no corriendo"
                echo "🔧 Iniciando Weaviate..."
                $COMPOSE_CMD up -d weaviate
                
                # Esperar a que Weaviate esté listo
                echo "⏳ Esperando a que Weaviate esté listo..."
                timeout=60
                while [ $timeout -gt 0 ]; do
                    if curl -f http://localhost:8080/v1/.well-known/ready > /dev/null 2>&1; then
                        echo "✅ Weaviate está listo!"
                        break
                    fi
                    sleep 5
                    timeout=$((timeout-5))
                done
                
                if [ $timeout -le 0 ]; then
                    echo "⚠️ Timeout esperando a Weaviate"
                fi
            fi
        fi
    else
        echo "❌ Docker no está corriendo"
        echo "💡 Inicia Docker Desktop"
    fi
else
    echo "❌ Docker no encontrado"
fi

# 6. Verificar API DeepSeek
echo ""
echo "🤖 Verificando API DeepSeek..."
if curl -f --connect-timeout 5 http://localhost:11004/api/actuator/health > /dev/null 2>&1; then
    echo "✅ DeepSeek API funcionando"
else
    echo "⚠️ DeepSeek API no disponible (verificando otros endpoints...)"
    
    # Intentar otros endpoints
    if curl -f --connect-timeout 5 http://localhost:11004/health > /dev/null 2>&1; then
        echo "✅ DeepSeek API funcionando (endpoint /health)"
    elif curl -f --connect-timeout 5 http://localhost:11004/ > /dev/null 2>&1; then
        echo "✅ DeepSeek servicio funcionando (endpoint raíz)"
    else
        echo "❌ DeepSeek API no disponible"
        echo "💡 Verifica que Spring Boot esté corriendo en puerto 11004"
    fi
fi

# 7. Verificar archivo principal
echo ""
echo "📝 Verificando archivos principales..."
if [ ! -f "src/models/banking_rag_configurable.py" ]; then
    echo "❌ banking_rag_configurable.py no encontrado"
    echo "💡 El archivo ya fue creado en el chat anterior"
    echo "📍 Cópialo desde el artifact a: src/models/banking_rag_configurable.py"
else
    echo "✅ banking_rag_configurable.py encontrado"
fi

if [ ! -f "src/models/config.py" ]; then
    echo "❌ config.py no encontrado"
    echo "💡 Necesitas copiar este archivo desde tu código original"
else
    echo "✅ config.py encontrado"
fi

# 8. Instalar dependencias si faltan
echo ""
echo "📦 Verificando e instalando dependencias..."
if [[ "$VIRTUAL_ENV" ]]; then
    echo "🔧 Instalando dependencias necesarias..."
    
    # Lista de dependencias críticas
    DEPS="streamlit weaviate-client langchain sentence-transformers requests python-dotenv pandas torch transformers"
    
    for dep in $DEPS; do
        if python -c "import $dep" 2>/dev/null; then
            echo "✅ $dep ya instalado"
        else
            echo "📦 Instalando $dep..."
            pip install $dep --quiet
        fi
    done
    
    echo "✅ Verificación de dependencias completada"
else
    echo "⚠️ Entorno virtual no activo - no se pueden instalar dependencias"
fi

# 9. Crear comando de inicio rápido
echo ""
echo "🚀 Creando comando de inicio rápido..."
cat > start_banking_rag.sh << 'EOF'
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
EOF

chmod +x start_banking_rag.sh
echo "✅ Comando de inicio creado: ./start_banking_rag.sh"

# 10. Resumen final
echo ""
echo "🎯 Resumen de acciones necesarias:"
echo "================================="

# Generar lista de acciones
ACTIONS_NEEDED=()

if [[ ! "$VIRTUAL_ENV" ]]; then
    ACTIONS_NEEDED+=("source venv/bin/activate")
fi

if [ ! -f "src/models/banking_rag_configurable.py" ]; then
    ACTIONS_NEEDED+=("Copiar banking_rag_configurable.py desde el artifact")
fi

if ! docker ps | grep -q weaviate; then
    if command -v "docker compose" &> /dev/null; then
        ACTIONS_NEEDED+=("docker compose up -d weaviate")
    else
        ACTIONS_NEEDED+=("docker-compose up -d weaviate")
    fi
fi

if [ ${#ACTIONS_NEEDED[@]} -eq 0 ]; then
    echo "✅ Todo parece estar en orden!"
    echo "🚀 Puedes ejecutar: ./start_banking_rag.sh"
    echo "🌐 O directamente: streamlit run src/models/banking_rag_configurable.py"
else
    echo "📋 Acciones pendientes:"
    for i in "${!ACTIONS_NEEDED[@]}"; do
        echo "   $((i+1)). ${ACTIONS_NEEDED[$i]}"
    done
fi

echo ""
echo "💡 Comandos útiles:"
echo "   ./start_banking_rag.sh          # Inicio rápido"
echo "   ./scripts/health_check.sh       # Verificar estado"
echo "   docker compose logs weaviate    # Ver logs Weaviate"
echo "   docker compose down             # Detener todo"
echo ""
echo "🎉 Diagnóstico completado!"