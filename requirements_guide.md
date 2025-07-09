# 📋 Enterprise-intelligence-engine
Public - Requirements Configuration Guide

## 🎯 Estrategia de Configuración Flexible

Este `requirements.txt` está diseñado para soportar múltiples configuraciones:
- **🏠 Stack 100% Local:** Sin dependencias cloud
- **☁️ Stack Híbrido:** Local + algunos servicios cloud  
- **🌐 Stack Full Cloud:** APIs cloud para LLM y embeddings

## 🔧 Configuraciones por Casos de Uso

### 📦 **Configuración 1: Stack Completamente Local (Tu caso actual)**

```bash
# Instalar solo dependencias locales
pip install langchain==0.1.0 langchain-community==0.0.13
pip install weaviate-client==3.25.3
pip install sentence-transformers==2.2.2 torch==2.1.1 transformers==4.36.0
pip install requests==2.31.0 httpx==0.25.2
pip install streamlit==1.29.0
pip install pypdf2==3.0.1 python-docx==0.8.11 openpyxl==3.1.2
pip install pandas==2.1.4 numpy==1.24.3 matplotlib==3.7.1 plotly==5.17.0
pip install python-dotenv==1.0.0 pydantic==2.5.0 pyyaml==6.0.1
```

### 📦 **Configuración 2: Local + OpenAI para Emergencias**

```bash
# Agregar a la configuración local:
pip install openai==1.6.1
```

Entonces en tu código:
```python
class LLMProvider(Enum):
    DEEPSEEK_API = "deepseek_api"
    DEEPSEEK_DIRECT = "deepseek_direct"  
    OPENAI = "openai"                    # ✅ Ahora disponible

class EmbeddingProvider(Enum):
    SENTENCE_BERT = "sentence_bert"
    OPENAI = "openai"                    # ✅ Ahora disponible
```

### 📦 **Configuración 3: Híbrido con Vector DB Cloud**

```bash
# Todo lo local + Pinecone cloud para escalabilidad
pip install pinecone-client==2.2.4
```

### 📦 **Configuración 4: Full Cloud para Producción**

```bash
# Instalar todas las opciones cloud
pip install openai==1.6.1 anthropic==0.8.1 cohere==4.37
pip install pinecone-client==2.2.4 qdrant-client==1.6.9
```

## 🚀 Archivos de Requirements Modulares

### `requirements-base.txt` (Siempre necesario)
```txt
langchain==0.1.0
langchain-community==0.0.13
streamlit==1.29.0
requests==2.31.0
pandas==2.1.4
python-dotenv==1.0.0
```

### `requirements-local.txt` (Para stack local)
```txt
-r requirements-base.txt
weaviate-client==3.25.3
sentence-transformers==2.2.2
torch==2.1.1
```

### `requirements-cloud.txt` (Para servicios cloud)
```txt
-r requirements-base.txt
openai==1.6.1
pinecone-client==2.2.4
anthropic==0.8.1
```

### `requirements-dev.txt` (Para desarrollo)
```txt
-r requirements-local.txt
pytest==7.4.3
black==23.11.0
flake8==6.1.0
```

## 📝 Instalación Según tu Necesidad

### **Método 1: Todo en uno (recomendado para desarrollo)**
```bash
pip install -r requirements.txt
```

### **Método 2: Modular**
```bash
# Solo lo básico + local
pip install -r requirements-local.txt

# Agregar cloud cuando necesites
pip install -r requirements-cloud.txt
```

### **Método 3: Selective Install**
```bash
# Crear tu propio requirements
cat > my-requirements.txt << EOF
-r requirements-base.txt
weaviate-client==3.25.3    # Tu vector DB
sentence-transformers==2.2.2  # Tus embeddings
openai==1.6.1             # Backup LLM
EOF

pip install -r my-requirements.txt
```

## 🔄 Actualización del Código para Soportar Cloud

### **Configuración Actualizada (`config.py`)**
```python
class LLMProvider(Enum):
    # Local
    DEEPSEEK_API = "deepseek_api"
    DEEPSEEK_DIRECT = "deepseek_direct"
    
    # Cloud (descomenta cuando necesites)
    # OPENAI = "openai"
    # ANTHROPIC = "anthropic"
    # COHERE = "cohere"

class VectorDBProvider(Enum):
    # Local  
    WEAVIATE = "weaviate"
    CHROMA = "chroma"
    
    # Cloud (descomenta cuando necesites)
    # PINECONE = "pinecone"
    # QDRANT = "qdrant"

@dataclass
class RAGConfig:
    # Providers
    llm_provider: LLMProvider = LLMProvider.DEEPSEEK_API
    vector_db_provider: VectorDBProvider = VectorDBProvider.WEAVIATE
    embedding_provider: EmbeddingProvider = EmbeddingProvider.SENTENCE_BERT
    
    # URLs locales
    weaviate_url: str = "http://localhost:8080"
    deepseek_api_url: str = "http://localhost:11004/api/llm/rag-query"
    
    # API Keys cloud (opcional)
    openai_api_key: Optional[str] = None
    pinecone_api_key: Optional[str] = None
    anthropic_api_key: Optional[str] = None
```

## 🎛️ Variables de Entorno Flexibles

### `.env` actualizado
```bash
# =============================================================================
# CONFIGURACIÓN FLEXIBLE - Banking RAG System
# =============================================================================

# Providers activos
LLM_PROVIDER=deepseek_api              # deepseek_api, deepseek_direct, openai
VECTOR_DB_PROVIDER=weaviate            # weaviate, chroma, pinecone
EMBEDDING_PROVIDER=sentence_bert       # sentence_bert, openai

# Local URLs
WEAVIATE_URL=http://localhost:8080
DEEPSEEK_API_URL=http://localhost:11004/api/llm/rag-query
DEEPSEEK_DIRECT_URL=http://localhost:11434

# Cloud API Keys (opcional - solo llenar si usas)
OPENAI_API_KEY=
PINECONE_API_KEY=
ANTHROPIC_API_KEY=
COHERE_API_KEY=

# Configuración general
RAG_TEMPERATURE=0.2
RAG_CHUNK_SIZE=1000
RAG_MAX_TOKENS=2000
```

## 📊 Ventajas de esta Estructura

### ✅ **Flexibilidad Total**
- Puedes empezar 100% local
- Agregar cloud incrementalmente
- Cambiar providers sin reescribir código

### ✅ **Gestión de Costos**
- Local = $0 después de setup inicial
- Cloud = Solo pagas lo que usas

### ✅ **Escalabilidad**
- Local para desarrollo/testing
- Cloud para producción/volumen alto

### ✅ **Redundancia**
- Si tu API local falla → automáticamente usa cloud
- Múltiples providers como backup

## 🚨 Recomendaciones de Seguridad

### **Para Producción**
```bash
# Nunca commites API keys
echo "*.env" >> .gitignore
echo ".env.local" >> .gitignore
echo ".env.production" >> .gitignore

# Usa archivos separados por ambiente
.env.development     # Local only
.env.staging        # Local + some cloud
.env.production     # Full cloud
```

### **Verificación de Configuración**
```python
# Agregar al inicio de tu app
def verify_config(config: RAGConfig):
    if config.llm_provider == LLMProvider.OPENAI and not config.openai_api_key:
        raise ValueError("OpenAI API key requerida para provider OpenAI")
    
    if config.vector_db_provider == VectorDBProvider.PINECONE and not config.pinecone_api_key:
        raise ValueError("Pinecone API key requerida para provider Pinecone")
```

## 🏁 Próximos Pasos

1. **Ahora:** Usa la configuración local completa
2. **Más tarde:** Descomenta solo lo que necesites
3. **Producción:** Evalúa qué partes migrar a cloud según volumen/costo

¿Te parece bien esta estructura flexible?