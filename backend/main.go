package main

import (
	"context"
	"database/sql"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"time"

	_ "github.com/lib/pq" // PostgreSQL driver
	"github.com/rs/cors"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/apis/meta/v1/unstructured"
	"k8s.io/apimachinery/pkg/runtime/schema"
	"k8s.io/client-go/dynamic"
	"k8s.io/client-go/rest"
)

var (
	db            *sql.DB
	dynamicClient *dynamic.DynamicClient
)

func main() {
	var err error

	// Initialize Kubernetes client only if running in Kubernetes
	if os.Getenv("KUBERNETES_SERVICE_HOST") != "" {
		config, err := rest.InClusterConfig()
		if err != nil {
			log.Printf("Warning: Error creating in-cluster config: %v", err)
		} else {
			dynamicClient, err = dynamic.NewForConfig(config)
			if err != nil {
				log.Printf("Warning: Error creating dynamic client: %v", err)
			}
		}
	}

	// Initialize PostgreSQL connection
	dbHost := os.Getenv("DB_HOST")
	dbPort := os.Getenv("DB_PORT")
	dbUser := os.Getenv("DB_USER")
	dbPassword := os.Getenv("DB_PASSWORD")
	dbName := os.Getenv("DB_NAME")

	connStr := fmt.Sprintf("host=%s port=%s user=%s password=%s dbname=%s sslmode=disable", dbHost, dbPort, dbUser, dbPassword, dbName)
	db, err = sql.Open("postgres", connStr)
	if err != nil {
		log.Fatal(err)
	}
	defer db.Close()

	// Create posts table
	_, err = db.Exec(`CREATE TABLE IF NOT EXISTS posts (
		id SERIAL PRIMARY KEY,
		title TEXT,
		content TEXT,
		created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
	)`)
	if err != nil {
		log.Fatal(err)
	}

	// HTTP routes
	mux := http.NewServeMux()
	mux.HandleFunc("/posts", postsHandler)        // PostgreSQL posts
	mux.HandleFunc("/crd-posts", crdPostsHandler) // CRD posts
	mux.HandleFunc("/healthz", healthCheckHandler(db))

	// CORS middleware
	handler := cors.Default().Handler(mux)

	log.Println("Starting backend API on :8081")
	log.Fatal(http.ListenAndServe(":8081", handler))
}

// postsHandler handles PostgreSQL posts
func postsHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method == "GET" {
		rows, err := db.Query("SELECT id, title, content FROM posts")
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		defer rows.Close()

		var posts []Post
		for rows.Next() {
			var p Post
			if err := rows.Scan(&p.ID, &p.Title, &p.Content); err != nil {
				http.Error(w, err.Error(), http.StatusInternalServerError)
				return
			}
			posts = append(posts, p)
		}
		json.NewEncoder(w).Encode(posts)
	} else if r.Method == "POST" {
		var p Post
		if err := json.NewDecoder(r.Body).Decode(&p); err != nil {
			http.Error(w, err.Error(), http.StatusBadRequest)
			return
		}
		_, err := db.Exec("INSERT INTO posts (title, content) VALUES ($1, $2)", p.Title, p.Content)
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		w.WriteHeader(http.StatusCreated)
	} else {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
	}
}

// crdPostsHandler handles BlogPost CRD
func crdPostsHandler(w http.ResponseWriter, r *http.Request) {
	if dynamicClient == nil {
		http.Error(w, "Kubernetes client not available in local development", http.StatusNotImplemented)
		return
	}

	gvr := schema.GroupVersionResource{
		Group:    "demo.example.com",
		Version:  "v1",
		Resource: "blogposts",
	}

	if r.Method == "GET" {
		list, err := dynamicClient.Resource(gvr).Namespace("default").List(context.Background(), metav1.ListOptions{})
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}

		var posts []map[string]interface{}
		for _, item := range list.Items {
			spec, _, _ := unstructured.NestedMap(item.Object, "spec")
			posts = append(posts, spec)
		}
		json.NewEncoder(w).Encode(posts)
	} else if r.Method == "POST" {
		var post map[string]interface{}
		if err := json.NewDecoder(r.Body).Decode(&post); err != nil {
			http.Error(w, err.Error(), http.StatusBadRequest)
			return
		}

		obj := &unstructured.Unstructured{
			Object: map[string]interface{}{
				"apiVersion": "demo.example.com/v1",
				"kind":       "BlogPost",
				"metadata": map[string]interface{}{
					"name": fmt.Sprintf("post-%d", time.Now().UnixNano()),
				},
				"spec": post,
			},
		}

		_, err := dynamicClient.Resource(gvr).Namespace("default").Create(context.Background(), obj, metav1.CreateOptions{})
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		w.WriteHeader(http.StatusCreated)
	} else {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
	}
}

// healthCheckHandler checks the database connection.
func healthCheckHandler(db *sql.DB) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		// Ping is a lightweight way to check the DB connection.
		err := db.Ping()
		if err != nil {
			// If ping fails, return a 500 error, which Kubernetes will see as a failed probe.
			http.Error(w, "Database connection is not healthy", http.StatusInternalServerError)
			return
		}
		// If everything is fine, return a 200 OK.
		w.WriteHeader(http.StatusOK)
	}
}

type Post struct {
	ID      int    `json:"id"`
	Title   string `json:"title"`
	Content string `json:"content"`
}

// Test change --- IGNORE ---