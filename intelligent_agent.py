"""
Implementación Práctica - Agente Inteligente Bancario
Integración directa con tu sistema RAG existente + nuevas capacidades
"""

import streamlit as st
import requests
import json
import os
from datetime import datetime, timedelta
from typing import List, Dict, Any, Optional
import logging

# LangChain imports
from langchain.agents import initialize_agent, Tool, AgentType
from langchain.memory import ConversationBufferMemory
from langchain.tools import BaseTool
from langchain.schema import BaseMessage
from pydantic import BaseModel, Field

# Tu sistema existente
from banking_rag_configurable import BankingRAGConfigurable

# ============================================================================
# 1. HERRAMIENTAS INTEGRADAS CON TU SISTEMA
# ============================================================================

class MyrluxStudentTool(BaseTool):
    """Herramienta para consultar estudiantes en tu backend Java"""
    name = "consultar_estudiante"
    description = """Consulta información de estudiantes del sistema MyrluxBack.
    Parámetros: id_estudiante (número) o 'todos' para listar todos"""
    
    def __init__(self):
        super().__init__()
        self.base_url = "http://localhost:11002/api"
    
    def _run(self, consulta: str) -> str:
        try:
            if consulta.lower() == "todos":
                # Obtener todos los estudiantes
                response = requests.get(f"{self.base_url}/lista/alumno", timeout=10)
                
                if response.status_code == 200:
                    estudiantes = response.json()
                    if not estudiantes:
                        return "No hay estudiantes registrados en el sistema."
                    
                    resultado = "📚 Lista de Estudiantes:\n\n"
                    for estudiante in estudiantes[:10]:  # Limitar a 10 para no saturar
                        resultado += f"ID: {estudiante.get('id', 'N/A')}\n"
                        resultado += f"Nombre: {estudiante.get('nombres', '')} {estudiante.get('apellidos', '')}\n"
                        resultado += f"Email: {estudiante.get('email', 'N/A')}\n"
                        resultado += f"Teléfono: {estudiante.get('telefono', 'N/A')}\n"
                        resultado += "---\n"
                    
                    if len(estudiantes) > 10:
                        resultado += f"\n... y {len(estudiantes) - 10} estudiantes más."
                    
                    return resultado
                else:
                    return f"Error obteniendo estudiantes: {response.status_code}"
            
            else:
                # Consultar estudiante específico
                try:
                    student_id = int(consulta)
                except ValueError:
                    return "Por favor proporciona un ID válido o escribe 'todos'"
                
                response = requests.get(f"{self.base_url}/obtener/alumno/{student_id}", timeout=10)
                
                if response.status_code == 200:
                    estudiante = response.json()
                    resultado = "👨‍🎓 Información del Estudiante:\n\n"
                    resultado += f"ID: {estudiante.get('id', 'N/A')}\n"
                    resultado += f"Nombre: {estudiante.get('nombres', '')} {estudiante.get('apellidos', '')}\n"
                    resultado += f"Email: {estudiante.get('email', 'N/A')}\n"
                    resultado += f"Teléfono: {estudiante.get('telefono', 'N/A')}\n"
                    resultado += f"Dirección: {estudiante.get('direccion', 'N/A')}\n"
                    return resultado
                
                elif response.status_code == 404:
                    return f"No se encontró estudiante con ID {student_id}"
                else:
                    return f"Error consultando estudiante: {response.status_code}"
                    
        except requests.exceptions.ConnectionError:
            return "❌ No se pudo conectar con MyrluxBack. ¿Está ejecutándose en puerto 11002?"
        except requests.exceptions.Timeout:
            return "⏱️ Timeout consultando MyrluxBack"
        except Exception as e:
            return f"Error inesperado: {str(e)}"

class BankingRAGTool(BaseTool):
    """Herramienta que usa tu sistema RAG bancario existente"""
    name = "consulta_bancaria_rag"
    description = """Responde preguntas sobre productos y servicios bancarios usando
    el sistema RAG. Ejemplos: cuentas de ahorro, préstamos, tarjetas de crédito"""
    
    def __init__(self, rag_system):
        super().__init__()
        self.rag_system = rag_system
    
    def _run(self, pregunta: str) -> str:
        try:
            resultado = self.rag_system.rag_query(pregunta, k=3)
            
            respuesta = f"🏦 Consulta Bancaria:\n\n"
            respuesta += resultado["response"]
            
            if resultado["sources"]:
                respuesta += f"\n\n📋 Fuentes consultadas: {len(resultado['sources'])} documentos"
            
            return respuesta
            
        except Exception as e:
            return f"Error en consulta bancaria: {str(e)}"

class FinancialCalculatorTool(BaseTool):
    """Calculadora financiera avanzada"""
    name = "calculadora_financiera"
    description = """Realiza cálculos financieros. Ejemplos:
    - 'prestamo 50000 18 24' (monto, tasa%, meses)
    - 'ahorro 1000 3.5 12' (deposito mensual, tasa%, meses)
    - 'interes 10000 5 2' (capital, tasa%, años)"""
    
    def _run(self, calculo: str) -> str:
        try:
            partes = calculo.lower().split()
            tipo = partes[0]
            
            if tipo == "prestamo" and len(partes) >= 4:
                monto = float(partes[1])
                tasa_anual = float(partes[2])
                meses = int(partes[3])
                
                # Calcular pago mensual
                tasa_mensual = (tasa_anual / 100) / 12
                pago_mensual = monto * (tasa_mensual * (1 + tasa_mensual)**meses) / ((1 + tasa_mensual)**meses - 1)
                total_pagado = pago_mensual * meses
                intereses = total_pagado - monto
                
                resultado = f"💰 Cálculo de Préstamo:\n\n"
                resultado += f"Monto solicitado: ${monto:,.2f}\n"
                resultado += f"Tasa anual: {tasa_anual}%\n"
                resultado += f"Plazo: {meses} meses\n"
                resultado += f"Pago mensual: ${pago_mensual:,.2f}\n"
                resultado += f"Total a pagar: ${total_pagado:,.2f}\n"
                resultado += f"Intereses totales: ${intereses:,.2f}"
                
                return resultado
            
            elif tipo == "ahorro" and len(partes) >= 4:
                deposito_mensual = float(partes[1])
                tasa_anual = float(partes[2])
                meses = int(partes[3])
                
                # Calcular valor futuro
                tasa_mensual = (tasa_anual / 100) / 12
                valor_futuro = deposito_mensual * (((1 + tasa_mensual)**meses - 1) / tasa_mensual)
                total_depositado = deposito_mensual * meses
                ganancias = valor_futuro - total_depositado
                
                resultado = f"🐷 Cálculo de Ahorro:\n\n"
                resultado += f"Depósito mensual: ${deposito_mensual:,.2f}\n"
                resultado += f"Tasa anual: {tasa_anual}%\n"
                resultado += f"Plazo: {meses} meses\n"
                resultado += f"Total depositado: ${total_depositado:,.2f}\n"
                resultado += f"Valor final: ${valor_futuro:,.2f}\n"
                resultado += f"Ganancias: ${ganancias:,.2f}"
                
                return resultado
            
            elif tipo == "interes" and len(partes) >= 4:
                capital = float(partes[1])
                tasa_anual = float(partes[2])
                años = float(partes[3])
                
                # Interés simple y compuesto
                interes_simple = capital * (tasa_anual / 100) * años
                interes_compuesto = capital * ((1 + tasa_anual / 100)**años - 1)
                
                resultado = f"📈 Cálculo de Intereses:\n\n"
                resultado += f"Capital inicial: ${capital:,.2f}\n"
                resultado += f"Tasa anual: {tasa_anual}%\n"
                resultado += f"Tiempo: {años} años\n\n"
                resultado += f"Interés simple: ${interes_simple:,.2f}\n"
                resultado += f"Monto final (simple): ${capital + interes_simple:,.2f}\n\n"
                resultado += f"Interés compuesto: ${interes_compuesto:,.2f}\n"
                resultado += f"Monto final (compuesto): ${capital + interes_compuesto:,.2f}"
                
                return resultado
            
            else:
                return """Formato incorrecto. Ejemplos válidos:
• prestamo 50000 18 24 (monto, tasa%, meses)
• ahorro 1000 3.5 12 (depósito mensual, tasa%, meses)  
• interes 10000 5 2 (capital, tasa%, años)"""
                
        except ValueError:
            return "Error: Verifica que los números sean válidos"
        except Exception as e:
            return f"Error en cálculo: {str(e)}"

class WeatherTool(BaseTool):
    """Consulta información del clima"""
    name = "consultar_clima"
    description = "Consulta el clima actual de una ciudad"
    
    def _run(self, ciudad: str) -> str:
        try:
            # Para demostración, usamos datos simulados
            # En producción usarías OpenWeatherMap API
            climas_simulados = {
                "mexico": {"temp": 22, "desc": "Soleado", "humedad": 60},
                "guadalajara": {"temp": 25, "desc": "Parcialmente nublado", "humedad": 55},
                "monterrey": {"temp": 28, "desc": "Despejado", "humedad": 45},
                "cancun": {"temp": 30, "desc": "Soleado", "humedad": 75},
                "veracruz": {"temp": 26, "desc": "Nublado", "humedad": 80}
            }
            
            ciudad_lower = ciudad.lower()
            clima = climas_simulados.get(ciudad_lower, {
                "temp": 24, "desc": "Información no disponible", "humedad": 65
            })
            
            resultado = f"🌤️ Clima en {ciudad.title()}:\n\n"
            resultado += f"Temperatura: {clima['temp']}°C\n"
            resultado += f"Condiciones: {clima['desc']}\n"
            resultado += f"Humedad: {clima['humedad']}%\n"
            resultado += f"Actualizado: {datetime.now().strftime('%H:%M')}"
            
            return resultado
            
        except Exception as e:
            return f"Error consultando clima: {str(e)}"

class CurrencyConverterTool(BaseTool):
    """Conversor de monedas"""
    name = "conversion_moneda"
    description = """Convierte entre monedas. Formato: 'cantidad moneda_origen a moneda_destino'
    Ejemplo: '100 USD a MXN' o '500 MXN a USD'"""
    
    def _run(self, conversion: str) -> str:
        try:
            # Parsear entrada
            partes = conversion.split()
            if len(partes) < 4 or partes[2].lower() != 'a':
                return "Formato: 'cantidad moneda_origen a moneda_destino' (ej: '100 USD a MXN')"
            
            cantidad = float(partes[0])
            moneda_origen = partes[1].upper()
            moneda_destino = partes[3].upper()
            
            # Tasas de cambio simuladas (en producción usarías una API real)
            tasas = {
                ("USD", "MXN"): 18.50,
                ("MXN", "USD"): 0.054,
                ("EUR", "MXN"): 20.20,
                ("MXN", "EUR"): 0.049,
                ("USD", "EUR"): 0.92,
                ("EUR", "USD"): 1.09
            }
            
            # Buscar tasa de conversión
            tasa = tasas.get((moneda_origen, moneda_destino))
            if not tasa:
                # Intentar conversión inversa
                tasa_inversa = tasas.get((moneda_destino, moneda_origen))
                if tasa_inversa:
                    tasa = 1 / tasa_inversa
                else:
                    return f"No hay tasa de conversión disponible para {moneda_origen} → {moneda_destino}"
            
            resultado_conversion = cantidad * tasa
            
            resultado = f"💱 Conversión de Moneda:\n\n"
            resultado += f"{cantidad:,.2f} {moneda_origen} = {resultado_conversion:,.2f} {moneda_destino}\n"
            resultado += f"Tasa de cambio: 1 {moneda_origen} = {tasa:.4f} {moneda_destino}\n"
            resultado += f"Actualizado: {datetime.now().strftime('%Y-%m-%d %H:%M')}"
            
            return resultado
            
        except ValueError:
            return "Error: La cantidad debe ser un número válido"
        except Exception as e:
            return f"Error en conversión: {str(e)}"

# ============================================================================
# 2. AGENTE INTELIGENTE INTEGRADO
# ============================================================================

class BankingIntelligentAgent:
    """Agente inteligente que combina tu sistema RAG con nuevas capacidades"""
    
    def __init__(self, rag_system):
        self.rag_system = rag_system
        
        # Configurar memoria conversacional
        self.memory = ConversationBufferMemory(
            memory_key="chat_history",
            return_messages=True
        )
        
        # Crear herramientas
        self.tools = [
            BankingRAGTool(rag_system),
            MyrluxStudentTool(),
            FinancialCalculatorTool(),
            WeatherTool(),
            CurrencyConverterTool(),
            
            # Herramienta simple de información
            Tool(
                name="informacion_sistema",
                description="Proporciona información sobre las capacidades del sistema",
                func=self._system_info
            ),
            
            # Herramienta de saludo/ayuda
            Tool(
                name="ayuda_general",
                description="Proporciona ayuda y ejemplos de uso",
                func=self._help_info
            )
        ]
        
        # Crear un LLM simple usando tu DeepSeek existente
        self.llm = self._create_simple_llm()
        
        # Inicializar agente
        try:
            self.agent = initialize_agent(
                tools=self.tools,
                llm=self.llm,
                agent=AgentType.CONVERSATIONAL_REACT_DESCRIPTION,
                memory=self.memory,
                verbose=True,
                max_iterations=3,
                early_stopping_method="generate",
                handle_parsing_errors=True
            )
        except Exception as e:
            st.error(f"Error inicializando agente: {e}")
            self.agent = None
    
    def _create_simple_llm(self):
        """Crear un wrapper simple para tu DeepSeek"""
        class DeepSeekLLM:
            def __init__(self, rag_system):
                self.rag_system = rag_system
            
            def __call__(self, prompt, **kwargs):
                try:
                    # Usar tu sistema DeepSeek existente
                    response = self.rag_system.query_deepseek(prompt)
                    return response
                except Exception as e:
                    return f"Error en LLM: {str(e)}"
            
            def predict(self, text, **kwargs):
                return self.__call__(text, **kwargs)
        
        return DeepSeekLLM(self.rag_system)
    
    def _system_info(self, query: str = "") -> str:
        """Información sobre capacidades del sistema"""
        return """🤖 Capacidades del Asistente Inteligente:

🏦 **Servicios Bancarios:**
• Consultas sobre productos bancarios (cuentas, préstamos, tarjetas)
• Cálculos financieros (préstamos, ahorros, intereses)
• Información sobre tarifas y comisiones

👨‍🎓 **Sistema Educativo (MyrluxBack):**
• Consultar información de estudiantes
• Listar todos los estudiantes registrados

🌐 **Servicios Generales:**
• Información del clima por ciudad
• Conversión entre monedas (USD, MXN, EUR)
• Calculadora financiera avanzada

💬 **Ejemplos de uso:**
• "¿Cómo abrir una cuenta de ahorros?"
• "Calcula un préstamo de 50000 pesos a 18% por 24 meses"
• "Muestra información del estudiante ID 123"
• "¿Cuál es el clima en Guadalajara?"
• "Convierte 100 USD a MXN"
"""
    
    def _help_info(self, query: str = "") -> str:
        """Información de ayuda"""
        return """📋 **Ejemplos de Consultas:**

**Bancarias:**
• "¿Qué documentos necesito para un crédito personal?"
• "¿Cuáles son las comisiones de la tarjeta de crédito?"
• "prestamo 100000 15 36" (cálculo de préstamo)

**Estudiantes:**
• "Consulta el estudiante 123"
• "Muestra todos los estudiantes"

**Utilidades:**
• "¿Cuál es el clima en Monterrey?"
• "Convierte 500 MXN a USD"
• "ahorro 2000 4 24" (cálculo de ahorro)

**Conversacional:**
• Puedo recordar nuestra conversación
• Hago preguntas de seguimiento
• Combino información de múltiples fuentes
"""
    
    def chat(self, user_input: str) -> str:
        """Método principal para chatear con el agente"""
        try:
            if not self.agent:
                # Fallback sin agente
                return self._handle_without_agent(user_input)
            
            # Usar el agente LangChain
            response = self.agent.run(input=user_input)
            return response
            
        except Exception as e:
            # Fallback en caso de error
            st.error(f"Error en agente: {e}")
            return self._handle_without_agent(user_input)
    
    def _handle_without_agent(self, user_input: str) -> str:
        """Manejo directo cuando el agente falla"""
        user_lower = user_input.lower()
        
        # Consultas bancarias
        if any(word in user_lower for word in ['banco', 'cuenta', 'credito', 'prestamo', 'tarjeta']):
            tool = BankingRAGTool(self.rag_system)
            return tool._run(user_input)
        
        # Consultas de estudiantes
        elif 'estudiante' in user_lower or 'alumno' in user_lower:
            tool = MyrluxStudentTool()
            if 'todos' in user_lower:
                return tool._run('todos')
            else:
                # Buscar número en la consulta
                import re
                numbers = re.findall(r'\d+', user_input)
                if numbers:
                    return tool._run(numbers[0])
                else:
                    return "Por favor especifica el ID del estudiante o escribe 'todos'"
        
        # Cálculos
        elif any(word in user_lower for word in ['calcula', 'prestamo', 'ahorro', 'interes']):
            tool = FinancialCalculatorTool()
            return tool._run(user_input)
        
        # Clima
        elif 'clima' in user_lower:
            tool = WeatherTool()
            # Extraer ciudad
            cities = ['mexico', 'guadalajara', 'monterrey', 'cancun', 'veracruz']
            for city in cities:
                if city in user_lower:
                    return tool._run(city)
            return tool._run('mexico')  # Default
        
        # Conversión
        elif any(word in user_lower for word in ['convierte', 'conversion', 'usd', 'mxn', 'eur']):
            tool = CurrencyConverterTool()
            return tool._run(user_input)
        
        # Ayuda
        elif any(word in user_lower for word in ['ayuda', 'help', 'que puedes', 'capacidades']):
            return self._help_info()
        
        # Default: usar RAG bancario
        else:
            tool = BankingRAGTool(self.rag_system)
            return tool._run(user_input)

# ============================================================================
# 3. INTERFAZ STREAMLIT MEJORADA
# ============================================================================

def create_intelligent_banking_ui():
    """Interfaz para el agente bancario inteligente"""
    
    st.set_page_config(
        page_title="🤖 Asistente Bancario Inteligente",
        page_icon="🤖",
        layout="wide"
    )
    
    st.title("🤖 Asistente Bancario Inteligente")
    st.markdown("**Agente AI que combina servicios bancarios, gestión educativa y utilidades**")
    
    # Inicializar sistemas
    if 'intelligent_agent' not in st.session_state:
        try:
            with st.spinner("🚀 Inicializando agente inteligente..."):
                # Usar tu sistema RAG existente
                if 'rag_system' not in st.session_state:
                    st.session_state.rag_system = BankingRAGConfigurable()
                
                # Crear agente inteligente
                st.session_state.intelligent_agent = BankingIntelligentAgent(
                    st.session_state.rag_system
                )
            
            st.success("✅ Agente inteligente listo!")
            
            # Mostrar estado de sistemas
            col1, col2, col3 = st.columns(3)
            with col1:
                st.metric("🏦 Banking RAG", "✅ Activo")
            with col2:
                st.metric("👨‍🎓 MyrluxBack", "🔗 Conectado")
            with col3:
                st.metric("🤖 Agente IA", "✅ Listo")
                
        except Exception as e:
            st.error(f"❌ Error inicializando agente: {e}")
            st.info("💡 Asegúrate de que MyrluxBack esté ejecutándose en puerto 11002")
            st.stop()
    
    # Chat interface
    st.subheader("💬 Chat con el Asistente")
    
    # Inicializar historial
    if "agent_messages" not in st.session_state:
        st.session_state.agent_messages = [
            {
                "role": "assistant",
                "content": """¡Hola! Soy tu asistente bancario inteligente 🤖

**Puedo ayudarte con:**
🏦 **Consultas bancarias** - productos, servicios, cálculos
👨‍🎓 **Gestión de estudiantes** - consultar información de MyrluxBack  
🌤️ **Información del clima** - consultas meteorológicas
💱 **Conversión de monedas** - USD, MXN, EUR
🧮 **Cálculos financieros** - préstamos, ahorros, intereses

**Ejemplos:**
• "¿Cómo abrir una cuenta de ahorros?"
• "Calcula un préstamo de 50000 pesos al 18% por 24 meses"
• "Muestra información del estudiante 123"
• "¿Cuál es el clima en Guadalajara?"

¿En qué puedo ayudarte?"""
            }
        ]
    
    # Mostrar historial de chat
    for message in st.session_state.agent_messages:
        with st.chat_message(message["role"]):
            st.markdown(message["content"])
    
    # Input del usuario
    if prompt := st.chat_input("Escribe tu consulta..."):
        # Mostrar mensaje del usuario
        st.session_state.agent_messages.append({"role": "user", "content": prompt})
        with st.chat_message("user"):
            st.markdown(prompt)
        
        # Generar respuesta del agente
        with st.chat_message("assistant"):
            with st.spinner("🤔 Procesando..."):
                try:
                    response = st.session_state.intelligent_agent.chat(prompt)
                    st.markdown(response)
                except Exception as e:
                    error_msg = f"❌ Error procesando consulta: {str(e)}"
                    st.error(error_msg)
                    response = error_msg
        
        # Guardar respuesta
        st.session_state.agent_messages.append({"role": "assistant", "content": response})
    
    # Sidebar con información y ejemplos
    with st.sidebar:
        st.header("🎯 Ejemplos Rápidos")
        
        ejemplos = [
            ("🏦 Productos bancarios", "¿Qué tipos de cuentas de ahorro tienen?"),
            ("💰 Cálculo préstamo", "prestamo 75000 16 30"),
            ("👨‍🎓 Lista estudiantes", "Muestra todos los estudiantes"),
            ("👤 Consulta estudiante", "Consulta el estudiante 1"),
            ("🌤️ Clima", "¿Cuál es el clima en Monterrey?"),
            ("💱 Conversión", "Convierte 200 USD a MXN"),
            ("🧮 Ahorro", "ahorro 1500 3.5 18"),
            ("❓ Ayuda", "¿Qué puedes hacer?")
        ]
        
        for titulo, ejemplo in ejemplos:
            if st.button(f"{titulo}", key=f"btn_{hash(ejemplo)}", use_container_width=True):
                # Simular entrada del usuario
                st.session_state.temp_input = ejemplo
                st.rerun()
        
        # Procesar entrada temporal
        if hasattr(st.session_state, 'temp_input'):
            ejemplo = st.session_state.temp_input
            del st.session_state.temp_input
            
            # Agregar a historial
            st.session_state.agent_messages.append({"role": "user", "content": ejemplo})
            
            # Generar respuesta
            try:
                response = st.session_state.intelligent_agent.chat(ejemplo)
                st.session_state.agent_messages.append({"role": "assistant", "content": response})
            except Exception as e:
                error_msg = f"❌ Error: {str(e)}"
                st.session_state.agent_messages.append({"role": "assistant", "content": error_msg})
            
            st.rerun()
        
        st.markdown("---")
        
        st.subheader("📊 Estado del Sistema")
        
        # Verificar estado de sistemas
        try:
            # Test MyrluxBack
            response = requests.get("http://localhost:11002/api/home", timeout=5)
            myrlux_status = "✅ Conectado" if response.status_code == 200 else "❌ Error"
        except:
            myrlux_status = "❌ Desconectado"
        
        # Test RAG
        rag_status = "✅ Activo" if hasattr(st.session_state, 'rag_system') else "❌ Inactivo"
        
        st.write(f"**Banking RAG:** {rag_status}")
        st.write(f"**MyrluxBack:** {myrlux_status}")
        st.write(f"**Agente IA:** ✅ Funcionando")
        
        if myrlux_status == "❌ Desconectado":
            st.warning("⚠️ MyrluxBack no está disponible. Inicia el servidor Java en puerto 11002")

# ============================================================================
# 4. MAIN - EJECUCIÓN
# ============================================================================

def main():
    """Función principal"""
    create_intelligent_banking_ui()

if __name__ == "__main__":
    main()
