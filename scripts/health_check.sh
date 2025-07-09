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
