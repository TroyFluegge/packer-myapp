package main

import (
	"fmt"
	"log"
	"net/http"
)

func main() {
	log.Print("Starting up!")

	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprint(w, "Hello world! v2.5")
	})

	// a truly basic health endpoint
	http.HandleFunc("/healthz", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprint(w, "looks good v2.5")
	})

	log.Fatal(http.ListenAndServe(":8080", nil))
}
