package main

import (
	"crypto/ecdsa"
	"crypto/elliptic"
	"crypto/rand"
	"crypto/x509"
	"crypto/x509/pkix"
	"encoding/pem"
	"fmt"
	"io"
	"math/big"
	"net"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"testing"
	"time"
)

var testBinary string

func TestMain(m *testing.M) {
	dir, err := os.MkdirTemp("", "v2ray-plugin-tests-")
	if err != nil {
		panic(err)
	}
	testBinary = filepath.Join(dir, "v2ray-plugin")
	cmd := exec.Command("go", "build", "-o", testBinary, ".")
	cmd.Stdout, cmd.Stderr = os.Stdout, os.Stderr
	if err := cmd.Run(); err != nil {
		_ = os.RemoveAll(dir)
		os.Exit(1)
	}
	code := m.Run()
	_ = os.RemoveAll(dir)
	os.Exit(code)
}

func testCertificate(t *testing.T) (string, string) {
	t.Helper()
	key, err := ecdsa.GenerateKey(elliptic.P256(), rand.Reader)
	if err != nil {
		t.Fatal(err)
	}
	template := &x509.Certificate{SerialNumber: big.NewInt(1), Subject: pkix.Name{CommonName: "localhost"}, DNSNames: []string{"localhost"}, NotBefore: time.Now().Add(-time.Hour), NotAfter: time.Now().Add(time.Hour), KeyUsage: x509.KeyUsageDigitalSignature | x509.KeyUsageCertSign, ExtKeyUsage: []x509.ExtKeyUsage{x509.ExtKeyUsageServerAuth}, BasicConstraintsValid: true, IsCA: true}
	der, err := x509.CreateCertificate(rand.Reader, template, template, &key.PublicKey, key)
	if err != nil {
		t.Fatal(err)
	}
	keyDER, err := x509.MarshalPKCS8PrivateKey(key)
	if err != nil {
		t.Fatal(err)
	}
	dir := t.TempDir()
	certPath, keyPath := filepath.Join(dir, "cert.pem"), filepath.Join(dir, "key.pem")
	if err := os.WriteFile(certPath, pem.EncodeToMemory(&pem.Block{Type: "CERTIFICATE", Bytes: der}), 0600); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(keyPath, pem.EncodeToMemory(&pem.Block{Type: "PRIVATE KEY", Bytes: keyDER}), 0600); err != nil {
		t.Fatal(err)
	}
	return certPath, keyPath
}

func unusedPort(t *testing.T, network string) string {
	t.Helper()
	if network == "udp" {
		c, err := net.ListenPacket("udp", "127.0.0.1:0")
		if err != nil {
			t.Fatal(err)
		}
		defer func() { _ = c.Close() }()
		return fmt.Sprint(c.LocalAddr().(*net.UDPAddr).Port)
	}
	l, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		t.Fatal(err)
	}
	defer func() { _ = l.Close() }()
	return fmt.Sprint(l.Addr().(*net.TCPAddr).Port)
}

func startPlugin(t *testing.T, args []string, env []string) {
	t.Helper()
	logFile, err := os.CreateTemp(t.TempDir(), "plugin-*.log")
	if err != nil {
		t.Fatal(err)
	}
	cmd := exec.Command(testBinary, args...)
	for _, entry := range os.Environ() {
		if !strings.HasPrefix(entry, "SS_") {
			cmd.Env = append(cmd.Env, entry)
		}
	}
	cmd.Env = append(cmd.Env, env...)
	cmd.Stdout, cmd.Stderr = logFile, logFile
	if err := cmd.Start(); err != nil {
		t.Fatal(err)
	}
	done := make(chan error, 1)
	go func() { done <- cmd.Wait() }()
	t.Cleanup(func() {
		_ = cmd.Process.Signal(os.Interrupt)
		select {
		case err := <-done:
			if err != nil {
				t.Errorf("plugin exited unexpectedly: %v", err)
			}
		case <-time.After(3 * time.Second):
			_ = cmd.Process.Kill()
			if err := <-done; err != nil {
				t.Logf("plugin did not exit after kill: %v", err)
			}
		}
		_ = logFile.Close()
		if t.Failed() {
			data, _ := os.ReadFile(logFile.Name())
			t.Logf("plugin output:\n%s", data)
		}
	})
}

func echoThroughPlugin(t *testing.T, addr string) error {
	t.Helper()
	conn, err := net.DialTimeout("tcp", addr, 200*time.Millisecond)
	if err != nil {
		return err
	}
	defer func() { _ = conn.Close() }()
	_ = conn.SetDeadline(time.Now().Add(2 * time.Second))
	payload := "Shadowsocks transport round trip\x00\xff"
	if _, err := io.WriteString(conn, payload); err != nil {
		return err
	}
	reply := make([]byte, len(payload))
	if _, err := io.ReadFull(conn, reply); err != nil {
		return err
	}
	if string(reply) != payload {
		return fmt.Errorf("unexpected reply: %q", reply)
	}
	return nil
}

func TestHysteria2Transport(t *testing.T) {
	testTransport(t, "hysteria2", "", "", "localhost", false, true)
}

func TestHysteria2Password(t *testing.T) {
	testTransport(t, "hysteria2", "shared-secret", "shared-secret", "localhost", false, true)
}

func TestHysteria2PluginOptions(t *testing.T) {
	testTransport(t, "hysteria2", "shared-secret", "shared-secret", "localhost", true, true)
}

func TestHysteria2RejectsWrongPassword(t *testing.T) {
	testTransport(t, "hysteria2", "shared-secret", "wrong-secret", "localhost", true, false)
}

func TestHysteria2RejectsWrongHostname(t *testing.T) {
	testTransport(t, "hysteria2", "", "", "other.example", false, false)
}

func TestWebSocketTransport(t *testing.T) {
	testTransport(t, "websocket", "", "", "localhost", false, true)
}

func TestWebSocketTLSTransport(t *testing.T) {
	testTransport(t, "websocket", "", "", "localhost", true, true)
}

func TestQUICTransport(t *testing.T) {
	testTransport(t, "quic", "", "", "localhost", false, true)
}

func testTransport(t *testing.T, transport, serverPassword, clientPassword, clientHost string, useEnv, wantSuccess bool) {
	t.Helper()
	certPath, keyPath := testCertificate(t)
	echo, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { _ = echo.Close() })
	go func() {
		for {
			conn, err := echo.Accept()
			if err != nil {
				return
			}
			go func() {
				defer func() { _ = conn.Close() }()
				_, _ = io.Copy(conn, conn)
			}()
		}
	}()
	network := "udp"
	if transport == "websocket" {
		network = "tcp"
	}
	transportPort, clientPort := unusedPort(t, network), unusedPort(t, "tcp")
	echoPort := fmt.Sprint(echo.Addr().(*net.TCPAddr).Port)
	if useEnv {
		startPlugin(t, nil, []string{"SS_LOCAL_HOST=127.0.0.1", "SS_LOCAL_PORT=" + echoPort, "SS_REMOTE_HOST=127.0.0.1", "SS_REMOTE_PORT=" + transportPort, "SS_PLUGIN_OPTIONS=server;tls;mode=" + transport + ";host=localhost;cert=" + certPath + ";key=" + keyPath + ";password=" + serverPassword})
		startPlugin(t, nil, []string{"SS_LOCAL_HOST=127.0.0.1", "SS_LOCAL_PORT=" + clientPort, "SS_REMOTE_HOST=127.0.0.1", "SS_REMOTE_PORT=" + transportPort, "SS_PLUGIN_OPTIONS=tls;mode=" + transport + ";host=" + clientHost + ";cert=" + certPath + ";password=" + clientPassword})
	} else {
		serverArgs := []string{"-server", "-mode=" + transport, "-localPort=" + transportPort, "-remotePort=" + echoPort, "-host=localhost", "-cert=" + certPath, "-key=" + keyPath}
		clientArgs := []string{"-mode=" + transport, "-localPort=" + clientPort, "-remotePort=" + transportPort, "-host=" + clientHost, "-cert=" + certPath}
		if transport == "hysteria2" {
			if serverPassword != "" {
				serverArgs = append(serverArgs, "-password="+serverPassword)
			}
			if clientPassword != "" {
				clientArgs = append(clientArgs, "-password="+clientPassword)
			}
			clientArgs = append(clientArgs, "-mux=8", "-path=/ignored")
		}
		startPlugin(t, serverArgs, nil)
		startPlugin(t, clientArgs, nil)
	}
	addr := net.JoinHostPort("127.0.0.1", clientPort)
	waitForListener(t, addr)
	deadline := time.Now().Add(6 * time.Second)
	var lastErr error
	for time.Now().Before(deadline) {
		lastErr = echoThroughPlugin(t, addr)
		if lastErr == nil {
			break
		}
		time.Sleep(50 * time.Millisecond)
	}
	if wantSuccess && lastErr != nil {
		t.Fatalf("transport failed: %v", lastErr)
	}
	if !wantSuccess && lastErr == nil {
		t.Fatal("transport accepted invalid credentials")
	}
}

func waitForListener(t *testing.T, addr string) {
	t.Helper()
	deadline := time.Now().Add(3 * time.Second)
	for time.Now().Before(deadline) {
		conn, err := net.DialTimeout("tcp", addr, 100*time.Millisecond)
		if err == nil {
			_ = conn.Close()
			return
		}
		time.Sleep(20 * time.Millisecond)
	}
	t.Fatalf("plugin did not start listening on %s", addr)
}
