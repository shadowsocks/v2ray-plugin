package main

import (
	"bytes"
	"crypto/sha256"
	"encoding/pem"
	"testing"
)

func TestCalculatePEMCertChainHash(t *testing.T) {
	leaf := []byte("leaf certificate")
	issuer := []byte("issuer certificate")
	pemChain := bytes.Join([][]byte{
		pem.EncodeToMemory(&pem.Block{Type: "CERTIFICATE", Bytes: leaf}),
		pem.EncodeToMemory(&pem.Block{Type: "CERTIFICATE", Bytes: issuer}),
	}, nil)

	hash, err := calculatePEMCertChainHash(pemChain)
	if err != nil {
		t.Fatal(err)
	}

	leafHash := sha256.Sum256(leaf)
	issuerHash := sha256.Sum256(issuer)
	expected := sha256.Sum256(append(leafHash[:], issuerHash[:]...))
	if !bytes.Equal(hash, expected[:]) {
		t.Fatalf("unexpected hash: got %x, want %x", hash, expected)
	}
}

func TestCalculatePEMCertChainHashRejectsInvalidPEM(t *testing.T) {
	if _, err := calculatePEMCertChainHash([]byte("not a certificate")); err == nil {
		t.Fatal("expected invalid PEM to fail")
	}
}
