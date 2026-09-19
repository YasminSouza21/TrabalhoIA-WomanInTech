package main

import (
	"encoding/json"
	"net/http"
	"time"
)

func handleReset(s *Store) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		if r.Method != http.MethodPost {
			http.Error(w, "Metodo nao permitido", http.StatusMethodNotAllowed)
			return
		}
		s.Reset()
		w.WriteHeader(http.StatusNoContent)
	}
}

func handleRelogio(s *Store) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json; charset=utf-8")

		switch r.Method {
		case http.MethodGet:
			agora := s.GetAgora()
			json.NewEncoder(w).Encode(map[string]string{
				"agora": agora.Format(time.RFC3339),
			})

		case http.MethodPut:
			var body struct {
				Agora string `json:"agora"`
			}
			if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
				w.WriteHeader(http.StatusUnprocessableEntity)
				json.NewEncoder(w).Encode(map[string]string{
					"erro":     "DADOS_INVALIDOS",
					"mensagem": "Corpo JSON invalido",
				})
				return
			}

			t, err := time.Parse(time.RFC3339, body.Agora)
			if err != nil {
				w.WriteHeader(http.StatusUnprocessableEntity)
				json.NewEncoder(w).Encode(map[string]string{
					"erro":     "DADOS_INVALIDOS",
					"mensagem": "Formato de data invalido",
				})
				return
			}

			s.SetRelogio(t)
			json.NewEncoder(w).Encode(map[string]string{
				"agora": t.Format(time.RFC3339),
			})

		default:
			http.Error(w, "Metodo nao permitido", http.StatusMethodNotAllowed)
		}
	}
}
