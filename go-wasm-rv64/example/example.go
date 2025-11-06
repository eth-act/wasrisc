package main

import (
	"bytes"
	"crypto/sha256"
	"fmt"
	"image/color"
	"image/png"
	"runtime"
	"runtime/debug"
	"strings"
	"time"
)

//go:wasmimport testmodule testfunc
//go:noescape
func testfunc(a, b uint32)

//go:wasmimport testmodule printk
//go:noescape
func printk(x uint32)

//go:wasmimport testmodule input_data
//go:noescape
func input_data(i uint32) uint32

//go:wasmimport testmodule input_data_len
//go:noescape
func input_data_len() uint32

func getInputData() []byte {
	n := input_data_len()
	fmt.Printf("input data len: %v\n", n)
	data := make([]byte, n)
	for i := uint32(0); i < n; i++ {
		data[i] = byte(input_data(i))
	}
	return data
}

func createSequence(ch chan<- uint32) {
	for i := uint32(0); i < 5; i++ {
		ch <- i
	}
	close(ch)
}

func asciiImage() (err error) {
	fmt.Printf("asciiImage: read png...\n")
	inputData := getInputData()
	fmt.Printf("asciiImage: new bytes reader...\n")
	r := bytes.NewReader(inputData)
	fmt.Printf("asciiImage: decode...\n")
	img, err := png.Decode(r)
	if err != nil {
		return fmt.Errorf("decode: %w", err)
	}

	levels := []string{" ", ".", ":", "o", "#"}

	fmt.Printf("asciiImage: process image... (bounds=%+v)\n", img.Bounds())
	for y := img.Bounds().Min.Y; y < img.Bounds().Max.Y; y++ {
		for x := img.Bounds().Min.X; x < img.Bounds().Max.X; x++ {
			c := color.GrayModel.Convert(img.At(x, y)).(color.Gray)
			level := c.Y / 51 // 51 * 5 = 255
			if level == 5 {
				level--
			}
			fmt.Print(levels[level])
		}
		fmt.Print("\n")
	}

	return nil
}

func memoryTest() {
	var memStats runtime.MemStats
	runtime.ReadMemStats(&memStats)
	fmt.Printf("mem stats: %+v\n", memStats)

	// 370 MB allocated through wasmAllocate
	// 512 MB in principle available from ziskemu
	fmt.Printf("test filling up memory (~370 MB expected to work)...\n")
	memChunkSz := 256*1024
	memChunks := make([][]uint32, 0, 1024)

	for i := 1; i <= 370; i++ {
		buf := make([]uint32, memChunkSz)
		memChunks = append(memChunks, buf)
		if i % 10 == 0 {
			fmt.Printf("mem test: filled up %d MB...\n", i)
		}
	}
}

func worker(name string, delay time.Duration) {
	for {
		fmt.Printf("-- %s -- yield me\n", name)
		runtime.Gosched()
	}
	for i := 1; i <= 5; i++ {
		fmt.Printf("[%s] iteration %d\n", name, i)
		time.Sleep(delay)
	}
}

func concurrencyTest() {
	go worker("A", 200*time.Millisecond)
	go worker("B", 200*time.Millisecond)

	// Main goroutine keeps working too
	for i := 1; i <= 5; i++ {
		fmt.Printf("[main] iteration %d\n", i)
	}
}

func main() {
	// Limit memory in use. Otherwise when a lot memory is used
	// eventually the Go runtime will allocate too chunks at
	// once. The smaller limit will pursue mallocgc to allocate
	// memory granular, allowing to use the available memory
	// more effectively.
	debug.SetMemoryLimit(400 * (1<<20));

	go (func() { select{} })()

	fmt.Printf("the current time is %v\n", time.Now())
	fmt.Printf("and now: %v\n", time.Now())
	testfunc(0x450, 0x6)
	printk(0x7890abcd);

	ch := make(chan uint32)
	go createSequence(ch)
	for i := range ch {
		fmt.Printf("read from channel: %d\n", i)
	}

	sum := sha256.Sum256([]byte("test"))
	fmt.Printf("sha256('test')=%x\n", sum)

	r := strings.NewReader("test go on web assembly")
	rBuf := make([]byte, 100)
	rN, rErr := r.Read(rBuf)
	fmt.Printf("string reader test: rN=%d rErr=%v\n", rN, rErr)
	fmt.Printf("string reader test: rBuf = %v\n", string(rBuf))

	fmt.Printf("get input data...\n")
	inputData := getInputData()
	inputDataPreview := inputData
	if len(inputDataPreview) > 32 {
		inputDataPreview = inputDataPreview[:32]
	}
	fmt.Printf("input data = % x... (len=%d)\n", inputDataPreview, len(inputData))
	fmt.Printf("sha256(input data) = %x\n", sha256.Sum256(inputData))

	if err := asciiImage(); err != nil {
		fmt.Printf("error from ascii image: %v\n", err)
	}

	memoryTest()
	runtime.GC()
	memoryTest()
	runtime.GC()

	concurrencyTest()
}
