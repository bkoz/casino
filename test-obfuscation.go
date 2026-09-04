// go:build ignore
// +build ignore

package main

import "fmt"

// Test script to generate obfuscated flag bytes
func main() {
	flag := "FLAG{b3n3d1ct_g0t_r0bb3d_2026}"
	xorKey := byte(0x42)

	fmt.Println("Original flag:", flag)
	fmt.Println("XOR Key:", xorKey)
	fmt.Println("\nObfuscated bytes:")
	fmt.Print("var flagObfuscated = []byte{\n\t")

	for i, char := range []byte(flag) {
		obfuscated := char ^ xorKey
		fmt.Printf("0x%02x, ", obfuscated)
		if (i+1)%14 == 0 && i < len(flag)-1 {
			fmt.Print("\n\t")
		}
	}
	fmt.Println("\n}")

	// Verify it works
	fmt.Println("\nDeobfuscated:")
	decoded := make([]byte, len(flag))
	for i, b := range []byte(flag) {
		decoded[i] = (b ^ xorKey) ^ xorKey
	}
	fmt.Println(string(decoded))
}
