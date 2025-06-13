package main

import (
	"encoding/json"
	"log"
	"net/http"
	"os"
)

func main() {
	// Get the backend API URL from an environment variable (set by ConfigMap)
	apiURL := os.Getenv("API_URL")
	if apiURL == "" {
		log.Fatal("API_URL not set")
	}

	// Serve static files from the "static" directory
	fs := http.FileServer(http.Dir("static"))
	http.Handle("/", fs)

	// Provide the API URL to the frontend via a /config endpoint
	http.HandleFunc("/config", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(map[string]string{"apiUrl": apiURL})
	})

	log.Println("Starting frontend server on :8080")
	log.Fatal(http.ListenAndServe(":8080", nil))
}
