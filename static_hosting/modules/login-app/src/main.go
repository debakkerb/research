package main

/**
 * Copyright 2022 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import (
	"crypto/hmac"
	"crypto/sha1"
	"encoding/base64"
	"errors"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"time"
)

func main() {
	mux := http.NewServeMux()
	mux.HandleFunc("/", login)

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
		log.Printf("Defaulting to port %s", port)
	}

	log.Printf("Listening on port %s", port)
	if err := http.ListenAndServe(":"+port, mux); err != nil {
		log.Fatal(err)
	}
}

func login(w http.ResponseWriter, r *http.Request) {
	urlPath := r.URL.Path
	host := r.URL.Host

	cookie := &http.Cookie{
		Name:   "Cloud-CDN-Cookie",
		Value:  "Testing",
		MaxAge: 300,
	}

	http.SetCookie(w, cookie)
	http.Redirect(w, r, host+urlPath, http.StatusFound)
}

func signCookie(urlPrefix string, key []byte, expiration time.Time) (string, error) {
	keyName := os.Getenv("KEY_NAME")

	encodedURLPrefix := base64.URLEncoding.EncodeToString([]byte(urlPrefix))
	input := fmt.Sprintf("URLPrefix=%s:Expires=%d:KeyName=%s", encodedURLPrefix, expiration.Unix(), keyName)

	mac := hmac.New(sha1.New, key)
	sig := base64.URLEncoding.EncodeToString(mac.Sum(nil))

	signedValue := fmt.Sprintf("%s:Signature=%s",
		input,
		sig,
	)

	return signedValue, nil
}

func readKey() ([]byte, error) {
	keyValue := os.Getenv("SIGN_KEY")
	d := make([]byte, base64.URLEncoding.DecodedLen(len(keyValue)))
	n, err := base64.URLEncoding.Decode([]byte(keyValue), d)
	if err != nil {
		return nil, fmt.Errorf("failed to decode base64url: %+v", err)
	}

	return d[:n], nil
}

func generateSignedCookie(w io.Writer) error {

	signingKey := os.Getenv("SIGN_KEY")
	if signingKey == "" {
		return errors.New("error while generating signed cookie, signing key not set")
	}

	var (
		domain     = os.Getenv("HOST")
		path       = "/"
		expiration = time.Hour * 2
	)

	key, err := readKey()
	if err != nil {
		return err
	}

	signedValue, err := signCookie(fmt.Sprintf("%s%s", domain, path), key, time.Now().Add(expiration))

	cookie := &http.Cookie{
		Name:   "Cloud-CDN-Cookie",
		Value:  signedValue,
		Path:   path,
		Domain: domain,
		MaxAge: int(expiration.Seconds()),
	}

	log.Println(cookie)

	fmt.Fprintln(w, cookie)
	return nil
}
