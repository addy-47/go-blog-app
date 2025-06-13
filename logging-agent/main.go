package main

import (
	"log"
	"os"
	"time"
)

func main() {
	// Get the node name from an environment variable (set by the downward API)
	nodeName := os.Getenv("NODE_NAME")
	if nodeName == "" {
		log.Fatal("NODE_NAME not set")
	}

	// Periodically log the node name
	for {
		log.Printf("Hello from node %s", nodeName)
		time.Sleep(10 * time.Second)
	}
}
