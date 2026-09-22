package main

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
)

func executar(handler http.Handler, metodo, caminho, usuario, corpo string) *httptest.ResponseRecorder {
	req := httptest.NewRequest(metodo, caminho, bytes.NewBufferString(corpo))
	if usuario != "" {
		req.Header.Set("X-Usuario", usuario)
	}
	if corpo != "" {
		req.Header.Set("Content-Type", "application/json")
	}
	rec := httptest.NewRecorder()
	handler.ServeHTTP(rec, req)
	return rec
}

func decodificar(t *testing.T, rec *httptest.ResponseRecorder) map[string]any {
	t.Helper()
	var resp map[string]any
	if err := json.Unmarshal(rec.Body.Bytes(), &resp); err != nil {
		t.Fatalf("resposta invalida: %v; corpo=%s", err, rec.Body.String())
	}
	return resp
}

func decodificarLista(t *testing.T, rec *httptest.ResponseRecorder) []map[string]any {
	t.Helper()
	var resp []map[string]any
	if err := json.Unmarshal(rec.Body.Bytes(), &resp); err != nil {
		t.Fatalf("resposta invalida: %v; corpo=%s", err, rec.Body.String())
	}
	return resp
}

func erro(t *testing.T, rec *httptest.ResponseRecorder, status int, codigo string) {
	t.Helper()
	if rec.Code != status {
		t.Fatalf("esperava status %d, recebeu %d: %s", status, rec.Code, rec.Body.String())
	}
	resp := decodificar(t, rec)
	if resp["erro"] != codigo {
		t.Fatalf("esperava erro %s, recebeu %v", codigo, resp["erro"])
	}
}

func atividadeValida(titulo, tipo, sala string, vagas int, encontros string) string {
	return `{"titulo":"` + titulo + `","tipo":"` + tipo + `","salaId":"` + sala + `","vagas":` + jsonNumber(vagas) + `,"cargaHorariaMinutos":999,"encontros":` + encontros + `}`
}

func jsonNumber(n int) string {
	b, _ := json.Marshal(n)
	return string(b)
}

func palestraPadrao(titulo string) string {
	return atividadeValida(titulo, "palestra", "sala-101", 30, `[{"inicio":"2026-10-19T09:00:00-03:00","fim":"2026-10-19T11:00:00-03:00"}]`)
}

func criarAtividadeTeste(t *testing.T, handler http.Handler, corpo string) map[string]any {
	t.Helper()
	rec := executar(handler, http.MethodPost, "/atividades", "org-ana", corpo)
	if rec.Code != http.StatusCreated {
		t.Fatalf("esperava 201, recebeu %d: %s", rec.Code, rec.Body.String())
	}
	return decodificar(t, rec)
}

func TestM1Fatia1CriacaoDeAtividades(t *testing.T) {
	store := NewStore()
	handler := newServer(true, store)

	t.Run("cria palestra valida e ignora carga horaria enviada", func(t *testing.T) {
		executar(handler, http.MethodPost, "/_teste/reset", "", "")
		resp := criarAtividadeTeste(t, handler, palestraPadrao("Abertura"))
		if resp["titulo"] != "Abertura" || resp["tipo"] != "palestra" || resp["salaId"] != "sala-101" {
			t.Fatalf("atividade retornada com campos incorretos: %#v", resp)
		}
		if resp["cargaHorariaMinutos"] != float64(120) {
			t.Fatalf("carga deveria ser 120, recebeu %v", resp["cargaHorariaMinutos"])
		}
		if resp["situacao"] != "prevista" || resp["ocupadas"] != float64(0) || resp["vagasRestantes"] != float64(30) || resp["emEspera"] != float64(0) {
			t.Fatalf("campos calculados incorretos: %#v", resp)
		}
		encontros := resp["encontros"].([]any)
		if len(encontros) != 1 || !strings.HasPrefix(encontros[0].(map[string]any)["id"].(string), "enc_") {
			t.Fatalf("encontros retornados incorretos: %#v", resp["encontros"])
		}
		if !strings.HasPrefix(resp["id"].(string), "atv_") {
			t.Fatalf("id de atividade invalido: %v", resp["id"])
		}
	})

	t.Run("cria minicurso valido com carga somada", func(t *testing.T) {
		executar(handler, http.MethodPost, "/_teste/reset", "", "")
		corpo := atividadeValida("Go pratico", "minicurso", "lab-3", 20, `[{"inicio":"2026-10-19T14:00:00-03:00","fim":"2026-10-19T16:00:00-03:00"},{"inicio":"2026-10-20T14:00:00-03:00","fim":"2026-10-20T17:00:00-03:00"}]`)
		resp := criarAtividadeTeste(t, handler, corpo)
		if resp["cargaHorariaMinutos"] != float64(300) {
			t.Fatalf("carga deveria ser 300, recebeu %v", resp["cargaHorariaMinutos"])
		}
	})

	t.Run("recusa usuario ausente desconhecido e participante na criacao", func(t *testing.T) {
		executar(handler, http.MethodPost, "/_teste/reset", "", "")
		erro(t, executar(handler, http.MethodPost, "/atividades", "", palestraPadrao("Sem usuario")), http.StatusUnauthorized, "USUARIO_DESCONHECIDO")
		erro(t, executar(handler, http.MethodPost, "/atividades", "nao-existe", palestraPadrao("Desconhecido")), http.StatusUnauthorized, "USUARIO_DESCONHECIDO")
		erro(t, executar(handler, http.MethodPost, "/atividades", "p-carla", palestraPadrao("Participante")), http.StatusForbidden, "SOMENTE_ORGANIZACAO")
	})

	t.Run("recusa corpo json invalido e datas invalidas", func(t *testing.T) {
		executar(handler, http.MethodPost, "/_teste/reset", "", "")
		erro(t, executar(handler, http.MethodPost, "/atividades", "org-ana", "nao-json"), http.StatusUnprocessableEntity, "DADOS_INVALIDOS")
		corpo := atividadeValida("Data ruim", "palestra", "sala-101", 10, `[{"inicio":"data","fim":"2026-10-19T11:00:00-03:00"}]`)
		erro(t, executar(handler, http.MethodPost, "/atividades", "org-ana", corpo), http.StatusUnprocessableEntity, "DADOS_INVALIDOS")
	})

	t.Run("valida quantidade de encontros por tipo", func(t *testing.T) {
		executar(handler, http.MethodPost, "/_teste/reset", "", "")
		palestraDois := atividadeValida("Palestra dois", "palestra", "sala-101", 10, `[{"inicio":"2026-10-19T09:00:00-03:00","fim":"2026-10-19T10:00:00-03:00"},{"inicio":"2026-10-20T09:00:00-03:00","fim":"2026-10-20T10:00:00-03:00"}]`)
		erro(t, executar(handler, http.MethodPost, "/atividades", "org-ana", palestraDois), http.StatusUnprocessableEntity, "QUANTIDADE_DE_ENCONTROS")
		palestraZero := atividadeValida("Palestra zero", "palestra", "sala-101", 10, `[]`)
		erro(t, executar(handler, http.MethodPost, "/atividades", "org-ana", palestraZero), http.StatusUnprocessableEntity, "QUANTIDADE_DE_ENCONTROS")
		miniUm := atividadeValida("Mini um", "minicurso", "sala-101", 10, `[{"inicio":"2026-10-19T09:00:00-03:00","fim":"2026-10-19T10:00:00-03:00"}]`)
		erro(t, executar(handler, http.MethodPost, "/atividades", "org-ana", miniUm), http.StatusUnprocessableEntity, "QUANTIDADE_DE_ENCONTROS")
		miniSeis := atividadeValida("Mini seis", "minicurso", "sala-101", 10, `[{"inicio":"2026-10-19T09:00:00-03:00","fim":"2026-10-19T10:00:00-03:00"},{"inicio":"2026-10-19T10:15:00-03:00","fim":"2026-10-19T11:15:00-03:00"},{"inicio":"2026-10-20T09:00:00-03:00","fim":"2026-10-20T10:00:00-03:00"},{"inicio":"2026-10-20T10:15:00-03:00","fim":"2026-10-20T11:15:00-03:00"},{"inicio":"2026-10-21T09:00:00-03:00","fim":"2026-10-21T10:00:00-03:00"},{"inicio":"2026-10-21T10:15:00-03:00","fim":"2026-10-21T11:15:00-03:00"}]`)
		erro(t, executar(handler, http.MethodPost, "/atividades", "org-ana", miniSeis), http.StatusUnprocessableEntity, "QUANTIDADE_DE_ENCONTROS")
	})

	t.Run("valida duracao periodo mesmo dia e sobreposicao interna dos encontros", func(t *testing.T) {
		casos := []string{
			atividadeValida("Curta", "palestra", "sala-101", 10, `[{"inicio":"2026-10-19T09:00:00-03:00","fim":"2026-10-19T09:59:00-03:00"}]`),
			atividadeValida("Longa", "palestra", "sala-101", 10, `[{"inicio":"2026-10-19T09:00:00-03:00","fim":"2026-10-19T13:01:00-03:00"}]`),
			atividadeValida("Fora", "palestra", "sala-101", 10, `[{"inicio":"2026-10-24T09:00:00-03:00","fim":"2026-10-24T10:00:00-03:00"}]`),
			atividadeValida("Meia noite", "palestra", "sala-101", 10, `[{"inicio":"2026-10-19T23:30:00-03:00","fim":"2026-10-20T00:30:00-03:00"}]`),
			atividadeValida("Sobrepoe", "minicurso", "sala-101", 10, `[{"inicio":"2026-10-19T09:00:00-03:00","fim":"2026-10-19T11:00:00-03:00"},{"inicio":"2026-10-19T10:30:00-03:00","fim":"2026-10-19T12:30:00-03:00"}]`),
		}
		for _, corpo := range casos {
			executar(handler, http.MethodPost, "/_teste/reset", "", "")
			erro(t, executar(handler, http.MethodPost, "/atividades", "org-ana", corpo), http.StatusUnprocessableEntity, "ENCONTRO_INVALIDO")
		}
	})

	t.Run("valida sala existente vagas e conflitos com intervalo minimo", func(t *testing.T) {
		executar(handler, http.MethodPost, "/_teste/reset", "", "")
		erro(t, executar(handler, http.MethodPost, "/atividades", "org-ana", atividadeValida("Sala ruim", "palestra", "sala-x", 10, `[{"inicio":"2026-10-19T09:00:00-03:00","fim":"2026-10-19T10:00:00-03:00"}]`)), http.StatusUnprocessableEntity, "DADOS_INVALIDOS")
		erro(t, executar(handler, http.MethodPost, "/atividades", "org-ana", atividadeValida("Capacidade", "palestra", "lab-3", 21, `[{"inicio":"2026-10-19T09:00:00-03:00","fim":"2026-10-19T10:00:00-03:00"}]`)), http.StatusUnprocessableEntity, "VAGAS_ACIMA_DA_CAPACIDADE")
		erro(t, executar(handler, http.MethodPost, "/atividades", "org-ana", atividadeValida("Zero", "palestra", "lab-3", 0, `[{"inicio":"2026-10-19T09:00:00-03:00","fim":"2026-10-19T10:00:00-03:00"}]`)), http.StatusUnprocessableEntity, "DADOS_INVALIDOS")
		criarAtividadeTeste(t, handler, atividadeValida("Base", "palestra", "sala-101", 10, `[{"inicio":"2026-10-19T09:00:00-03:00","fim":"2026-10-19T10:00:00-03:00"}]`))
		erro(t, executar(handler, http.MethodPost, "/atividades", "org-ana", atividadeValida("Sobreposta", "palestra", "sala-101", 10, `[{"inicio":"2026-10-19T09:30:00-03:00","fim":"2026-10-19T10:30:00-03:00"}]`)), http.StatusConflict, "CONFLITO_DE_SALA")
		erro(t, executar(handler, http.MethodPost, "/atividades", "org-ana", atividadeValida("Intervalo 14", "palestra", "sala-101", 10, `[{"inicio":"2026-10-19T10:14:00-03:00","fim":"2026-10-19T11:14:00-03:00"}]`)), http.StatusConflict, "CONFLITO_DE_SALA")
		criarAtividadeTeste(t, handler, atividadeValida("Intervalo 15", "palestra", "sala-101", 10, `[{"inicio":"2026-10-19T10:15:00-03:00","fim":"2026-10-19T11:15:00-03:00"}]`))
	})
}

func TestM1Fatias2a8ConsultasEdicaoCancelamentoListagemFiltrosReset(t *testing.T) {
	store := NewStore()
	handler := newServer(true, store)

	t.Run("GET /salas retorna salas iniciais com capacidades", func(t *testing.T) {
		executar(handler, http.MethodPost, "/_teste/reset", "", "")
		erro(t, executar(handler, http.MethodGet, "/salas", "nao-existe", ""), http.StatusUnauthorized, "USUARIO_DESCONHECIDO")
		rec := executar(handler, http.MethodGet, "/salas", "p-carla", "")
		if rec.Code != http.StatusOK {
			t.Fatalf("esperava 200, recebeu %d", rec.Code)
		}
		lista := decodificarLista(t, rec)
		if len(lista) != 4 {
			t.Fatalf("esperava 4 salas, recebeu %d", len(lista))
		}
		caps := map[string]float64{}
		for _, sala := range lista {
			caps[sala["id"].(string)] = sala["capacidade"].(float64)
		}
		if caps["auditorio"] != 200 || caps["sala-101"] != 40 || caps["sala-102"] != 40 || caps["lab-3"] != 20 {
			t.Fatalf("capacidades incorretas: %#v", caps)
		}
	})

	t.Run("GET /atividades/:id retorna atividade existente e 404 para inexistente", func(t *testing.T) {
		executar(handler, http.MethodPost, "/_teste/reset", "", "")
		criada := criarAtividadeTeste(t, handler, palestraPadrao("Detalhe"))
		erro(t, executar(handler, http.MethodGet, "/atividades/"+criada["id"].(string), "nao-existe", ""), http.StatusUnauthorized, "USUARIO_DESCONHECIDO")
		rec := executar(handler, http.MethodGet, "/atividades/"+criada["id"].(string), "p-carla", "")
		if rec.Code != http.StatusOK {
			t.Fatalf("esperava 200, recebeu %d", rec.Code)
		}
		resp := decodificar(t, rec)
		if len(resp) != 11 {
			t.Fatalf("atividade deveria retornar exatamente 11 campos, recebeu %d em %#v", len(resp), resp)
		}
		for _, campo := range []string{"id", "titulo", "tipo", "salaId", "vagas", "encontros", "cargaHorariaMinutos", "situacao", "ocupadas", "vagasRestantes", "emEspera"} {
			if _, ok := resp[campo]; !ok {
				t.Fatalf("campo %s ausente em %#v", campo, resp)
			}
		}
		erro(t, executar(handler, http.MethodGet, "/atividades/atv_naoexiste", "p-carla", ""), http.StatusNotFound, "NAO_ENCONTRADO")
	})

	t.Run("PATCH edita apenas titulo e vagas e valida permissoes campos e capacidade", func(t *testing.T) {
		executar(handler, http.MethodPost, "/_teste/reset", "", "")
		criada := criarAtividadeTeste(t, handler, palestraPadrao("Original"))
		id := criada["id"].(string)
		erro(t, executar(handler, http.MethodPatch, "/atividades/"+id, "p-carla", `{"titulo":"X"}`), http.StatusForbidden, "SOMENTE_ORGANIZACAO")
		erro(t, executar(handler, http.MethodPatch, "/atividades/atv_naoexiste", "org-ana", `{"titulo":"X"}`), http.StatusNotFound, "NAO_ENCONTRADO")
		rec := executar(handler, http.MethodPatch, "/atividades/"+id, "org-ana", `{"titulo":"Novo titulo","vagas":25,"cargaHorariaMinutos":1}`)
		if rec.Code != http.StatusOK {
			t.Fatalf("esperava 200, recebeu %d: %s", rec.Code, rec.Body.String())
		}
		resp := decodificar(t, rec)
		if resp["titulo"] != "Novo titulo" || resp["vagas"] != float64(25) || resp["cargaHorariaMinutos"] != float64(120) {
			t.Fatalf("patch nao alterou apenas campos permitidos: %#v", resp)
		}
		for _, campo := range []string{"salaId", "tipo", "encontros"} {
			erro(t, executar(handler, http.MethodPatch, "/atividades/"+id, "org-ana", `{"`+campo+`":"x"}`), http.StatusUnprocessableEntity, "CAMPO_NAO_EDITAVEL")
		}
		erro(t, executar(handler, http.MethodPatch, "/atividades/"+id, "org-ana", `{"vagas":41}`), http.StatusUnprocessableEntity, "VAGAS_ACIMA_DA_CAPACIDADE")
		erro(t, executar(handler, http.MethodPatch, "/atividades/"+id, "org-ana", `{"vagas":0}`), http.StatusUnprocessableEntity, "DADOS_INVALIDOS")
	})

	t.Run("PATCH nao reduz vagas abaixo de confirmadas e convocadas", func(t *testing.T) {
		executar(handler, http.MethodPost, "/_teste/reset", "", "")
		criada := criarAtividadeTeste(t, handler, palestraPadrao("Inscritos"))
		id := criada["id"].(string)
		store.mu.Lock()
		store.Inscricoes = map[string]Inscricao{
			"ins_1": {ID: "ins_1", AtividadeID: id, Status: "confirmada"},
			"ins_2": {ID: "ins_2", AtividadeID: id, Status: "convocada"},
			"ins_3": {ID: "ins_3", AtividadeID: id, Status: "em_espera"},
			"ins_4": {ID: "ins_4", AtividadeID: id, Status: "cancelada"},
			"ins_5": {ID: "ins_5", AtividadeID: id, Status: "expirada"},
		}
		store.mu.Unlock()
		erro(t, executar(handler, http.MethodPatch, "/atividades/"+id, "org-ana", `{"vagas":1}`), http.StatusConflict, "VAGAS_ABAIXO_DOS_INSCRITOS")
		rec := executar(handler, http.MethodPatch, "/atividades/"+id, "org-ana", `{"vagas":2}`)
		if rec.Code != http.StatusOK {
			t.Fatalf("esperava permitir vagas igual a ocupadas, recebeu %d", rec.Code)
		}
		resp := decodificar(t, rec)
		if resp["ocupadas"] != float64(2) || resp["emEspera"] != float64(1) || resp["vagasRestantes"] != float64(0) {
			t.Fatalf("ocupacao calculada incorretamente: %#v", resp)
		}
	})

	t.Run("cancelamento respeita tempo e e definitivo", func(t *testing.T) {
		executar(handler, http.MethodPost, "/_teste/reset", "", "")
		criada := criarAtividadeTeste(t, handler, palestraPadrao("Cancelar"))
		id := criada["id"].(string)
		erro(t, executar(handler, http.MethodPost, "/atividades/"+id+"/cancelamento", "nao-existe", `{}`), http.StatusUnauthorized, "USUARIO_DESCONHECIDO")
		erro(t, executar(handler, http.MethodPost, "/atividades/"+id+"/cancelamento", "p-carla", `{}`), http.StatusForbidden, "SOMENTE_ORGANIZACAO")
		erro(t, executar(handler, http.MethodPost, "/atividades/atv_naoexiste/cancelamento", "org-ana", `{}`), http.StatusNotFound, "NAO_ENCONTRADO")
		rec := executar(handler, http.MethodPost, "/atividades/"+id+"/cancelamento", "org-ana", `{}`)
		if rec.Code != http.StatusOK {
			t.Fatalf("esperava 200, recebeu %d", rec.Code)
		}
		if decodificar(t, rec)["situacao"] != "cancelada" {
			t.Fatalf("cancelamento deveria retornar situacao cancelada")
		}
		erro(t, executar(handler, http.MethodPost, "/atividades/"+id+"/cancelamento", "org-ana", `{}`), http.StatusUnprocessableEntity, "ATIVIDADE_CANCELADA")
		erro(t, executar(handler, http.MethodPatch, "/atividades/"+id, "org-ana", `{"titulo":"X"}`), http.StatusUnprocessableEntity, "ATIVIDADE_CANCELADA")
		criarAtividadeTeste(t, handler, palestraPadrao("Mesmo horario de cancelada"))

		executar(handler, http.MethodPost, "/_teste/reset", "", "")
		iniciada := criarAtividadeTeste(t, handler, palestraPadrao("Ja iniciou"))
		executar(handler, http.MethodPut, "/_teste/relogio", "", `{"agora":"2026-10-19T09:00:00-03:00"}`)
		erro(t, executar(handler, http.MethodPost, "/atividades/"+iniciada["id"].(string)+"/cancelamento", "org-ana", `{}`), http.StatusUnprocessableEntity, "ATIVIDADE_JA_INICIADA")
		executar(handler, http.MethodPut, "/_teste/relogio", "", `{"agora":"2026-10-19T09:00:01-03:00"}`)
		erro(t, executar(handler, http.MethodPost, "/atividades/"+iniciada["id"].(string)+"/cancelamento", "org-ana", `{}`), http.StatusUnprocessableEntity, "ATIVIDADE_JA_INICIADA")
	})

	t.Run("situacao e calculada pelo relogio e cancelada prevalece", func(t *testing.T) {
		executar(handler, http.MethodPost, "/_teste/reset", "", "")
		corpo := atividadeValida("Tempo", "minicurso", "sala-101", 10, `[{"inicio":"2026-10-19T09:00:00-03:00","fim":"2026-10-19T10:00:00-03:00"},{"inicio":"2026-10-20T09:00:00-03:00","fim":"2026-10-20T10:00:00-03:00"}]`)
		criada := criarAtividadeTeste(t, handler, corpo)
		id := criada["id"].(string)
		casos := []struct{ agora, situacao string }{{"2026-10-19T08:59:59-03:00", "prevista"}, {"2026-10-19T09:00:00-03:00", "em_andamento"}, {"2026-10-19T10:30:00-03:00", "em_andamento"}, {"2026-10-20T10:00:00-03:00", "encerrada"}, {"2026-10-20T10:00:01-03:00", "encerrada"}}
		for _, caso := range casos {
			executar(handler, http.MethodPut, "/_teste/relogio", "", `{"agora":"`+caso.agora+`"}`)
			rec := executar(handler, http.MethodGet, "/atividades/"+id, "p-carla", "")
			resp := decodificar(t, rec)
			if resp["situacao"] != caso.situacao {
				t.Fatalf("em %s esperava %s, recebeu %v", caso.agora, caso.situacao, resp["situacao"])
			}
		}
		executar(handler, http.MethodPut, "/_teste/relogio", "", `{"agora":"2026-10-13T09:00:00-03:00"}`)
		executar(handler, http.MethodPost, "/atividades/"+id+"/cancelamento", "org-ana", `{}`)
		executar(handler, http.MethodPut, "/_teste/relogio", "", `{"agora":"2026-10-20T10:00:01-03:00"}`)
		if decodificar(t, executar(handler, http.MethodGet, "/atividades/"+id, "p-carla", ""))["situacao"] != "cancelada" {
			t.Fatalf("cancelada deveria prevalecer")
		}
	})

	t.Run("GET /atividades lista vazio ordena inclui canceladas e filtra", func(t *testing.T) {
		executar(handler, http.MethodPost, "/_teste/reset", "", "")
		recVazio := executar(handler, http.MethodGet, "/atividades", "p-carla", "")
		if recVazio.Code != http.StatusOK || len(decodificarLista(t, recVazio)) != 0 {
			t.Fatalf("lista inicial deveria ser vazia")
		}
		b := criarAtividadeTeste(t, handler, atividadeValida("Beta", "palestra", "sala-101", 10, `[{"inicio":"2026-10-20T09:00:00-03:00","fim":"2026-10-20T10:00:00-03:00"}]`))
		criarAtividadeTeste(t, handler, atividadeValida("Alfa", "palestra", "sala-102", 10, `[{"inicio":"2026-10-20T09:00:00-03:00","fim":"2026-10-20T10:00:00-03:00"}]`))
		criarAtividadeTeste(t, handler, atividadeValida("Antes", "minicurso", "lab-3", 10, `[{"inicio":"2026-10-19T21:30:00-03:00","fim":"2026-10-19T22:30:00-03:00"},{"inicio":"2026-10-21T09:00:00-03:00","fim":"2026-10-21T10:00:00-03:00"}]`))
		executar(handler, http.MethodPost, "/atividades/"+b["id"].(string)+"/cancelamento", "org-ana", `{}`)
		lista := decodificarLista(t, executar(handler, http.MethodGet, "/atividades", "p-carla", ""))
		titulos := []string{lista[0]["titulo"].(string), lista[1]["titulo"].(string), lista[2]["titulo"].(string)}
		if strings.Join(titulos, ",") != "Antes,Alfa,Beta" {
			t.Fatalf("ordem incorreta: %v", titulos)
		}
		if lista[2]["situacao"] != "cancelada" {
			t.Fatalf("canceladas devem aparecer com situacao cancelada")
		}
		if len(decodificarLista(t, executar(handler, http.MethodGet, "/atividades?tipo=palestra", "p-carla", ""))) != 2 {
			t.Fatalf("filtro tipo palestra deveria retornar 2")
		}
		if len(decodificarLista(t, executar(handler, http.MethodGet, "/atividades?dia=2026-10-21", "p-carla", ""))) != 1 {
			t.Fatalf("filtro dia deveria considerar qualquer encontro no dia de Brasilia")
		}
		if len(decodificarLista(t, executar(handler, http.MethodGet, "/atividades?dia=2026-10-19&tipo=minicurso", "p-carla", ""))) != 1 {
			t.Fatalf("filtro combinado deveria aplicar dia e tipo")
		}
		if len(decodificarLista(t, executar(handler, http.MethodGet, "/atividades?dia=2026-10-18", "p-carla", ""))) != 0 {
			t.Fatalf("dia UTC diferente nao deve ser usado no filtro")
		}
	})

	t.Run("reset restaura relogio usuarios salas e remove atividades", func(t *testing.T) {
		executar(handler, http.MethodPost, "/_teste/reset", "", "")
		criarAtividadeTeste(t, handler, palestraPadrao("Sera removida"))
		executar(handler, http.MethodPut, "/_teste/relogio", "", `{"agora":"2026-10-19T09:00:00-03:00"}`)
		rec := executar(handler, http.MethodPost, "/_teste/reset", "", "")
		if rec.Code != http.StatusNoContent {
			t.Fatalf("esperava 204, recebeu %d", rec.Code)
		}
		if decodificar(t, executar(handler, http.MethodGet, "/_teste/relogio", "", ""))["agora"] != "2026-10-13T09:00:00-03:00" {
			t.Fatalf("reset deveria restaurar relogio")
		}
		if len(decodificarLista(t, executar(handler, http.MethodGet, "/salas", "org-ana", ""))) != 4 {
			t.Fatalf("reset deveria restaurar salas")
		}
		if len(decodificarLista(t, executar(handler, http.MethodGet, "/atividades", "org-ana", ""))) != 0 {
			t.Fatalf("reset deveria remover atividades")
		}
	})
}
