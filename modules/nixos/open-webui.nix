{ ... }:

{
  networking.firewall.allowedTCPPorts = [ 8090 ];

  services.open-webui = {
    enable = true;
    host = "0.0.0.0";
    port = 8090;
    environment = {
      ENABLE_OLLAMA_API = "False";
      OPENAI_API_BASE_URLS = "http://127.0.0.1:4000/v1";
      OPENAI_API_KEYS = "none";
      ANONYMIZED_TELEMETRY = "False";
      DO_NOT_TRACK = "True";
      SCARF_NO_ANALYTICS = "True";
      WEBUI_AUTH = "True";
      DEFAULT_USER_ROLE = "user";
    };
  };
}
