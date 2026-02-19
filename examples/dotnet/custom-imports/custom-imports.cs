using System.Runtime.InteropServices;

namespace Example {
    public unsafe class CustomImports {

        public static byte[] InputDataBytes() {
            int n = inputDataLen();
            byte[] result = new byte[n];

            for (int i = 0; i < n; i++) {
                result[i] = (byte) inputData(i);
            }

            return result;
        }

        // Host function declarations as specified in custom-imports.wit.
        // This allows clean modularized definitions.
        //
        // It should be mentioned though that unsigned declarations
        // become signed at the interface level.

        [global::System.Runtime.InteropServices.DllImportAttribute("example:api/testmodule", EntryPoint = "testfunc"), global::System.Runtime.InteropServices.WasmImportLinkageAttribute]
        public static extern int testfunc(int a, int b);

        [global::System.Runtime.InteropServices.DllImportAttribute("example:api/testmodule", EntryPoint = "testfunc2"), global::System.Runtime.InteropServices.WasmImportLinkageAttribute]
        public static extern int testfunc2(int a, int b);

        [global::System.Runtime.InteropServices.DllImportAttribute("example:api/testmodule", EntryPoint = "printk"), global::System.Runtime.InteropServices.WasmImportLinkageAttribute]
        public static extern void _printk(int val);

        public static void printk(uint val) {
            unchecked {
                _printk((int)val);
            }
        }

        [global::System.Runtime.InteropServices.DllImportAttribute("example:api/testmodule", EntryPoint = "input-data"), global::System.Runtime.InteropServices.WasmImportLinkageAttribute]
        public static extern int inputData(int i);

        [global::System.Runtime.InteropServices.DllImportAttribute("example:api/testmodule", EntryPoint = "input-data-len"), global::System.Runtime.InteropServices.WasmImportLinkageAttribute]
        public static extern int inputDataLen();

        [global::System.Runtime.InteropServices.DllImportAttribute("example:api/testmodule", EntryPoint = "shutdown"), global::System.Runtime.InteropServices.WasmImportLinkageAttribute]
        public static extern void shutdown();
    }
}
