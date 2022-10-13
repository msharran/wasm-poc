package main

import (
	"fmt"
	"strings"
	"unsafe"

	"github.com/mailru/easyjson"
	"github.com/wasm-automation/ruby-wasmer/go/types"
)

func main() {}

//export sum
func sum(i, j int) int {
	return i + j
}

func check(err error) {
	if err != nil {
		panic(err)
	}
}

// TODO: De-allocate memory
//
//export GetMemoryBuffer
func GetMemoryBuffer(size int) *byte {
	buffer := make([]byte, size)
	return &buffer[0]
}

//export Greet
func Greet(dataPtr *byte) *byte {
	ticketBytes := readFromMemory(dataPtr)

	// To pass a string to syscall you need to pass a pointer to the first character of the string. The first question is what string encoding your DLL function expects. Go strings are encoded as UTF-8 unicode so if your C function expects something else you have to convert them first. Here are some common cases:
	// First convert your string to a byte array and add the zero that C expects at the end. Then pass the pointer to the first byte character.
	// To be safe you should also make sure that you actually pass in only valid ASCII strings and no invalid characters. Usually only characters in the range [0..127] are valid for general ASCII. The rest depends on the current codepage.

	s := fmt.Sprintf("Hello, %s!", ticketBytes)
	b := append([]byte(s), 0)
	return &b[0]
}

//export AddFooTag
func AddFooTag(dataPtr *byte) *byte {
	msgJSON := readFromMemory(dataPtr)

	msg := &types.Message{}
	err := easyjson.Unmarshal(msgJSON, msg)
	check(err)

	// remove duplicate tags by adding it to map
	tt := make(map[string]struct{})
	for _, t := range msg.Tags {
		tt[t] = struct{}{}
	}
	if strings.Contains(strings.ToLower(msg.Subject), "foo") {
		tt["foo"] = struct{}{}
	}

	msg.Tags = make([]string, 0, len(tt))
	for tag := range tt {
		t := strings.TrimSpace(tag)
		if t != "" {
			msg.Tags = append(msg.Tags, tag)
		}
	}

	msgRes, err := easyjson.Marshal(msg)
	check(err)

	// terminate the data with 0.
	b := append(msgRes, 0)
	return &b[0]
}

// readFromMemory extracts the string from the memory pointer till it get 0
func readFromMemory(pointerStart *byte) []byte {
	var bb []byte

	ptrStart := unsafe.Pointer(pointerStart)
	itemSize := unsafe.Sizeof(*pointerStart)

	i := 0
	for {
		item := *(*byte)(unsafe.Add(ptrStart, uintptr(i)*itemSize))
		if item == 0 {
			break
		}
		bb = append(bb, item)
		i++
	}

	return bb
}
