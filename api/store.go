package main

import (
	"sync"
	"time"
)

type Usuario struct {
	ID    string `json:"id"`
	Nome  string `json:"nome"`
	Papel string `json:"papel"`
}

type Sala struct {
	ID         string `json:"id"`
	Nome       string `json:"nome"`
	Capacidade int    `json:"capacidade"`
}

type Store struct {
	mu         sync.RWMutex
	Relogio    time.Time
	Usuarios   map[string]Usuario
	Salas      map[string]Sala
	Atividades map[string]struct{}
}

func NewStore() *Store {
	s := &Store{}
	s.Reset()
	return s
}

func (s *Store) Reset() {
	s.mu.Lock()
	defer s.mu.Unlock()

	loc, _ := time.LoadLocation("America/Sao_Paulo")
	if loc == nil {
		// Fallback if the host does not have tzdata available.
		loc = time.FixedZone("BRT", -3*60*60)
	}
	s.Relogio = time.Date(2026, 10, 13, 9, 0, 0, 0, loc)

	s.Usuarios = map[string]Usuario{
		"org-ana":    {"org-ana", "Ana Beatriz Lima", "organizacao"},
		"org-bruno":  {"org-bruno", "Bruno Tavares", "organizacao"},
		"p-carla":    {"p-carla", "Carla Mendes Souza", "participante"},
		"p-diego":    {"p-diego", "Diego Alves", "participante"},
		"p-elisa":    {"p-elisa", "Elisa Fernandes da Rocha", "participante"},
		"p-fabio":    {"p-fabio", "Fábio Nogueira", "participante"},
		"p-gabriela": {"p-gabriela", "Gabriela Moura Castro", "participante"},
		"p-heitor":   {"p-heitor", "Heitor Campos", "participante"},
		"p-isadora":  {"p-isadora", "Isadora Ribeiro dos Santos", "participante"},
		"p-joao":     {"p-joao", "João Pedro Martins", "participante"},
	}

	s.Salas = map[string]Sala{
		"auditorio": {"auditorio", "Auditório Central", 200},
		"sala-101":  {"sala-101", "Sala 101", 40},
		"sala-102":  {"sala-102", "Sala 102", 40},
		"lab-3":     {"lab-3", "Laboratório 3", 20},
	}

	s.Atividades = map[string]struct{}{}
}

func (s *Store) GetAgora() time.Time {
	s.mu.RLock()
	defer s.mu.RUnlock()
	return s.Relogio
}

func (s *Store) SetRelogio(t time.Time) {
	s.mu.Lock()
	defer s.mu.Unlock()
	s.Relogio = t
}
