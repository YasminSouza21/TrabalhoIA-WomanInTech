package main

import (
	"crypto/rand"
	"encoding/hex"
	"encoding/json"
	"io"
	"net/http"
	"sort"
	"strings"
	"time"
)

type erroAPI struct {
	Erro     string `json:"erro"`
	Mensagem string `json:"mensagem"`
}

type encontroEntrada struct {
	Inicio string `json:"inicio"`
	Fim    string `json:"fim"`
}

type atividadeEntrada struct {
	Titulo    *string            `json:"titulo"`
	Tipo      *string            `json:"tipo"`
	SalaID    *string            `json:"salaId"`
	Vagas     *int               `json:"vagas"`
	Encontros *[]encontroEntrada `json:"encontros"`
}

type encontroResposta struct {
	ID     string `json:"id"`
	Inicio string `json:"inicio"`
	Fim    string `json:"fim"`
}

type atividadeResposta struct {
	ID                  string             `json:"id"`
	Titulo              string             `json:"titulo"`
	Tipo                string             `json:"tipo"`
	SalaID              string             `json:"salaId"`
	Vagas               int                `json:"vagas"`
	Encontros           []encontroResposta `json:"encontros"`
	CargaHorariaMinutos int                `json:"cargaHorariaMinutos"`
	Situacao            string             `json:"situacao"`
	Ocupadas            int                `json:"ocupadas"`
	VagasRestantes      int                `json:"vagasRestantes"`
	EmEspera            int                `json:"emEspera"`
}

func handleAtividades(s *Store) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Path != "/atividades" {
			http.NotFound(w, r)
			return
		}
		switch r.Method {
		case http.MethodPost:
			criarAtividade(w, r, s)
		case http.MethodGet:
			listarAtividades(w, r, s)
		default:
			http.Error(w, "Metodo nao permitido", http.StatusMethodNotAllowed)
		}
	}
}

func handleAtividadePorID(s *Store) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		path := strings.TrimPrefix(r.URL.Path, "/atividades/")
		if path == "" || path == r.URL.Path {
			http.NotFound(w, r)
			return
		}
		partes := strings.Split(strings.Trim(path, "/"), "/")
		if len(partes) == 2 && partes[1] == "cancelamento" && r.Method == http.MethodPost {
			cancelarAtividade(w, r, s, partes[0])
			return
		}
		if len(partes) != 1 {
			http.NotFound(w, r)
			return
		}
		switch r.Method {
		case http.MethodGet:
			obterAtividade(w, r, s, partes[0])
		case http.MethodPatch:
			editarAtividade(w, r, s, partes[0])
		default:
			http.Error(w, "Metodo nao permitido", http.StatusMethodNotAllowed)
		}
	}
}

func handleSalas(s *Store) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Path != "/salas" {
			http.NotFound(w, r)
			return
		}
		if r.Method != http.MethodGet {
			http.Error(w, "Metodo nao permitido", http.StatusMethodNotAllowed)
			return
		}
		if !autorizar(w, r, s, "") {
			return
		}
		s.mu.RLock()
		salas := make([]Sala, 0, len(s.Salas))
		for _, sala := range s.Salas {
			salas = append(salas, sala)
		}
		s.mu.RUnlock()
		sort.Slice(salas, func(i, j int) bool { return salas[i].ID < salas[j].ID })
		responderJSON(w, http.StatusOK, salas)
	}
}

func criarAtividade(w http.ResponseWriter, r *http.Request, s *Store) {
	if !autorizar(w, r, s, "organizacao") {
		return
	}
	var entrada atividadeEntrada
	dec := json.NewDecoder(r.Body)
	if err := dec.Decode(&entrada); err != nil || entrada.Titulo == nil || entrada.Tipo == nil || entrada.SalaID == nil || entrada.Vagas == nil || entrada.Encontros == nil {
		responderErro(w, http.StatusUnprocessableEntity, "DADOS_INVALIDOS")
		return
	}
	var extra any
	if err := dec.Decode(&extra); err != io.EOF {
		responderErro(w, http.StatusUnprocessableEntity, "DADOS_INVALIDOS")
		return
	}

	encontros, ok := montarEncontros(*entrada.Encontros, true)
	if !ok {
		responderErro(w, http.StatusUnprocessableEntity, "DADOS_INVALIDOS")
		return
	}
	atv := Atividade{ID: novoID("atv_"), Titulo: *entrada.Titulo, Tipo: *entrada.Tipo, SalaID: *entrada.SalaID, Vagas: *entrada.Vagas, Encontros: encontros}
	if err := validarCriacao(s, atv); err != "" {
		status := http.StatusUnprocessableEntity
		if err == "CONFLITO_DE_SALA" {
			status = http.StatusConflict
		}
		responderErro(w, status, err)
		return
	}

	s.mu.Lock()
	s.Atividades[atv.ID] = atv
	agora := s.Relogio
	ocupadas, espera := ocupacao(s, atv.ID)
	s.mu.Unlock()
	responderJSON(w, http.StatusCreated, montarResposta(atv, agora, ocupadas, espera))
}

func validarCriacao(s *Store, atv Atividade) string {
	if atv.Tipo != "palestra" && atv.Tipo != "minicurso" {
		return "DADOS_INVALIDOS"
	}
	if atv.Tipo == "palestra" && len(atv.Encontros) != 1 {
		return "QUANTIDADE_DE_ENCONTROS"
	}
	if atv.Tipo == "minicurso" && (len(atv.Encontros) < 2 || len(atv.Encontros) > 5) {
		return "QUANTIDADE_DE_ENCONTROS"
	}
	if !validarEncontros(atv.Encontros) {
		return "ENCONTRO_INVALIDO"
	}
	s.mu.RLock()
	sala, salaExiste := s.Salas[atv.SalaID]
	if !salaExiste {
		s.mu.RUnlock()
		return "DADOS_INVALIDOS"
	}
	if atv.Vagas < 1 {
		s.mu.RUnlock()
		return "DADOS_INVALIDOS"
	}
	if atv.Vagas > sala.Capacidade {
		s.mu.RUnlock()
		return "VAGAS_ACIMA_DA_CAPACIDADE"
	}
	conflito := temConflitoDeSala(s.Atividades, atv)
	s.mu.RUnlock()
	if conflito {
		return "CONFLITO_DE_SALA"
	}
	return ""
}

func montarEncontros(entradas []encontroEntrada, gerarID bool) ([]Encontro, bool) {
	encontros := make([]Encontro, 0, len(entradas))
	for _, entrada := range entradas {
		inicio, errInicio := time.Parse(time.RFC3339, entrada.Inicio)
		fim, errFim := time.Parse(time.RFC3339, entrada.Fim)
		if errInicio != nil || errFim != nil {
			return nil, false
		}
		id := ""
		if gerarID {
			id = novoID("enc_")
		}
		encontros = append(encontros, Encontro{ID: id, Inicio: inicio, Fim: fim})
	}
	sort.Slice(encontros, func(i, j int) bool { return encontros[i].Inicio.Before(encontros[j].Inicio) })
	return encontros, true
}

func validarEncontros(encontros []Encontro) bool {
	loc := brasilia()
	for i, enc := range encontros {
		inicioBR := enc.Inicio.In(loc)
		fimBR := enc.Fim.In(loc)
		if !mesmoDia(inicioBR, fimBR) {
			return false
		}
		if inicioBR.Year() != 2026 || inicioBR.Month() != time.October || inicioBR.Day() < 19 || inicioBR.Day() > 23 {
			return false
		}
		if fimBR.Year() != 2026 || fimBR.Month() != time.October || fimBR.Day() < 19 || fimBR.Day() > 23 {
			return false
		}
		duracao := enc.Fim.Sub(enc.Inicio)
		if duracao < time.Hour || duracao > 4*time.Hour {
			return false
		}
		if i > 0 && encontros[i-1].Fim.After(enc.Inicio) {
			return false
		}
	}
	return true
}

func temConflitoDeSala(atividades map[string]Atividade, nova Atividade) bool {
	for _, existente := range atividades {
		if existente.Cancelada || existente.SalaID != nova.SalaID || existente.ID == nova.ID {
			continue
		}
		for _, a := range existente.Encontros {
			for _, b := range nova.Encontros {
				if encontrosConflitam(a, b) {
					return true
				}
			}
		}
	}
	return false
}

func encontrosConflitam(a, b Encontro) bool {
	if a.Inicio.Before(b.Fim) && b.Inicio.Before(a.Fim) {
		return true
	}
	if !a.Fim.After(b.Inicio) && b.Inicio.Sub(a.Fim) < 15*time.Minute {
		return true
	}
	if !b.Fim.After(a.Inicio) && a.Inicio.Sub(b.Fim) < 15*time.Minute {
		return true
	}
	return false
}

func montarResposta(atv Atividade, agora time.Time, ocupadas, espera int) atividadeResposta {
	encontros := append([]Encontro(nil), atv.Encontros...)
	sort.Slice(encontros, func(i, j int) bool { return encontros[i].Inicio.Before(encontros[j].Inicio) })
	respEncontros := make([]encontroResposta, 0, len(encontros))
	carga := 0
	for _, enc := range encontros {
		respEncontros = append(respEncontros, encontroResposta{ID: enc.ID, Inicio: enc.Inicio.Format(time.RFC3339), Fim: enc.Fim.Format(time.RFC3339)})
		carga += int(enc.Fim.Sub(enc.Inicio).Minutes())
	}
	return atividadeResposta{ID: atv.ID, Titulo: atv.Titulo, Tipo: atv.Tipo, SalaID: atv.SalaID, Vagas: atv.Vagas, Encontros: respEncontros, CargaHorariaMinutos: carga, Situacao: situacao(atv, agora), Ocupadas: ocupadas, VagasRestantes: atv.Vagas - ocupadas, EmEspera: espera}
}

func situacao(atv Atividade, agora time.Time) string {
	if atv.Cancelada {
		return "cancelada"
	}
	encontros := append([]Encontro(nil), atv.Encontros...)
	sort.Slice(encontros, func(i, j int) bool { return encontros[i].Inicio.Before(encontros[j].Inicio) })
	if len(encontros) == 0 || agora.Before(encontros[0].Inicio) {
		return "prevista"
	}
	ultimoFim := encontros[len(encontros)-1].Fim
	if !agora.Before(ultimoFim) {
		return "encerrada"
	}
	return "em_andamento"
}

func ocupacao(s *Store, atividadeID string) (int, int) {
	ocupadas := 0
	espera := 0
	for _, ins := range s.Inscricoes {
		if ins.AtividadeID != atividadeID {
			continue
		}
		switch ins.Status {
		case "confirmada", "convocada":
			ocupadas++
		case "em_espera":
			espera++
		}
	}
	return ocupadas, espera
}

func autorizar(w http.ResponseWriter, r *http.Request, s *Store, papel string) bool {
	usuarioID := r.Header.Get("X-Usuario")
	s.mu.RLock()
	usuario, ok := s.Usuarios[usuarioID]
	s.mu.RUnlock()
	if usuarioID == "" || !ok {
		responderErro(w, http.StatusUnauthorized, "USUARIO_DESCONHECIDO")
		return false
	}
	if papel != "" && usuario.Papel != papel {
		responderErro(w, http.StatusForbidden, "SOMENTE_ORGANIZACAO")
		return false
	}
	return true
}

func responderJSON(w http.ResponseWriter, status int, v any) {
	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	w.WriteHeader(status)
	json.NewEncoder(w).Encode(v)
}

func responderErro(w http.ResponseWriter, status int, codigo string) {
	responderJSON(w, status, erroAPI{Erro: codigo, Mensagem: codigo})
}

func novoID(prefixo string) string {
	b := make([]byte, 4)
	if _, err := rand.Read(b); err != nil {
		return prefixo + "00000000"
	}
	return prefixo + hex.EncodeToString(b)
}

func brasilia() *time.Location {
	loc, err := time.LoadLocation("America/Sao_Paulo")
	if err != nil {
		return time.FixedZone("BRT", -3*60*60)
	}
	return loc
}

func mesmoDia(a, b time.Time) bool {
	ay, am, ad := a.Date()
	by, bm, bd := b.Date()
	return ay == by && am == bm && ad == bd
}

func listarAtividades(w http.ResponseWriter, r *http.Request, s *Store) {
	if !autorizar(w, r, s, "") {
		return
	}
	tipo := r.URL.Query().Get("tipo")
	dia := r.URL.Query().Get("dia")
	s.mu.RLock()
	agora := s.Relogio
	atividades := make([]Atividade, 0, len(s.Atividades))
	for _, atv := range s.Atividades {
		if tipo != "" && atv.Tipo != tipo {
			continue
		}
		if dia != "" && !atividadeTemEncontroNoDia(atv, dia) {
			continue
		}
		atividades = append(atividades, atv)
	}
	sort.Slice(atividades, func(i, j int) bool {
		iniI := primeiroInicio(atividades[i])
		iniJ := primeiroInicio(atividades[j])
		if iniI.Equal(iniJ) {
			return atividades[i].Titulo < atividades[j].Titulo
		}
		return iniI.Before(iniJ)
	})
	respostas := make([]atividadeResposta, 0, len(atividades))
	for _, atv := range atividades {
		ocupadas, espera := ocupacao(s, atv.ID)
		respostas = append(respostas, montarResposta(atv, agora, ocupadas, espera))
	}
	s.mu.RUnlock()
	responderJSON(w, http.StatusOK, respostas)
}

func obterAtividade(w http.ResponseWriter, r *http.Request, s *Store, id string) {
	if !autorizar(w, r, s, "") {
		return
	}
	s.mu.RLock()
	atv, ok := s.Atividades[id]
	if !ok {
		s.mu.RUnlock()
		responderErro(w, http.StatusNotFound, "NAO_ENCONTRADO")
		return
	}
	agora := s.Relogio
	ocupadas, espera := ocupacao(s, id)
	s.mu.RUnlock()
	responderJSON(w, http.StatusOK, montarResposta(atv, agora, ocupadas, espera))
}

func editarAtividade(w http.ResponseWriter, r *http.Request, s *Store, id string) {
	if !autorizar(w, r, s, "organizacao") {
		return
	}
	s.mu.RLock()
	atv, ok := s.Atividades[id]
	s.mu.RUnlock()
	if !ok {
		responderErro(w, http.StatusNotFound, "NAO_ENCONTRADO")
		return
	}

	var bruto map[string]json.RawMessage
	dec := json.NewDecoder(r.Body)
	if err := dec.Decode(&bruto); err != nil {
		responderErro(w, http.StatusUnprocessableEntity, "DADOS_INVALIDOS")
		return
	}
	var extra any
	if err := dec.Decode(&extra); err != io.EOF {
		responderErro(w, http.StatusUnprocessableEntity, "DADOS_INVALIDOS")
		return
	}
	if _, ok := bruto["salaId"]; ok {
		responderErro(w, http.StatusUnprocessableEntity, "CAMPO_NAO_EDITAVEL")
		return
	}
	if _, ok := bruto["tipo"]; ok {
		responderErro(w, http.StatusUnprocessableEntity, "CAMPO_NAO_EDITAVEL")
		return
	}
	if _, ok := bruto["encontros"]; ok {
		responderErro(w, http.StatusUnprocessableEntity, "CAMPO_NAO_EDITAVEL")
		return
	}
	if atv.Cancelada {
		responderErro(w, http.StatusUnprocessableEntity, "ATIVIDADE_CANCELADA")
		return
	}

	if raw, ok := bruto["titulo"]; ok {
		var titulo string
		if err := json.Unmarshal(raw, &titulo); err != nil {
			responderErro(w, http.StatusUnprocessableEntity, "DADOS_INVALIDOS")
			return
		}
		atv.Titulo = titulo
	}
	if raw, ok := bruto["vagas"]; ok {
		var vagas int
		if err := json.Unmarshal(raw, &vagas); err != nil || vagas < 1 {
			responderErro(w, http.StatusUnprocessableEntity, "DADOS_INVALIDOS")
			return
		}
		s.mu.RLock()
		sala := s.Salas[atv.SalaID]
		ocupadas, _ := ocupacao(s, id)
		s.mu.RUnlock()
		if vagas > sala.Capacidade {
			responderErro(w, http.StatusUnprocessableEntity, "VAGAS_ACIMA_DA_CAPACIDADE")
			return
		}
		if vagas < ocupadas {
			responderErro(w, http.StatusConflict, "VAGAS_ABAIXO_DOS_INSCRITOS")
			return
		}
		atv.Vagas = vagas
	}

	s.mu.Lock()
	s.Atividades[id] = atv
	agora := s.Relogio
	ocupadas, espera := ocupacao(s, id)
	s.mu.Unlock()
	responderJSON(w, http.StatusOK, montarResposta(atv, agora, ocupadas, espera))
}

func cancelarAtividade(w http.ResponseWriter, r *http.Request, s *Store, id string) {
	if !autorizar(w, r, s, "organizacao") {
		return
	}
	s.mu.Lock()
	atv, ok := s.Atividades[id]
	if !ok {
		s.mu.Unlock()
		responderErro(w, http.StatusNotFound, "NAO_ENCONTRADO")
		return
	}
	if atv.Cancelada {
		s.mu.Unlock()
		responderErro(w, http.StatusUnprocessableEntity, "ATIVIDADE_CANCELADA")
		return
	}
	agora := s.Relogio
	if !agora.Before(primeiroInicio(atv)) {
		s.mu.Unlock()
		responderErro(w, http.StatusUnprocessableEntity, "ATIVIDADE_JA_INICIADA")
		return
	}
	atv.Cancelada = true
	s.Atividades[id] = atv
	ocupadas, espera := ocupacao(s, id)
	s.mu.Unlock()
	responderJSON(w, http.StatusOK, montarResposta(atv, agora, ocupadas, espera))
}

func primeiroInicio(atv Atividade) time.Time {
	if len(atv.Encontros) == 0 {
		return time.Time{}
	}
	primeiro := atv.Encontros[0].Inicio
	for _, enc := range atv.Encontros[1:] {
		if enc.Inicio.Before(primeiro) {
			primeiro = enc.Inicio
		}
	}
	return primeiro
}

func atividadeTemEncontroNoDia(atv Atividade, dia string) bool {
	loc := brasilia()
	for _, enc := range atv.Encontros {
		if enc.Inicio.In(loc).Format("2006-01-02") == dia {
			return true
		}
	}
	return false
}
