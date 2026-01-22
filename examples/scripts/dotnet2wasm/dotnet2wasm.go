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

	space = " "

	memoryStr = `"memory"`

	keywordFunc = "func"
	keywordParam = "param"
	keywordType = "type"
	keywordResult = "result"

	funcStartMatch = parOpen + keywordFunc
	typeStartMatch = parOpen + keywordType
	paramStartMatch = parOpen + keywordParam
	resultStartMatch = parOpen + keywordResult
	exportMemoryMatch = parOpen + space + memoryStr

	maxLineParseLen = 1000
)

type Params struct {
	Args []string
	Res  string
}

func extractParams(t string) (p Params) {
	i := strings.Index(t, paramStartMatch)
	j := strings.Index(t[i:], parClose)+i
	args := t[i+len(paramStartMatch):j]
	args = strings.TrimSuffix(args, parClose)
	args = strings.TrimSpace(args)
	p.Args = strings.Split(args, " ")

	if k := strings.Index(t[j:], resultStartMatch); k >= 0 {
		k += j + len(resultStartMatch)
		res := t[k:]
		res = strings.TrimSuffix(res, parClose)
		res = strings.TrimSpace(res)
		p.Res = res
	}

	return p
}

func Main(in, out string, funs []string) (err error) {
	buf := make([]byte, 30*1024*1024)
	fin, err := os.Open(in)
	if err != nil { return }

	// 1st pass: gather function signatures
	params := make(map[string]Params)

	scanner := bufio.NewScanner(fin)
	scanner.Buffer(buf, len(buf))
	for scanner.Scan() {
		for _, fun := range funs {
			t := scanner.Text()
			if isFuncDecl(t, fun) {
				//log.Printf("found: %+v", t)
				log.Printf("import %s", fun)
				params[fun] = extractParams(t)
			}
		}
	}
	if err := scanner.Err(); err != nil {
		return fmt.Errorf("scanner error: %w", err)
	}

	//log.Printf("params: %+v", params)
	fin.Close()

	// 2nd pass: write exports
	fin, err = os.Open(in)
	if err != nil {
		return fmt.Errorf("2nd pass: open %s: %w", in, err)
	}
	defer fin.Close()

	fout, err := os.Create(out)
	if err != nil {
		return fmt.Errorf("2nd pass: create %s: %w", out, err)
	}
	defer fout.Close()

	// state
	i := 0
	exportMemoryMatched := false
	// prepare scanner
	scanner = bufio.NewScanner(fin)
	scanner.Buffer(buf, len(buf))
	w := bufio.NewWriter(fout)
	for scanner.Scan() {
		t := scanner.Text()
		// Output with re-written function calls
		if err := writeText(w, t, funs, params); err != nil {
			return fmt.Errorf("write text: %w", err)
		}

		if i == 0 {
			for fun, param := range params {
				fmt.Fprintf(w, "(import \"testmodule\" \"%s\" (func $Example_Example_CustomImports__%sOverwrite (param %s)", fun, fun, strings.Join(param.Args, " "))
				if param.Res != "" {
					fmt.Fprintf(w, space)
					fmt.Fprintf(w, parOpen)
					fmt.Fprintf(w, keywordResult)
					fmt.Fprintf(w, space)
					fmt.Fprintf(w, param.Res)
					fmt.Fprintf(w, parClose)
				}
				fmt.Fprintf(w, "))\n")
			}
		} else if !exportMemoryMatched && strings.Contains(t, exportMemoryMatch) {
			for fun := range params {
				fmt.Fprintf(w, "(export \"Example_%s\" (func $Example_Example_CustomImports__%s))\n", fun, fun)
			}
		}

		i++
	}
	if err := scanner.Err(); err != nil {
		return fmt.Errorf("scanner error: %w", err)
	}
	w.Flush()

	return
}

func isFuncDecl(txt, fun string) bool {
	if !strings.HasPrefix(strings.TrimSpace(txt), funcStartMatch) {
		return false
	}

	i := strings.Index(txt, fun)
	if i < 0 {
		return false
	}
	t := txt[i+len(fun):]

	t = strings.TrimSpace(t)

	matched := len(t) == 0 || strings.HasPrefix(t, paramStartMatch) || strings.HasPrefix(t, typeStartMatch)

	return matched
}

func writeText(w *bufio.Writer, t string, funs []string, params map[string]Params) (err error) {
	for _, fun := range funs {
		if strings.TrimSpace(t) == "call $Example_Example_CustomImports__"+fun {
			p := params[fun]
			// Arguments should be passed sequentially starting with the guest instance.
			// dotnet seems to use stdcall calling convention which cannot be changed
			// for functions annotated with UnmanagedCallersOnly. Thus overwrite
			// arguments by dropping them from the WebAssembly stack and adding the
			// correct ones.
			code := ""
			for i := 0; i < len(p.Args); i++ {
				code += "    drop\n"
			}
			for i := 0; i < len(p.Args); i++ {
				code += fmt.Sprintf("    local.get %d\n", i)
			}
			t = strings.Replace(t, "call $Example_Example_CustomImports__"+fun, code+"call $Example_Example_CustomImports__"+fun+"Overwrite", 1)
		}
	}
	if _, err = w.WriteString(t+"\n"); err != nil {
		return fmt.Errorf("write: %w", err)
	}
	return err
}

func main() {
	in := flag.String("in", "input.wat", "input file")
	out := flag.String("out", "output.wat", "output file")
	funsStr := flag.String("import", "printk,shutdown,input_data_len,input_data,testfunc", "import C functions")
	flag.Parse()

	funs := strings.Split(*funsStr, ",")

	if err := Main(*in, *out, funs); err != nil {
		log.Printf("main: %v", err)
	}
}
