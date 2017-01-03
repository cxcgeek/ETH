package http

import (
	"testing"
	"io/ioutil"
	"net/http"
	"bytes"
	"sync"
	"time"
	
	"github.com/ethereum/go-ethereum/swarm/storage"
	"github.com/ethereum/go-ethereum/swarm/api"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/logger/glog"
)

func TestBzzrGetPath(t *testing.T) {
	
	glog.SetToStderr(true)
	glog.SetV(6)
	
	var err error
	
	maxproxyattempts := 3
	
	testmanifest := []string{
		`{"entries":[{"path":"a/","hash":"674af7073604ebfc0282a4ab21e5ef1a3c22913866879ebc0816f8a89896b2ed","contentType":"application/bzz-manifest+json","status":0}]}`,
		`{"entries":[{"path":"a","hash":"011b4d03dd8c01f1049143cf9c4c817e4b167f1d1b83e5c6f0f10d89ba1e7bce","contentType":"","status":0},{"path":"b/","hash":"0a87b1c3e4bf013686cdf107ec58590f2004610ee58cc2240f26939f691215f5","contentType":"application/bzz-manifest+json","status":0}]}`,
		`{"entries":[{"path":"b","hash":"011b4d03dd8c01f1049143cf9c4c817e4b167f1d1b83e5c6f0f10d89ba1e7bce","contentType":"","status":0},{"path":"c","hash":"011b4d03dd8c01f1049143cf9c4c817e4b167f1d1b83e5c6f0f10d89ba1e7bce","contentType":"","status":0}]}`,
	}
	
	testrequests := make(map[string]int)
	testrequests["/"] = 0
	testrequests["/a"] = 1
	testrequests["/a/b"] = 2
	
	reader := [3]*bytes.Reader{}
	
	key := [3]storage.Key{}	
	
	dir, _ := ioutil.TempDir("", "bzz-storage-test")
	
	storeparams := &storage.StoreParams{
		dir,
		5000000,
		5000,
		0,
	}

	localStore, err := storage.NewLocalStore(storage.MakeHashFunc("SHA3"), storeparams)
	if err != nil {
		t.Fatal(err)
	}
	chunker := storage.NewTreeChunker(storage.NewChunkerParams())
	dpa := &storage.DPA{
		Chunker:    chunker,
		ChunkStore: localStore,
	}
	dpa.Start()
	defer dpa.Stop()
	
	wg := &sync.WaitGroup{}
	
	for i, mf := range testmanifest {
		reader[i] = bytes.NewReader([]byte(mf))
		key[i], err = dpa.Store(reader[i], int64(len(mf)), wg, nil)
		if err != nil {
			t.Fatal(err)
		}
		wg.Wait()
	}
	
	a := api.NewApi(dpa, nil)
	
	// iterate port numbers up if fail
	StartHttpServer(a, "8504")
	// how to wait for ListenAndServe to have initialized? This is pretty cruuuude
	// if we fix it we don't need maxproxyattempts anymore either
	time.Sleep(100 * time.Millisecond)	
	for i := 0; i <= maxproxyattempts; i++ {
		_, err := http.Get("http://127.0.0.1:8504/bzzr:/" + common.ToHex(key[0])[2:] + "/a")
		if i == maxproxyattempts {
			t.Fatalf("Failed to connect to proxy after %v attempts: %v", i, err)
		} else if err != nil {
			t.Logf("Proxy connect failed: %v", err)
			time.Sleep(100 * time.Millisecond)	
			continue
		} 
		break
	}
	
	
	
	for k, v := range testrequests {
		var body []byte
		var resp *http.Response
		url := "http://127.0.0.1:8504/bzzr:/" + common.ToHex(key[0])[2:] + "/" + k[1:] + "?content_type=text/plain"
		t.Logf("Sending proxy GET: %v", url)
		resp, err = http.Get(url)
		defer resp.Body.Close()
		body, err = ioutil.ReadAll(resp.Body)
	
		if string(body) != testmanifest[v] {
			t.Fatalf("Response body does not match, expected: %v, got %v", testmanifest[v], string(body))
		}
	
		t.Log(string(body))
	}

	
}
