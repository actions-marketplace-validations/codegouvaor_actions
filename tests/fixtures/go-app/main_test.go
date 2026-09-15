package main

import "testing"

func TestHello(t *testing.T) {
	if Hello() != "hello" {
		t.Fatal("unexpected Hello() result")
	}
}