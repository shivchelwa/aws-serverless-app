package main

import (
	"fmt"
	"net/http"
	"net/http/httptest"
	"os"
	"testing"
)

func TestCheckCoverage(t *testing.T) {
	t.Run("Non 200 Response", func(t *testing.T) {
		ts := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			w.WriteHeader(500)
		}))
		defer ts.Close()

		os.Setenv("COVERAGE_URL", ts.URL)

		_, err := checkCoverage("{}")
		if err == nil {
			t.Fatalf("checkCoverage should return error if response status code is not 200")
		}
	})

	t.Run("Successful Request", func(t *testing.T) {
		ts := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			w.WriteHeader(200)
			fmt.Fprintf(w, "{\"inforce\": true}")
		}))
		defer ts.Close()

		os.Setenv("COVERAGE_URL", ts.URL)

		result, err := checkCoverage("{}")
		if err != nil {
			t.Fatal("Everything should be ok")
		}
		if !result.Inforce {
			t.Fatal("Inforce should be true")
		}
	})

}
