package main

import (
	"errors"
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestReadACMECertificate(t *testing.T) {
	const host = "example.com"
	tests := []struct {
		name     string
		files    map[string]string
		wantCert string
		wantKey  string
		missing  string
	}{
		{name: "original pair", files: map[string]string{host + "/fullchain.cer": "original cert", host + "/" + host + ".key": "original key"}, wantCert: "original cert", wantKey: "original key"},
		{name: "ECC pair", files: map[string]string{host + "_ecc/fullchain.cer": "ECC cert", host + "_ecc/" + host + ".key": "ECC key"}, wantCert: "ECC cert", wantKey: "ECC key"},
		{name: "original wins", files: map[string]string{host + "/fullchain.cer": "original cert", host + "/" + host + ".key": "original key", host + "_ecc/fullchain.cer": "ECC cert", host + "_ecc/" + host + ".key": "ECC key"}, wantCert: "original cert", wantKey: "original key"},
		{name: "missing original key", files: map[string]string{host + "/fullchain.cer": "original cert", host + "_ecc/fullchain.cer": "ECC cert", host + "_ecc/" + host + ".key": "ECC key"}, wantCert: "ECC cert", wantKey: "ECC key"},
		{name: "missing original cert", files: map[string]string{host + "/" + host + ".key": "original key", host + "_ecc/fullchain.cer": "ECC cert", host + "_ecc/" + host + ".key": "ECC key"}, wantCert: "ECC cert", wantKey: "ECC key"},
		{name: "no pair", missing: host + "_ecc/fullchain.cer"},
		{name: "do not mix directories", files: map[string]string{host + "/fullchain.cer": "original cert", host + "_ecc/" + host + ".key": "ECC key"}, missing: host + "_ecc/fullchain.cer"},
		{name: "missing ECC key", files: map[string]string{host + "_ecc/fullchain.cer": "ECC cert"}, missing: host + "_ecc/" + host + ".key"},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			home := t.TempDir()
			for relativePath, data := range tt.files {
				path := filepath.Join(home, ".acme.sh", relativePath)
				if err := os.MkdirAll(filepath.Dir(path), 0700); err != nil {
					t.Fatal(err)
				}
				if err := os.WriteFile(path, []byte(data), 0600); err != nil {
					t.Fatal(err)
				}
			}
			certificate, err := readACMECertificate(home, host)
			if tt.missing != "" {
				if !errors.Is(err, os.ErrNotExist) || !strings.Contains(err.Error(), filepath.FromSlash(tt.missing)) {
					t.Fatalf("want missing %s, got %v", tt.missing, err)
				}
				return
			}
			if err != nil {
				t.Fatal(err)
			}
			if string(certificate.Certificate) != tt.wantCert || string(certificate.Key) != tt.wantKey {
				t.Fatalf("unexpected pair: cert=%q key=%q", certificate.Certificate, certificate.Key)
			}
		})
	}
}

func TestReadACMECertificateStopsOnReadError(t *testing.T) {
	const host = "example.com"
	for _, unreadable := range []string{"fullchain.cer", host + ".key"} {
		t.Run(unreadable, func(t *testing.T) {
			home := t.TempDir()
			for _, domainDir := range []string{host, host + "_ecc"} {
				dir := filepath.Join(home, ".acme.sh", domainDir)
				if err := os.MkdirAll(dir, 0700); err != nil {
					t.Fatal(err)
				}
				for _, name := range []string{"fullchain.cer", host + ".key"} {
					path := filepath.Join(dir, name)
					if domainDir == host && name == unreadable {
						// Reading a directory fails without relying on process permissions.
						if err := os.Mkdir(path, 0700); err != nil {
							t.Fatal(err)
						}
					} else if err := os.WriteFile(path, []byte("data"), 0600); err != nil {
						t.Fatal(err)
					}
				}
			}
			_, err := readACMECertificate(home, host)
			if err == nil || errors.Is(err, os.ErrNotExist) || !strings.Contains(err.Error(), filepath.Join(host, unreadable)) {
				t.Fatalf("want original read error, got %v", err)
			}
		})
	}
}
