package api

import (
	"io"
	"log/slog"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
)

func newTestServer() *Server {
	return New(slog.New(slog.NewTextHandler(io.Discard, nil)), "test")
}

func TestRoutes(t *testing.T) {
	tests := []struct {
		name       string
		method     string
		path       string
		wantStatus int
		wantBody   string
	}{
		{"liveness", http.MethodGet, "/healthz", http.StatusOK, `"ok"`},
		{"readiness", http.MethodGet, "/readyz", http.StatusOK, `"ready"`},
		{"list items", http.MethodGet, "/api/v1/items", http.StatusOK, "stethoscope"},
		{"get item", http.MethodGet, "/api/v1/items/2", http.StatusOK, "thermometer"},
		{"item not found", http.MethodGet, "/api/v1/items/99", http.StatusNotFound, "not found"},
		{"bad id", http.MethodGet, "/api/v1/items/abc", http.StatusBadRequest, "integer"},
		{"version", http.MethodGet, "/version", http.StatusOK, "test"},
		{"metrics", http.MethodGet, "/metrics", http.StatusOK, "http_requests_total"},
		{"wrong method", http.MethodPost, "/api/v1/items", http.StatusMethodNotAllowed, ""},
		{"unknown path", http.MethodGet, "/nope", http.StatusNotFound, ""},
	}

	h := newTestServer().Routes()
	for _, tc := range tests {
		t.Run(tc.name, func(t *testing.T) {
			rec := httptest.NewRecorder()
			h.ServeHTTP(rec, httptest.NewRequest(tc.method, tc.path, nil))

			if rec.Code != tc.wantStatus {
				t.Fatalf("status = %d, want %d", rec.Code, tc.wantStatus)
			}
			if tc.wantBody != "" && !strings.Contains(rec.Body.String(), tc.wantBody) {
				t.Fatalf("body %q does not contain %q", rec.Body.String(), tc.wantBody)
			}
		})
	}
}

func TestReadinessFlipsDuringShutdown(t *testing.T) {
	s := newTestServer()
	s.SetReady(false)

	rec := httptest.NewRecorder()
	s.Routes().ServeHTTP(rec, httptest.NewRequest(http.MethodGet, "/readyz", nil))

	if rec.Code != http.StatusServiceUnavailable {
		t.Fatalf("status = %d, want %d", rec.Code, http.StatusServiceUnavailable)
	}
}
