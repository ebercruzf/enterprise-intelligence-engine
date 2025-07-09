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
