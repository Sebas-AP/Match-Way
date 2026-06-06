// DurangoGuía IA - Client Logic

document.addEventListener("DOMContentLoaded", () => {
    // DOM Elements
    const sidebar = document.getElementById("sidebar");
    const menuBtn = document.getElementById("menuBtn");
    const closeSidebarBtn = document.getElementById("closeSidebarBtn");
    const apiKeyInput = document.getElementById("apiKeyInput");
    const saveKeyBtn = document.getElementById("saveKeyBtn");
    const keyStatusText = document.getElementById("keyStatusText");
    const clearChatBtn = document.getElementById("clearChatBtn");
    const toggleThemeBtn = document.getElementById("toggleThemeBtn");
    const messagesContainer = document.getElementById("messagesContainer");
    const welcomeContainer = document.getElementById("welcomeContainer");
    const typingIndicator = document.getElementById("typingIndicator");
    const inputForm = document.getElementById("inputForm");
    const userInput = document.getElementById("userInput");
    const apiKeyWarning = document.getElementById("apiKeyWarning");

    // Chat State
    let chatHistory = []; // Array of { role: 'user'|'assistant', content: string }
    
    // Initialize API Key from localStorage
    const getStoredApiKey = () => localStorage.getItem("openrouter_api_key") || "";
    apiKeyInput.value = getStoredApiKey();
    updateKeyStatus();

    // Configure marked options for markdown rendering
    if (window.marked) {
        marked.setOptions({
            breaks: true,
            sanitize: false,
            smartypants: true
        });
    }

    // Toggle Mobile Sidebar
    menuBtn.addEventListener("click", () => {
        sidebar.classList.add("active");
    });

    closeSidebarBtn.addEventListener("click", () => {
        sidebar.classList.remove("active");
    });

    // Close sidebar on option click (mobile)
    document.querySelectorAll(".topic-btn").forEach(btn => {
        btn.addEventListener("click", () => {
            if (window.innerWidth <= 992) {
                sidebar.classList.remove("active");
            }
        });
    });

    // API Key Saving
    saveKeyBtn.addEventListener("click", () => {
        const key = apiKeyInput.value.trim();
        if (key) {
            localStorage.setItem("openrouter_api_key", key);
            showNotification("Clave API guardada con éxito", "success");
        } else {
            localStorage.removeItem("openrouter_api_key");
            showNotification("Usando clave por defecto del servidor", "info");
        }
        updateKeyStatus();
    });

    function updateKeyStatus() {
        const key = getStoredApiKey();
        if (key) {
            keyStatusText.innerHTML = 'Estado: Clave Personal <span style="color: var(--success)">🟢</span>';
            apiKeyWarning.innerHTML = '<i class="fa-solid fa-info-circle"></i> Usando tu clave API personal de OpenRouter.';
            apiKeyWarning.style.display = "block";
        } else {
            keyStatusText.innerHTML = 'Estado: Clave del Servidor <span style="color: var(--success)">🟢</span>';
            apiKeyWarning.innerHTML = '<i class="fa-solid fa-info-circle"></i> Usando la Clave API de OpenRouter por defecto del servidor.';
            apiKeyWarning.style.display = "block";
        }
    }

    // Theme Toggle (Dark / Light)
    toggleThemeBtn.addEventListener("click", () => {
        const currentTheme = document.documentElement.getAttribute("data-theme");
        if (currentTheme === "light") {
            document.documentElement.removeAttribute("data-theme");
            toggleThemeBtn.innerHTML = '<i class="fa-solid fa-moon"></i>';
            localStorage.setItem("theme", "dark");
        } else {
            document.documentElement.setAttribute("data-theme", "light");
            toggleThemeBtn.innerHTML = '<i class="fa-solid fa-sun"></i>';
            localStorage.setItem("theme", "light");
        }
    });

    // Initialize Theme
    const storedTheme = localStorage.getItem("theme");
    if (storedTheme === "light") {
        document.documentElement.setAttribute("data-theme", "light");
        toggleThemeBtn.innerHTML = '<i class="fa-solid fa-sun"></i>';
    }

    // Clear Chat
    clearChatBtn.addEventListener("click", () => {
        if (chatHistory.length === 0) return;
        
        if (confirm("¿Estás seguro de que deseas vaciar el historial del chat?")) {
            chatHistory = [];
            // Remove all message-row elements
            const messageRows = messagesContainer.querySelectorAll(".message-row");
            messageRows.forEach(row => row.remove());
            welcomeContainer.style.display = "flex";
            showNotification("Historial de chat limpiado", "info");
        }
    });

    // Handle Form Submit (Sending Message)
    inputForm.addEventListener("submit", (e) => {
        e.preventDefault();
        const text = userInput.value.trim();
        if (!text) return;
        
        sendMessage(text);
        userInput.value = "";
    });

    // Handle Quick Prompts
    document.addEventListener("click", (e) => {
        const target = e.target.closest(".suggested-prompt-btn, .topic-btn");
        if (target) {
            const prompt = target.getAttribute("data-prompt");
            if (prompt) {
                sendMessage(prompt);
            }
        }
    });

    // Send Message Logic
    async function sendMessage(text) {
        const apiKey = getStoredApiKey();
        // El servidor cuenta con una clave de OpenRouter por defecto, por lo que no es obligatorio ingresar una clave propia.

        // Hide welcome screen if showing
        welcomeContainer.style.display = "none";

        // 1. Add message to UI & history
        appendMessage("user", text);
        chatHistory.push({ role: "user", content: text });

        // 2. Show typing indicator
        showTyping(true);

        try {
            // 3. Request backend (resolve host dynamically if opened via file://)
            const host = window.location.protocol === "file:" ? "http://localhost:8000" : "";
            const response = await fetch(`${host}/api/chat`, {
                method: "POST",
                headers: {
                    "Content-Type": "application/json"
                },
                body: JSON.stringify({
                    messages: chatHistory,
                    api_key: apiKey
                })
            });

            const data = await response.json();

            // 4. Handle response
            showTyping(false);

            if (response.ok) {
                appendMessage("assistant", data.reply);
                chatHistory.push({ role: "assistant", content: data.reply });
            } else {
                const errMsg = data.detail || "Error desconocido en el servidor.";
                appendMessage("assistant", `❌ **Error del Sistema:** ${errMsg}\n\nPor favor, verifica que tu API Key sea correcta y que el servidor de FastAPI esté activo.`);
            }
        } catch (error) {
            showTyping(false);
            console.error("Fetch error:", error);
            appendMessage("assistant", "❌ **Error de Red:** No se pudo establecer conexión con el backend de FastAPI. Asegúrate de estar ejecutando `app.py` en tu terminal local.");
        }
    }

    // Helper: Append message row to DOM
    function appendMessage(role, content) {
        const messageRow = document.createElement("div");
        messageRow.classList.add("message-row", role);

        let avatarHtml = "";
        if (role === "assistant") {
            avatarHtml = `<div class="agent-bubble-avatar"><i class="fa-solid fa-scorpion">🦂</i></div>`;
        }

        let parsedContent = content;
        if (role === "assistant" && window.marked) {
            try {
                parsedContent = marked.parse(content);
            } catch (err) {
                console.error("Markdown parsing error:", err);
            }
        } else {
            // For user messages, simple text escaping to avoid XSS
            const div = document.createElement("div");
            div.textContent = content;
            parsedContent = `<p>${div.innerHTML}</p>`;
        }

        messageRow.innerHTML = `
            ${avatarHtml}
            <div class="message-bubble">
                ${parsedContent}
            </div>
        `;

        messagesContainer.appendChild(messageRow);
        
        // Auto-scroll to bottom
        messagesContainer.scrollTop = messagesContainer.scrollHeight;
    }

    // Helper: Show/Hide typing indicator
    function showTyping(show) {
        if (show) {
            typingIndicator.style.display = "flex";
            messagesContainer.scrollTop = messagesContainer.scrollHeight;
        } else {
            typingIndicator.style.display = "none";
        }
    }

    // Helper: Toast Notifications
    function showNotification(text, type = "info") {
        const toast = document.createElement("div");
        toast.style.position = "fixed";
        toast.style.bottom = "24px";
        toast.style.right = "24px";
        toast.style.padding = "12px 24px";
        toast.style.borderRadius = "8px";
        toast.style.color = "white";
        toast.style.fontSize = "14px";
        toast.style.fontWeight = "600";
        toast.style.boxShadow = "0 4px 12px rgba(0,0,0,0.3)";
        toast.style.zIndex = "1000";
        toast.style.animation = "slideUp 0.3s ease-out";
        
        if (type === "success") {
            toast.style.background = "var(--success)";
        } else if (type === "danger") {
            toast.style.background = "var(--danger)";
        } else {
            toast.style.background = "var(--bg-tertiary)";
            toast.style.border = "1px solid var(--border-color)";
        }

        toast.textContent = text;
        document.body.appendChild(toast);

        setTimeout(() => {
            toast.style.animation = "slideUp 0.3s reverse ease-in";
            setTimeout(() => toast.remove(), 300);
        }, 3000);
    }
});
