package main

import (
	"database/sql"
	"log"
	"os"
	"time"

	_ "github.com/lib/pq" // PostgreSQL driver
)

func main() {
	// Retrieve database configuration from environment variables
	dbHost := os.Getenv("DB_HOST")
	dbPort := os.Getenv("DB_PORT")
	dbUser := os.Getenv("DB_USER")
	dbPassword := os.Getenv("DB_PASSWORD")
	dbName := os.Getenv("DB_NAME")

	// Connect to the database
	connStr := "host=" + dbHost + " port=" + dbPort + " user=" + dbUser + " password=" + dbPassword + " dbname=" + dbName + " sslmode=disable"
	db, err := sql.Open("postgres", connStr)
	if err != nil {
		log.Fatal(err)
	}
	defer db.Close()

	// Periodically check for new posts
	for {
		rows, err := db.Query("SELECT id, title FROM posts WHERE created_at > NOW() - INTERVAL '1 minute'")
		if err != nil {
			log.Println(err)
		} else {
			for rows.Next() {
				var id int
				var title string
				rows.Scan(&id, &title)
				log.Printf("New post detected: ID=%d, Title=%s", id, title)
				// Simulate a task like sending an email
			}
			rows.Close()
		}
		time.Sleep(1 * time.Minute)
	}
}
