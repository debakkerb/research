package main

import (
	"crypto/hmac"
	"crypto/sha1"
	"encoding/base64"
	"flag"
	"fmt"
	"log"
	"os"
)

func main() {
	urlPrefix := flag.String("prefix", "test", "URL Prefix")
	expiryDate := flag.String("expire", "test", "When the cookie expires")
	keyName := flag.String("keyname", "test", "Name of the key that was used to encode everything")
	signature := flag.String("sig", "test", "Signature")

	flag.Parse()

	input := fmt.Sprintf("URLPrefix=%s:Expires=%s:KeyName=%s",
		*urlPrefix,
		*expiryDate,
		*keyName,
	)

	key, err := readKey()
	if err != nil {
		log.Fatal("Can't read key.")
	}

	mac := hmac.New(sha1.New, key)
	mac.Write([]byte(input))
	sig := base64.URLEncoding.EncodeToString(mac.Sum(nil))

	if sig == *signature {
		fmt.Printf("Both signatures are alike (cookie: %s, calculated: %s)", *signature, sig)
	} else {
		fmt.Printf("Signatures are different (cookie: %s, calculated: %s)", *signature, sig)
	}
}

func readKey() ([]byte, error) {
	b, err := os.ReadFile("./key.txt")
	if err != nil {
		return nil, fmt.Errorf("failed to read key file: %+v", err)
	}

	d := make([]byte, base64.URLEncoding.DecodedLen(len(b)))
	n, err := base64.URLEncoding.Decode(d, b)
	if err != nil {
		return nil, fmt.Errorf("failed to base64url decode: %+v", err)
	}
	return d[:n], nil
}
