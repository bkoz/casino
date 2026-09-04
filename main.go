package main

import (
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"strings"
)

// Obfuscated flag - embedded at compile time
// This makes it harder to extract with simple 'strings' command
var flagObfuscated = []byte{
	0x04, 0x0e, 0x03, 0x05, 0x39, 0x20, 0x71, 0x2c, 0x71, 0x26, 0x73, 0x21, 0x36, 0x1d,
	0x25, 0x72, 0x36, 0x1d, 0x30, 0x72, 0x20, 0x20, 0x71, 0x26, 0x1d, 0x70, 0x72, 0x70,
	0x74, 0x3f,
}
var xorKey byte = 66

// Deobfuscate flag at runtime
func getFlag() string {
	decoded := make([]byte, len(flagObfuscated))
	for i, b := range flagObfuscated {
		decoded[i] = b ^ xorKey
	}
	return string(decoded)
}

// In-memory storage for the stolen service account token
// This is injected at startup and NOT stored in the filesystem
var stolenToken string

type FetchResponse struct {
	Content     string `json:"content,omitempty"`
	Error       string `json:"error,omitempty"`
	StatusCode  int    `json:"status_code,omitempty"`
	Hint        string `json:"hint,omitempty"`
	Description string `json:"description,omitempty"`
}

type InfoResponse struct {
	Hostname          string `json:"hostname"`
	PodName           string `json:"pod_name"`
	Namespace         string `json:"namespace"`
	ServiceAccount    string `json:"service_account"`
	KubernetesService string `json:"kubernetes_service"`
	Hint              string `json:"hint"`
}

type HealthResponse struct {
	Status string `json:"status"`
}

func main() {
	// Load the stolen token from environment variable
	// This token is injected by an init container, NOT mounted by Kubernetes
	stolenToken = os.Getenv("STOLEN_SA_TOKEN")
	if stolenToken == "" {
		log.Fatal("ERROR: STOLEN_SA_TOKEN environment variable not set!")
	}

	log.Println("🎰 Cipher Breeze Casino Kiosk starting...")
	log.Printf("Token loaded: %d characters (hidden in memory)\n", len(stolenToken))
	log.Printf("Flag embedded in binary: %d bytes (obfuscated)\n", len(flagObfuscated))

	http.HandleFunc("/", handleIndex)
	http.HandleFunc("/fetch", handleFetch)
	http.HandleFunc("/info", handleInfo)
	http.HandleFunc("/health", handleHealth)

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	log.Printf("Server listening on port %s\n", port)
	log.Fatal(http.ListenAndServe(":"+port, nil))
}

func handleIndex(w http.ResponseWriter, r *http.Request) {
	html := `<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Cipher Breeze Digital Concierge</title>
    <style>
        body {
            font-family: 'Georgia', serif;
            background: linear-gradient(135deg, #1a1a1a 0%, #2d2d2d 100%);
            color: #d4af37;
            margin: 0;
            padding: 20px;
        }
        .container {
            max-width: 800px;
            margin: 50px auto;
            background: rgba(0, 0, 0, 0.7);
            border: 2px solid #d4af37;
            border-radius: 10px;
            padding: 30px;
            box-shadow: 0 0 30px rgba(212, 175, 55, 0.3);
        }
        h1 {
            text-align: center;
            font-size: 2.5em;
            margin-bottom: 10px;
        }
        .subtitle {
            text-align: center;
            color: #b8860b;
            margin-bottom: 30px;
        }
        .feature-box {
            background: rgba(212, 175, 55, 0.1);
            border: 1px solid #d4af37;
            border-radius: 5px;
            padding: 20px;
            margin: 20px 0;
        }
        input[type="text"] {
            width: calc(100% - 20px);
            padding: 10px;
            background: #1a1a1a;
            border: 1px solid #d4af37;
            color: #d4af37;
            border-radius: 5px;
            font-size: 14px;
        }
        button {
            background: #d4af37;
            color: #1a1a1a;
            border: none;
            padding: 12px 30px;
            font-size: 16px;
            border-radius: 5px;
            cursor: pointer;
            font-weight: bold;
            margin-top: 10px;
        }
        button:hover {
            background: #b8860b;
        }
        .result {
            margin-top: 20px;
            padding: 15px;
            background: rgba(0, 0, 0, 0.5);
            border: 1px solid #d4af37;
            border-radius: 5px;
            font-family: 'Courier New', monospace;
            font-size: 12px;
            max-height: 400px;
            overflow-y: auto;
            white-space: pre-wrap;
            word-wrap: break-word;
        }
        .hint {
            color: #808080;
            font-size: 0.85em;
            font-style: italic;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>CIPHER BREEZE CASINO</h1>
        <p class="subtitle">Digital Concierge Service</p>

        <div class="feature-box">
            <h3>Document Viewer</h3>
            <p>Enter a URL to view content from our systems:</p>
            <input type="text" id="url" placeholder="http://example.com/document.txt" />
            <button onclick="fetchDocument()">Fetch Document</button>
            <p class="hint">Try: http://internal-docs/menu.txt</p>
            <div id="doc-result" class="result" style="display:none;"></div>
        </div>

        <div class="feature-box">
            <h3>System Information</h3>
            <button onclick="fetchInfo()">View System Info</button>
            <div id="info-result" class="result" style="display:none;"></div>
        </div>
    </div>

    <script>
        function fetchDocument() {
            const url = document.getElementById('url').value;
            const resultDiv = document.getElementById('doc-result');

            fetch('/fetch?url=' + encodeURIComponent(url))
                .then(response => response.json())
                .then(data => {
                    resultDiv.style.display = 'block';
                    if (data.error) {
                        resultDiv.textContent = 'Error: ' + data.error;
                    } else {
                        resultDiv.textContent = data.content;
                    }
                })
                .catch(err => {
                    resultDiv.style.display = 'block';
                    resultDiv.textContent = 'Error: ' + err.message;
                });
        }

        function fetchInfo() {
            const resultDiv = document.getElementById('info-result');

            fetch('/info')
                .then(response => response.json())
                .then(data => {
                    resultDiv.style.display = 'block';
                    resultDiv.textContent = JSON.stringify(data, null, 2);
                })
                .catch(err => {
                    resultDiv.style.display = 'block';
                    resultDiv.textContent = 'Error: ' + err.message;
                });
        }
    </script>
</body>
</html>`
	w.Header().Set("Content-Type", "text/html")
	w.Write([]byte(html))
}

func handleFetch(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	url := r.URL.Query().Get("url")
	if url == "" {
		json.NewEncoder(w).Encode(FetchResponse{Error: "No URL provided"})
		return
	}

	// VULNERABILITY 1: Special endpoint to leak the in-memory service account token
	// Players must discover this specific URL to extract the token
	if url == "secret://casino-internal/serviceaccount/token" {
		log.Printf("⚠️  Token requested via secret:// protocol")
		json.NewEncoder(w).Encode(FetchResponse{
			Content:     stolenToken,
			Description: "Kubernetes service account JWT token",
			Hint:        "This token can be used to authenticate to the Kubernetes API. In a real attack, you could use this with kubectl or curl to access cluster resources. For this challenge, you've found the authentication piece - now find the vault!",
		})
		return
	}

	// VULNERABILITY 2: Special endpoint to leak the embedded flag
	// This is the ultimate goal - players must discover this after getting the token
	if url == "secret://casino-internal/vault/flag" {
		log.Printf("🎯 FLAG requested via secret:// protocol")
		json.NewEncoder(w).Encode(FetchResponse{
			Content:     getFlag(),
			Description: "CTF flag - Challenge complete!",
			Hint:        "Congratulations! You've successfully exploited the SSRF vulnerability to extract the flag from the vault. In this challenge you learned: (1) SSRF protocol discovery, (2) Custom URL scheme exploitation, (3) Path enumeration, (4) Embedded secrets in compiled binaries. The flag was XOR-obfuscated in the Go binary and the service account token was stored in memory only.",
		})
		return
	}

	// Helpful error for secret:// protocol with wrong path
	if strings.HasPrefix(url, "secret://casino-internal/") {
		json.NewEncoder(w).Encode(FetchResponse{
			Error: "Path not found. Hint: This system provides access to authentication resources at /serviceaccount/token and secure storage at /vault/flag. Remember the pattern from /info: protocol://hostname/path/to/resource",
		})
		return
	}

	// Helpful error for secret:// protocol with wrong hostname
	if strings.HasPrefix(url, "secret://") {
		json.NewEncoder(w).Encode(FetchResponse{
			Error: "Hostname not recognized. Hint: Try 'casino-internal' as the hostname for internal resources.",
		})
		return
	}

	// Handle file:// protocol (traditional SSRF)
	if strings.HasPrefix(url, "file://") {
		filePath := strings.TrimPrefix(url, "file://")

		// Special hint for Kubernetes service account token path
		if strings.Contains(filePath, "/var/run/secrets/kubernetes.io/serviceaccount/token") {
			json.NewEncoder(w).Encode(FetchResponse{
				Error: "Token not found in standard Kubernetes location. This system uses a custom protocol for internal resources. Hint: Try the secret:// protocol with an internal hostname.",
			})
			return
		}

		content, err := os.ReadFile(filePath)
		if err != nil {
			json.NewEncoder(w).Encode(FetchResponse{Error: fmt.Sprintf("Failed to read file: %v", err)})
			return
		}
		json.NewEncoder(w).Encode(FetchResponse{Content: string(content)})
		return
	}

	// Handle HTTP(S) URLs
	if strings.HasPrefix(url, "http://") || strings.HasPrefix(url, "https://") {
		resp, err := http.Get(url)
		if err != nil {
			json.NewEncoder(w).Encode(FetchResponse{Error: fmt.Sprintf("Request failed: %v", err)})
			return
		}
		defer resp.Body.Close()

		body, err := io.ReadAll(resp.Body)
		if err != nil {
			json.NewEncoder(w).Encode(FetchResponse{Error: fmt.Sprintf("Failed to read response: %v", err)})
			return
		}

		json.NewEncoder(w).Encode(FetchResponse{
			Content:    string(body),
			StatusCode: resp.StatusCode,
		})
		return
	}

	json.NewEncoder(w).Encode(FetchResponse{Error: "Unsupported URL protocol"})
}

func handleInfo(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	hostname, _ := os.Hostname()

	response := InfoResponse{
		Hostname:          hostname,
		PodName:           hostname,
		Namespace:         os.Getenv("POD_NAMESPACE"),
		ServiceAccount:    os.Getenv("SERVICE_ACCOUNT"),
		KubernetesService: os.Getenv("KUBERNETES_SERVICE_HOST"),
		Hint:              "This system supports standard protocols (file://, http://, https://) but also custom internal schemes. Try protocols like secret://, internal://, or admin:// to access restricted resources. This system handles authentication tokens and vault storage - try paths related to these services. Pattern: protocol://hostname/path/to/resource",
	}

	json.NewEncoder(w).Encode(response)
}

func handleHealth(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(HealthResponse{Status: "healthy"})
}
