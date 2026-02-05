// Rudimentary tool to parse and patch wasip2 style import function
// declarations such they are compatible with wasip1.
package main

import (
	"bufio"
	"flag"
	"fmt"
	"log"
	"os"
	"strings"
)

const (
	parOpen = "("
	parClose = ")"

	quote = `"`

	importStr = "import"

	importPackageName = "example:api"
	importModuleName = "testmodule"
	fullImportModuleName = importPackageName + "/" + importModuleName
)

func Main(in, out string) (err error) {
	buf := make([]byte, 30*1024*1024)
	fin, err := os.Open(in)
	if err != nil { return }

	fout, err := os.Create(out)
	if err != nil {
		return fmt.Errorf("2nd pass: create %s: %w", out, err)
	}
	defer fout.Close()

	scanner := bufio.NewScanner(fin)
	scanner.Buffer(buf, len(buf))
	for scanner.Scan() {
		t := scanner.Text()
		if funcName, updated, ok := importWasip1Compat(t); ok {
			log.Printf("import %s", funcName)
			fout.WriteString(updated+"\n")
		} else {
			fout.WriteString(t+"\n")
		}
	}
	if err := scanner.Err(); err != nil {
		return fmt.Errorf("scanner error: %w", err)
	}

	fin.Close()

	return
}

func importWasip1Compat(line string) (funcName, updated string, ok bool) {
	line = strings.TrimSpace(line)
	line = strings.TrimPrefix(line, parOpen)
	line = strings.TrimSuffix(line, parClose)
	tokens := strings.Fields(line)
	if len(tokens) >= 3 && tokens[0] == importStr {
		if tokens[1] == quote + fullImportModuleName + quote {
			funcName = tokens[2]
			tokens[1] = quote + importModuleName + quote
			updated = parOpen + strings.Join(tokens, " ") + parClose
			ok = true
		}
	}
	return
}

func main() {
	in := flag.String("in", "input.wat", "input file")
	out := flag.String("out", "output.wat", "output file")
	flag.Parse()

	if err := Main(*in, *out); err != nil {
		log.Printf("main: %v", err)
	}
}
