// Package api implements the HTTP handlers for the items service.
package api

import (
	"encoding/json"
	"fmt"
	"log/slog"
	"net/http"
	"strconv"
	"sync"
	"sync/atomic"
	"time"
)

// Item is the sample resource exposed by the API.
type Item struct {
	ID   int    `json:"id"`
	Name string `json:"name"`
}

// Server holds handler dependencies and in-memory state.
type Server struct {
	logger  *slog.Logger
	version string

	mu    sync.RWMutex
	items []Item

	ready    atomic.Bool
	requests atomic.Uint64
}

// New returns a Server seeded with sample data.
func New(logger *slog.Logger, version string) *Server {
	s := &Server{
		logger:  logger,
		version: version,
		items: []Item{
			{ID: 1, Name: "stethoscope"},
			{ID: 2, Name: "thermometer"},
		},
	}
	s.ready.Store(true)
	return s
}

// SetReady toggles the readiness state (used during graceful shutdown).
func (s *Server) SetReady(v bool) { s.ready.Store(v) }

// Routes registers all handlers on a new ServeMux.
func (s *Server) Routes() http.Handler {
	mux := http.NewServeMux()
	mux.HandleFunc("GET /healthz", s.healthz)
	mux.HandleFunc("GET /readyz", s.readyz)
	mux.HandleFunc("GET /metrics", s.metrics)
	mux.HandleFunc("GET /api/v1/items", s.listItems)
	mux.HandleFunc("GET /api/v1/items/{id}", s.getItem)
	mux.HandleFunc("GET /version", s.versionInfo)
	return s.logRequests(mux)
}

func (s *Server) logRequests(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		start := time.Now()
		s.requests.Add(1)
		next.ServeHTTP(w, r)
		// Probe and metrics traffic is noise in logs.
		switch r.URL.Path {
		case "/healthz", "/readyz", "/metrics":
			return
		}
		s.logger.Info("request",
			"method", r.Method,
			"path", r.URL.Path,
			"duration_ms", time.Since(start).Milliseconds(),
		)
	})
}

// healthz is the liveness check: the process is up and serving.
// It deliberately checks no dependencies, so a downstream outage
// never causes Kubernetes to restart healthy pods.
func (s *Server) healthz(w http.ResponseWriter, _ *http.Request) {
	writeJSON(w, http.StatusOK, map[string]string{"status": "ok"})
}

// readyz is the readiness check: the pod can take traffic.
func (s *Server) readyz(w http.ResponseWriter, _ *http.Request) {
	if !s.ready.Load() {
		writeJSON(w, http.StatusServiceUnavailable, map[string]string{"status": "not ready"})
		return
	}
	writeJSON(w, http.StatusOK, map[string]string{"status": "ready"})
}

// metrics exposes a minimal Prometheus text-format endpoint.
// Hand-rolled to keep the service dependency-free; a real service
// would use prometheus/client_golang.
func (s *Server) metrics(w http.ResponseWriter, _ *http.Request) {
	w.Header().Set("Content-Type", "text/plain; version=0.0.4")
	_, _ = fmt.Fprintf(w,
		"# HELP http_requests_total Total HTTP requests served.\n"+
			"# TYPE http_requests_total counter\n"+
			"http_requests_total %d\n", s.requests.Load())
}

func (s *Server) listItems(w http.ResponseWriter, _ *http.Request) {
	s.mu.RLock()
	defer s.mu.RUnlock()
	writeJSON(w, http.StatusOK, s.items)
}

func (s *Server) getItem(w http.ResponseWriter, r *http.Request) {
	id, err := strconv.Atoi(r.PathValue("id"))
	if err != nil {
		writeJSON(w, http.StatusBadRequest, map[string]string{"error": "id must be an integer"})
		return
	}
	s.mu.RLock()
	defer s.mu.RUnlock()
	for _, it := range s.items {
		if it.ID == id {
			writeJSON(w, http.StatusOK, it)
			return
		}
	}
	writeJSON(w, http.StatusNotFound, map[string]string{"error": "item not found"})
}

func (s *Server) versionInfo(w http.ResponseWriter, _ *http.Request) {
	writeJSON(w, http.StatusOK, map[string]string{"version": s.version})
}

func writeJSON(w http.ResponseWriter, status int, v any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(v)
}
