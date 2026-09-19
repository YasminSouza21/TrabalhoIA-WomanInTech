package main

import (
	"fmt"
	"log"
	"net/http"
	"os"
)

func newServer(modoTeste bool, store *Store) http.Handler {
	mux := http.NewServeMux()

	if modoTeste {
		mux.HandleFunc("/_teste/reset", handleReset(store))
		mux.HandleFunc("/_teste/relogio", handleRelogio(store))
	} else {
		mux.HandleFunc("/_teste/", func(w http.ResponseWriter, r *http.Request) {
			http.NotFound(w, r)
		})
	}

	return mux
}

func main() {
	port := os.Getenv("PORT")
	if port == "" {
		port = "3000"
	}

	modoTeste := os.Getenv("MODO_TESTE") == "1"
	store := NewStore()
	handler := newServer(modoTeste, store)

	fmt.Printf("Servidor rodando na porta %s (MODO_TESTE=%v)\n", port, modoTeste)
	log.Fatal(http.ListenAndServe(":"+port, handler))
}
