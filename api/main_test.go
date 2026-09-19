package main

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"
)

func TestModoTeste(t *testing.T) {
	store := NewStore()
	handler := newServer(true, store)

	t.Run("GET /_teste/relogio retorna hora inicial", func(t *testing.T) {
		req := httptest.NewRequest("GET", "/_teste/relogio", nil)
		rec := httptest.NewRecorder()
		handler.ServeHTTP(rec, req)

		if rec.Code != http.StatusOK {
			t.Errorf("esperava 200, recebeu %d", rec.Code)
		}

		var resp map[string]string
		if err := json.Unmarshal(rec.Body.Bytes(), &resp); err != nil {
			t.Fatalf("resposta invalida: %v", err)
		}

		esperado := "2026-10-13T09:00:00-03:00"
		if resp["agora"] != esperado {
			t.Errorf("esperava %s, recebeu %s", esperado, resp["agora"])
		}
	})

	t.Run("PUT /_teste/relogio altera o tempo", func(t *testing.T) {
		novaHora := "2026-10-19T10:00:00Z"
		body, _ := json.Marshal(map[string]string{"agora": novaHora})
		req := httptest.NewRequest("PUT", "/_teste/relogio", bytes.NewBuffer(body))
		rec := httptest.NewRecorder()
		handler.ServeHTTP(rec, req)

		if rec.Code != http.StatusOK {
			t.Errorf("esperava 200, recebeu %d", rec.Code)
		}

		var resp map[string]string
		if err := json.Unmarshal(rec.Body.Bytes(), &resp); err != nil {
			t.Fatalf("resposta invalida: %v", err)
		}

		t1, _ := time.Parse(time.RFC3339, novaHora)
		t2, _ := time.Parse(time.RFC3339, resp["agora"])
		if !t1.Equal(t2) {
			t.Errorf("esperava %v, recebeu %v", t1, t2)
		}
	})

	t.Run("PUT /_teste/relogio recusa corpo invalido", func(t *testing.T) {
		req := httptest.NewRequest("PUT", "/_teste/relogio", bytes.NewBufferString("nao-json"))
		rec := httptest.NewRecorder()
		handler.ServeHTTP(rec, req)

		if rec.Code != http.StatusUnprocessableEntity {
			t.Fatalf("esperava 422, recebeu %d", rec.Code)
		}

		var resp map[string]string
		if err := json.Unmarshal(rec.Body.Bytes(), &resp); err != nil {
			t.Fatalf("resposta invalida: %v", err)
		}
		if resp["erro"] != "DADOS_INVALIDOS" {
			t.Fatalf("esperava DADOS_INVALIDOS, recebeu %s", resp["erro"])
		}
	})

	t.Run("POST /_teste/reset restaura estado", func(t *testing.T) {
		store.SetRelogio(time.Now())
		store.Usuarios = nil
		store.Salas = nil
		store.Atividades = map[string]struct{}{"nao-contratada": {}}

		req := httptest.NewRequest("POST", "/_teste/reset", nil)
		rec := httptest.NewRecorder()
		handler.ServeHTTP(rec, req)

		if rec.Code != http.StatusNoContent {
			t.Errorf("esperava 204, recebeu %d", rec.Code)
		}

		esperado := "2026-10-13T09:00:00-03:00"
		agora := store.GetAgora().Format(time.RFC3339)
		if agora != esperado {
			t.Errorf("esperava %s, recebeu %s", esperado, agora)
		}

		if len(store.Usuarios) != 10 {
			t.Fatalf("esperava 10 usuarios iniciais, recebeu %d", len(store.Usuarios))
		}
		if store.Usuarios["org-ana"].Papel != "organizacao" {
			t.Fatalf("usuario org-ana nao foi restaurado como organizacao")
		}
		if store.Usuarios["p-joao"].Nome != "João Pedro Martins" {
			t.Fatalf("usuario p-joao nao foi restaurado")
		}

		if len(store.Salas) != 4 {
			t.Fatalf("esperava 4 salas iniciais, recebeu %d", len(store.Salas))
		}
		if store.Salas["auditorio"].Capacidade != 200 {
			t.Fatalf("sala auditorio nao foi restaurada com capacidade 200")
		}
		if store.Salas["lab-3"].Nome != "Laboratório 3" {
			t.Fatalf("sala lab-3 nao foi restaurada")
		}

		if len(store.Atividades) != 0 {
			t.Fatalf("reset nao deve criar atividades iniciais")
		}
	})
}

func TestModoTesteDesativado(t *testing.T) {
	handler := newServer(false, NewStore())

	t.Run("Rotas /_teste/ retornam 404 quando MODO_TESTE=0", func(t *testing.T) {
		rotas := []struct {
			metodo string
			rota   string
		}{
			{http.MethodPost, "/_teste/reset"},
			{http.MethodGet, "/_teste/relogio"},
			{http.MethodPut, "/_teste/relogio"},
		}
		for _, rota := range rotas {
			req := httptest.NewRequest(rota.metodo, rota.rota, nil)
			rec := httptest.NewRecorder()
			handler.ServeHTTP(rec, req)

			if rec.Code != http.StatusNotFound {
				t.Errorf("%s %s: esperava 404, recebeu %d", rota.metodo, rota.rota, rec.Code)
			}
		}
	})
}
