using System.Runtime.InteropServices;

namespace Example {
    public unsafe class CustomImports {
        // Host functions need to be wrapped within Unmanaged Code
        // as this is the code which can be patched on a wasm level.
        //
        // The managed code on the other hand is compiled to dotnet
        // byte code, and embedded as a binary blob.

        private static unsafe extern void printk(uint a);

        private static unsafe extern int input_data_len();

        private static unsafe extern int input_data(int i);

        private static unsafe extern void shutdown();

        private static unsafe extern uint testfunc(uint a, uint b);

        [UnmanagedCallersOnly(EntryPoint = "Example_printkWrapper")]
        private static void printkWrapper(uint a) {
            printk(a);
        }

        [UnmanagedCallersOnly(EntryPoint = "Example_input_data_lenWrapper")]
        private static int input_data_lenWrapper() {
            return input_data_len();
        }

        [UnmanagedCallersOnly(EntryPoint = "Example_input_dataWrapper")]
        private static int input_dataWrapper(int i) {
            return input_data(i);
        }

        [UnmanagedCallersOnly(EntryPoint = "Example_shutdownWrapper")]
        private static void shutdownWrapper() {
            shutdown();
        }

        [UnmanagedCallersOnly(EntryPoint = "Example_testfuncWrapper")]
        private static uint testfuncWrapper(uint a, uint b) {
            return testfunc(a, b);
        }

        // Define function pointer to access unmanaged code from managed code.

        public static delegate* unmanaged<int> InputDataLen = &input_data_lenWrapper;
        public static delegate* unmanaged<int, int> InputData = &input_dataWrapper;
        public static delegate* unmanaged<uint, void> Printk = &printkWrapper;
        public static delegate* unmanaged<void> Shutdown = &shutdownWrapper;
        public static delegate* unmanaged<uint, uint, uint> Testfunc = &testfuncWrapper;

        public static byte[] InputDataBytes() {
            int n = InputDataLen();
            byte[] result = new byte[n];

            for (int i = 0; i < n; i++) {
                result[i] = (byte) InputData(i);
            }

            return result;
        }
    }
}
