package main

import (
	"bytes"
	"context"
	"encoding/binary"
	"encoding/json"
	"fmt"
	"log"
	"net"
	"net/http"
	"os"
	"os/exec"
	"time"
)

var (
	port                 = env("SIDECAR_PORT", "8000")
	rpcPort              = env("TON_API_HTTP_PORT", "8081")
	liteClientConfigPath = env("LITESERVER_CONFIG", "/var/ton-work/db/localhost.global.config.json")
	liteClientBin        = env("LITECLIENT_BIN", "/usr/local/bin/lite-client")
)

// inherited from my-local-ton
type faucet struct {
	WorkChain        int32  `json:"workChain"`
	WalletRawAddress string `json:"walletRawAddress"`
	Mnemonic         string `json:"mnemonic"`
	WalletVersion    string `json:"walletVersion"`
	SubWalletId      int    `json:"subWalletId"`
}

// https://github.com/neodix42/mylocalton-docker?tab=readme-ov-file#pre-installed-wallets
// Faucet wallet @ basechain (balance: 1,000,000 TON)
var faucetBaseChain = faucet{
	WorkChain:        0,
	WalletRawAddress: "0:1da77f0269bbbb76c862ea424b257df63bd1acb0d4eb681b68c9aadfbf553b93",
	Mnemonic:         "again tired walnut legal case simple gate deer huge version enable special metal collect hurdle merit between salmon elbow pattern initial receive total slender",
	WalletVersion:    "V3R2",
	SubWalletId:      42,
}

func main() {
	http.HandleFunc("/faucet.json", errorWrapper(faucetHandler))
	http.HandleFunc("/lite-client.json", errorWrapper(liteClientHandler))
	http.HandleFunc("/status", errorWrapper(statusHandler))

	log.Print("Starting sidecar on port ", port)

	//nolint:gosec
	if err := http.ListenAndServe(":"+port, nil); err != nil {
		log.Fatal(err)
	}
}

func errorWrapper(handler func(w http.ResponseWriter, r *http.Request) error) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		if err := handler(w, r); err != nil {
			errResponse(w, http.StatusInternalServerError, err)
		}
	}
}

// Handler for the /faucet.json route
func faucetHandler(w http.ResponseWriter, _ *http.Request) error {
	jsonResponse(w, http.StatusOK, faucetBaseChain)

	return nil
}

// liteClientHandler returns lite json client config
// and alters localhost to docker IP if needed.
func liteClientHandler(w http.ResponseWriter, _ *http.Request) error {
	data, err := os.ReadFile(liteClientConfigPath)
	if err != nil {
		return fmt.Errorf("could not read lite client config: %w", err)
	}

	dockerIP := os.Getenv("DOCKER_IP")

	if dockerIP != "" {
		altered, err := alterConfigIP(data, dockerIP)
		if err != nil {
			errResponse(w, http.StatusInternalServerError, err)
			return nil
		}

		data = altered
	}

	jsonResponse(w, http.StatusOK, json.RawMessage(data))
	return nil
}

var resOK = map[string]string{
	"status": "OK",
}

// Handler for the /status route
func statusHandler(w http.ResponseWriter, _ *http.Request) error {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	if err := checkLiteClient(ctx); err != nil {
		return fmt.Errorf("lite server check failed: %w", err)
	}

	if err := checkRPC(ctx); err != nil {
		return fmt.Errorf("rpc check failed: %w", err)
	}

	jsonResponse(w, http.StatusOK, resOK)

	return nil
}

func errResponse(w http.ResponseWriter, status int, err error) {
	jsonResponse(w, status, map[string]string{
		"error": err.Error(),
	})
}

func jsonResponse(w http.ResponseWriter, status int, data any) {
	b, err := json.Marshal(data)
	if err != nil {
		b = []byte("Failed to marshal JSON")
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)

	//nolint:errcheck
	w.Write(b)
}

// TON's lite client config contains the IP of the node.
// And it's localhost, we need to change it to the docker IP.
func alterConfigIP(config []byte, ipString string) ([]byte, error) {
	const localhost = uint32(2130706433)

	ip := net.ParseIP(ipString)
	if ip == nil {
		return nil, fmt.Errorf("failed to parse IP: %q", ipString)
	}

	return bytes.ReplaceAll(
		config,
		uint32ToBytes(localhost),
		uint32ToBytes(ip2int(ip)),
	), nil
}

func ip2int(ip net.IP) uint32 {
	if len(ip) == 16 {
		return binary.BigEndian.Uint32(ip[12:16])
	}

	return binary.BigEndian.Uint32(ip)
}

func uint32ToBytes(n uint32) []byte {
	return []byte(fmt.Sprintf("%d", n))
}

func checkLiteClient(ctx context.Context) error {
	const timeoutSec = "2"

	args := []string{
		"--timeout", timeoutSec,
		"--global-config", liteClientConfigPath,
		"-c", "last",
	}

	return exec.CommandContext(ctx, liteClientBin, args...).Run()
}

// https://toncenter.com/api/v2/#/
func checkRPC(ctx context.Context) error {
	url := fmt.Sprintf("http://0.0.0.0:%s/getMasterchainInfo", rpcPort)

	req, err := http.NewRequestWithContext(ctx, http.MethodGet, url, nil)
	if err != nil {
		return fmt.Errorf("failed to create request: %w", err)
	}

	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		return fmt.Errorf("failed to get masterchain info: %w", err)
	}

	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("failed to get masterchain info: http code %d", resp.StatusCode)
	}

	type resShape struct {
		Ok     bool `json:"ok"`
		Result struct {
			Last struct {
				Seqno uint32 `json:"seqno"`
			} `json:"last"`
		} `json:"result"`
	}

	var res resShape

	err = json.NewDecoder(resp.Body).Decode(&res)

	switch {
	case err != nil:
		return fmt.Errorf("failed to decode response: %w", err)
	case !res.Ok:
		return fmt.Errorf("invalid response")
	case res.Result.Last.Seqno == 0:
		return fmt.Errorf("seqno is 0")
	}

	return nil
}

func env(key, fallback string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}

	return fallback
}
