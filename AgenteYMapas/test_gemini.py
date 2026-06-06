import os
from autogen import ConversableAgent

def main():
    print("Testing Gemini configuration with AG2/AutoGen...")
    print("Environment variables:")
    for k, v in os.environ.items():
        if "google" in k.lower() or "gemini" in k.lower() or "api" in k.lower():
            # Avoid printing secret keys completely, but print names
            val = v[:5] + "..." if len(v) > 5 else v
            print(f"  {k} = {val}")

    # Configuration for Gemini
    config_list = [
        {
            "model": "gemini-3.5-flash",
            "api_type": "google",
            # We will rely on ambient environment credentials or GEMINI_API_KEY if present
            "api_key": os.environ.get("GEMINI_API_KEY") or os.environ.get("GOOGLE_API_KEY")
        }
    ]

    print(f"Config list: {config_list}")

    try:
        agent = ConversableAgent(
            name="durango_agent",
            system_message="You are a tour guide of Durango, Mexico. Keep it short.",
            llm_config={"config_list": config_list},
        )
        
        reply = agent.generate_reply(
            messages=[{"role": "user", "content": "Hola, ¿cuáles son los 3 lugares turísticos principales de Durango?"}]
        )
        print("\nSuccess! Reply from agent:")
        print(reply)
    except Exception as e:
        print("\nError occurred:")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    main()
