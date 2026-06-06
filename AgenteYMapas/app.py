import os
import json
from dotenv import load_dotenv

load_dotenv()
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel
from typing import List, Optional
from autogen import AssistantAgent, UserProxyAgent, register_function

app = FastAPI(title="DurangoGuía IA - Agente de Turismo de Durango")

# Habilitar CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Datos curados simplificados para Durango, México (ahorro de tokens)
DURANGO_DATA = {
    "turismo": (
        "• Centro Histórico y Catedral Basílica Menor (arquitectura y leyendas).\n"
        "• Teleférico de Durango (vistas al Cerro de los Remedios).\n"
        "• Paseo del Viejo Oeste (set de vaqueros con shows en vivo).\n"
        "• Túnel de Minería (museo subterráneo).\n"
        "• Museo Francisco Villa (historia de Pancho Villa)."
    ),
    "gastronomia": (
        "• Caldillo Duranguense (guisado tradicional de res con chile pasado).\n"
        "• Chile Pasado (chile verde asado y seco local, en guisados o con queso).\n"
        "• Gorditas de maíz rellenas (como las de Gorditas Gabino o Coronado).\n"
        "• Queso Menonita local y Mezcal artesanal Cenizo."
    ),
    "artesanias": (
        "• Llaveros, jewelry y dulces con Alacranes encapsulados (en Mercado Gómez Palacio).\n"
        "• Casa del Artesano (arte Wixárika/Huichol y textiles Tepehuanes).\n"
        "• Talabartería tradicional (botas, sombreros y cuero)."
    ),
    "ocio": (
        "• Paseo peatonal de la Constitución (cafés y mezcalerías).\n"
        "• Parques Guadiana y Sahuatoba (lagos y zoológico en la ciudad).\n"
        "• Mexiquillo (cascadas y formaciones rocosas en la sierra)."
    )
}

# Lugares con coordenadas GPS reales de Durango, México
DURANGO_PLACES = {
    "gastronomia": [
        {"id": "gorditas_gabino",   "title": "Gorditas Gabino",        "description": "Las mejores gorditas de maíz rellenas de la ciudad",       "lat": 24.0281, "lng": -104.6532},
        {"id": "caldillo_don_beto", "title": "Caldillo Don Beto",      "description": "Caldillo Duranguense tradicional y chile pasado auténtico", "lat": 24.0265, "lng": -104.6518},
        {"id": "gorditas_coronado", "title": "Gorditas Coronado",      "description": "Gorditas rellenas y aguas frescas en el centro histórico",  "lat": 24.0270, "lng": -104.6525},
        {"id": "mezcaleria_cenizo", "title": "Mezcalería El Cenizo",   "description": "Mezcal artesanal Cenizo y botanas duranguenses",            "lat": 24.0268, "lng": -104.6527},
    ],
    "turismo": [
        {"id": "catedral",    "title": "Catedral Basílica Menor",  "description": "Joya del barroco novohispano del siglo XVII",              "lat": 24.0271, "lng": -104.6524},
        {"id": "teleferico",  "title": "Teleférico de Durango",    "description": "Vistas panorámicas al Cerro de los Remedios",             "lat": 24.0289, "lng": -104.6669},
        {"id": "tunel",       "title": "Túnel de Minería",         "description": "Museo subterráneo en antiguas minas coloniales",          "lat": 24.0272, "lng": -104.6533},
        {"id": "museo_villa", "title": "Museo Francisco Villa",    "description": "Historia del Centauro del Norte, Pancho Villa",           "lat": 24.0262, "lng": -104.6509},
        {"id": "viejo_oeste", "title": "Paseo del Viejo Oeste",    "description": "Set de películas western con shows en vivo",              "lat": 24.1056, "lng": -104.8095},
    ],
    "artesanias": [
        {"id": "casa_artesano", "title": "Casa del Artesano",          "description": "Arte Huichol, textiles Tepehuanes y artesanías locales",  "lat": 24.0259, "lng": -104.6521},
        {"id": "mercado_gomez", "title": "Mercado Gómez Palacio",      "description": "Alacranes encapsulados y souvenirs típicos de Durango",   "lat": 24.0278, "lng": -104.6505},
        {"id": "talabarteria",  "title": "Taller de Talabartería",     "description": "Botas, sombreros y artículos de cuero artesanal",         "lat": 24.0255, "lng": -104.6490},
    ],
    "ocio": [
        {"id": "paseo_constitucion", "title": "Paseo de la Constitución", "description": "Andador peatonal con cafés y mezcalerías",            "lat": 24.0269, "lng": -104.6521},
        {"id": "parque_guadiana",    "title": "Parque Guadiana",          "description": "Lago artificial, jardines y zoológico urbano",         "lat": 24.0219, "lng": -104.6620},
        {"id": "mexiquillo",         "title": "Mexiquillo",               "description": "Cascadas y formaciones rocosas en la Sierra Madre",    "lat": 23.9544, "lng": -105.3950},
        {"id": "parque_sahuatoba",   "title": "Parque Sahuatoba",         "description": "Zona recreativa familiar con lago artificial",         "lat": 24.0312, "lng": -104.6411},
    ],
}

def get_place_recommendations(category: str) -> str:
    """
    Devuelve exactamente 3 lugares recomendados de Durango, México con coordenadas GPS como JSON.
    Llama a esta herramienta en cuanto sepas qué categoría busca el usuario.

    Args:
        category (str): Una de 'gastronomia', 'turismo', 'artesanias', 'ocio'.

    Returns:
        str: JSON con lista de 3 lugares (id, title, description, lat, lng).
    """
    cat = category.lower().strip()
    if "gast" in cat or "com" in cat or "rest" in cat or "plat" in cat or "comer" in cat or "comi" in cat:
        places = DURANGO_PLACES["gastronomia"][:3]
    elif "tur" in cat or "museo" in cat or "hist" in cat or "visitar" in cat or "atract" in cat:
        places = DURANGO_PLACES["turismo"][:3]
    elif "art" in cat or "comp" in cat or "merc" in cat or "sou" in cat or "recuer" in cat:
        places = DURANGO_PLACES["artesanias"][:3]
    elif "oci" in cat or "act" in cat or "nat" in cat or "sier" in cat or "park" in cat or "parq" in cat or "diver" in cat:
        places = DURANGO_PLACES["ocio"][:3]
    else:
        places = DURANGO_PLACES["turismo"][:3]
    return json.dumps({"places": places}, ensure_ascii=False)


def get_durango_recommendations(category: str) -> str:
    """
    Obtiene recomendaciones locales curadas de Durango, México, según la categoría proporcionada.
    
    Args:
        category (str): Categoría solicitada. Debe ser una de: 'turismo', 'gastronomia', 'artesanias', 'ocio'.
        
    Returns:
        str: Las recomendaciones detalladas de la categoría seleccionada.
    """
    cat = category.lower().strip()
    if "tur" in cat:
        return DURANGO_DATA["turismo"]
    elif "gast" in cat or "com" in cat or "rest" in cat or "plat" in cat:
        return DURANGO_DATA["gastronomia"]
    elif "art" in cat or "comp" in cat or "neg" in cat or "merc" in cat:
        return DURANGO_DATA["artesanias"]
    elif "oci" in cat or "act" in cat or "diver" in cat or "nat" in cat or "sier" in cat:
        return DURANGO_DATA["ocio"]
    else:
        return (
            "Categoría no identificada en la base de datos curada. Las categorías válidas son:\n"
            "- 'turismo' (para lugares de interés, templos y museos)\n"
            "- 'gastronomia' (para comida típica, restaurantes y bebidas locales)\n"
            "- 'artesanias' (para mercados, alacranes encapsulados y artesanías indígenas)\n"
            "- 'ocio' (para paseos peatonales, parques urbanos y naturaleza en la sierra).\n"
            "\nSin embargo, puedes intentar responder con tu conocimiento general sobre la hermosa ciudad de Durango."
        )

# Modelos Pydantic para la API
class ChatMessage(BaseModel):
    role: str
    content: str

class ChatRequest(BaseModel):
    messages: List[ChatMessage]
    api_key: Optional[str] = None
    model_name: Optional[str] = "google/gemini-2.5-flash"

class RecommendRequest(BaseModel):
    message: str
    history: List[ChatMessage] = []

def resume_conversation(user_proxy: UserProxyAgent, assistant: AssistantAgent, history: List[ChatMessage]):
    """Reconstruye el historial de conversación en los agentes de AutoGen de forma bidireccional."""
    user_proxy.clear_history()
    assistant.clear_history()
    
    user_proxy._oai_messages[assistant] = []
    assistant._oai_messages[user_proxy] = []
    
    for msg in history:
        role = msg.role
        content = msg.content
        
        if role == "user":
            user_msg = {"role": "user", "content": content, "name": "usuario_proxy"}
            user_proxy._oai_messages[assistant].append(user_msg)
            assistant._oai_messages[user_proxy].append(user_msg)
        elif role == "assistant":
            ast_msg = {"role": "assistant", "content": content, "name": "durango_guia_asistente"}
            user_proxy._oai_messages[assistant].append(ast_msg)
            assistant._oai_messages[user_proxy].append(ast_msg)

DEFAULT_OPENROUTER_KEY = os.getenv("OPENROUTER_API_KEY", "")

@app.post("/api/chat")
async def chat_endpoint(request: ChatRequest):
    # Determinar qué API Key usar
    api_key = request.api_key or os.environ.get("OPENROUTER_API_KEY") or DEFAULT_OPENROUTER_KEY
    
    if not api_key:
        raise HTTPException(
            status_code=400,
            detail="Se requiere una API Key de OpenRouter. Por favor configúrala en la interfaz o define OPENROUTER_API_KEY en el servidor."
        )
        
    if not request.messages:
        raise HTTPException(status_code=400, detail="El historial de mensajes no puede estar vacío.")

    # El último mensaje es la consulta actual
    latest_message = request.messages[-1].content
    # El resto del historial
    history = request.messages[:-1]

    # Configuración de AutoGen para usar OpenRouter (compatible con OpenAI)
    config_list = [
        {
            "model": request.model_name or "google/gemini-2.5-flash",
            "base_url": "https://openrouter.ai/api/v1",
            "api_key": api_key.strip(),
            "api_type": "openai",
            "max_tokens": 120
        }
    ]

    try:
        # Inicializar el Asistente Especializado en Durango
        assistant = AssistantAgent(
            name="durango_guia_asistente",
            system_message=(
                "Eres un guía turístico de Durango, México de pocas palabras.\n"
                "\n"
                "REGLAS CRÍTICAS DE DIÁLOGO:\n"
                "1. Haz solo UNA pregunta breve a la vez para recabar información (tiempo de viaje, qué quiere hacer, con quién viaja).\n"
                "2. Si la conversación inicia o no tienes suficiente información, saluda brevemente y haz la primera pregunta. No acumules preguntas en un solo mensaje.\n"
                "3. Cuando el usuario responda, haz la siguiente pregunta o, si ya tienes suficiente información, dale recomendaciones muy sencillas, breves (máximo 2 opciones cortas).\n"
                "4. Usa la herramienta 'get_durango_recommendations' solo cuando sea estrictamente necesario y resume sus resultados en máximo 1 o 2 oraciones muy simples.\n"
                "5. Mantén tus respuestas en un límite estricto de menos de 40 palabras. Sé extremadamente directo y amigable."
            ),
            llm_config={
                "config_list": config_list,
                "temperature": 0.5,
                "max_tokens": 120,
            },
        )

        # Función para detectar cuándo terminar el chat y evitar loops infinitos
        def check_termination(message):
            if isinstance(message, dict):
                # Si el mensaje tiene contenido y no contiene llamadas a herramientas, terminamos
                return message.get("content") is not None and not message.get("tool_calls")
            return True

        # Inicializar el Proxy de Usuario
        user_proxy = UserProxyAgent(
            name="usuario_proxy",
            human_input_mode="NEVER",
            code_execution_config=False,
            is_termination_msg=check_termination,
            max_consecutive_auto_reply=3, # Límite para evitar loops infinitos en caso de que falle la terminación
        )

        # Registrar la herramienta
        register_function(
            get_durango_recommendations,
            caller=assistant,
            executor=user_proxy,
            name="get_durango_recommendations",
            description="Obtiene recomendaciones locales curadas de Durango, México para turismo, gastronomía, artesanías u ocio.",
        )

        # Reconstruir la conversación previa en los agentes
        if history:
            resume_conversation(user_proxy, assistant, history)

        # Iniciar la conversación para este turno
        chat_result = user_proxy.initiate_chat(
            assistant,
            message=latest_message,
            clear_history=False,
        )

        # Buscar la respuesta del asistente. La última respuesta en la conversación será el texto final generado por el asistente.
        # Filtramos para asegurarnos de que la última respuesta de texto sea del asistente.
        reply_content = ""
        for msg in reversed(chat_result.chat_history):
            if msg.get("role") == "user" and msg.get("name") == "durango_guia_asistente":
                # Nota: En el historial de initiate_chat, las respuestas del asistente pueden guardarse bajo el rol 'user'
                # con el nombre del asistente si son enviadas de vuelta al proxy de usuario.
                reply_content = msg.get("content") or ""
                if reply_content.strip():
                    break
            elif msg.get("role") == "assistant" and msg.get("content"):
                reply_content = msg.get("content")
                if reply_content.strip():
                    break

        if not reply_content:
            # Fallback en caso de que el formato del historial varíe
            reply_content = chat_result.chat_history[-1].get("content") or "Lo siento, no pude procesar una respuesta."

        return {"reply": reply_content}

    except Exception as e:
        import traceback
        error_details = traceback.format_exc()
        print(f"Error en el endpoint de chat:\n{error_details}")
        raise HTTPException(
            status_code=500,
            detail=f"Error al procesar la respuesta con AutoGen: {str(e)}"
        )

@app.post("/api/recommend")
async def recommend_endpoint(request: RecommendRequest):
    """
    Endpoint para la app Flutter: el agente pregunta qué quiere el usuario,
    y cuando tiene suficiente contexto llama get_place_recommendations()
    y devuelve 3 lugares con coordenadas GPS.
    """
    config_list = [
        {
            "model": "google/gemini-2.5-flash",
            "base_url": "https://openrouter.ai/api/v1",
            "api_key": DEFAULT_OPENROUTER_KEY,
            "api_type": "openai",
            "max_tokens": 150,
        }
    ]

    assistant = AssistantAgent(
        name="durango_guide",
        system_message=(
            "Eres un guía turístico de Durango, México. Sé muy breve y amigable.\n"
            "REGLAS:\n"
            "1. Si no sabes qué busca el usuario, haz UNA sola pregunta corta "
            "(ej: '¿Qué prefieres: gastronomía, turismo, artesanías o actividades al aire libre?').\n"
            "2. En cuanto el usuario mencione una preferencia o categoría, "
            "llama INMEDIATAMENTE a `get_place_recommendations` con la categoría correcta. "
            "No hagas más preguntas si ya tienes la categoría.\n"
            "3. Después de recibir el resultado de la herramienta, responde SOLO con: "
            "'¡Aquí tienes 3 opciones cerca de ti! Elige la que más te guste.' "
            "No repitas la lista; las tarjetas se mostrarán automáticamente en el mapa."
        ),
        llm_config={
            "config_list": config_list,
            "temperature": 0.2,
            "max_tokens": 150,
        },
    )

    def check_termination(message):
        if isinstance(message, dict):
            return message.get("content") is not None and not message.get("tool_calls")
        return True

    user_proxy = UserProxyAgent(
        name="user_proxy",
        human_input_mode="NEVER",
        code_execution_config=False,
        is_termination_msg=check_termination,
        max_consecutive_auto_reply=3,
    )

    register_function(
        get_place_recommendations,
        caller=assistant,
        executor=user_proxy,
        name="get_place_recommendations",
        description="Devuelve 3 lugares de Durango con coordenadas GPS para la categoría dada.",
    )

    # Reconstruir historial previo
    if request.history:
        user_proxy.clear_history()
        assistant.clear_history()
        user_proxy._oai_messages[assistant] = []
        assistant._oai_messages[user_proxy] = []
        for msg in request.history:
            entry = {"role": msg.role, "content": msg.content}
            user_proxy._oai_messages[assistant].append(entry)
            assistant._oai_messages[user_proxy].append(entry)

    try:
        chat_result = user_proxy.initiate_chat(
            assistant,
            message=request.message,
            clear_history=False,
        )
    except Exception as e:
        import traceback
        print(traceback.format_exc())
        raise HTTPException(status_code=500, detail=str(e))

    # Extraer texto de respuesta y lugares si el agente llamó la herramienta
    reply_text = ""
    places = None

    for msg in reversed(chat_result.chat_history):
        content = msg.get("content")
        if not content or not isinstance(content, str):
            continue

        # Detectar resultado de la herramienta (JSON con "places")
        if places is None:
            try:
                parsed = json.loads(content)
                if isinstance(parsed, dict) and "places" in parsed:
                    places = parsed["places"]
                    continue  # no usar este mensaje como reply_text
            except (json.JSONDecodeError, TypeError):
                pass

        # Tomar el último texto del asistente que no sea una tool call ni tool result
        if not reply_text and not msg.get("tool_calls"):
            stripped = content.strip()
            if stripped:
                reply_text = stripped

    if places:
        return {
            "type": "recommendations",
            "text": reply_text or "¡Aquí tienes 3 opciones cerca de ti!",
            "places": places,
        }
    return {
        "type": "message",
        "text": reply_text or "¿Qué tipo de lugar te gustaría visitar en Durango?",
    }


# Servir archivos estáticos del frontend
app.mount("/", StaticFiles(directory="static", html=True), name="static")

if __name__ == "__main__":
    import uvicorn
    # Ejecutar el servidor en el puerto 8000
    uvicorn.run("app:app", host="0.0.0.0", port=8000, reload=True)
