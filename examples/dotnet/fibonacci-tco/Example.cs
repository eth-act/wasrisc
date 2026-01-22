using System;
using System.IO;
using System.Runtime.InteropServices;
using System.Text;

namespace Example
{
    public unsafe class Example
    {
        [UnmanagedCallersOnly(EntryPoint = "Example_Free")]
        public static void Free(void* p)
        {
            NativeMemory.Free(p);
        }

        public uint fibonacci(uint n, uint a, uint b) {
            if (n == 0) {
                return a;
            }
            return fibonacci(n-1, b, a+b);
        }

        [UnmanagedCallersOnly(EntryPoint = "_start")]
        public static void Run()
        {
            var example = new Example();

            uint n = 40;
            uint y = example.fibonacci(n, 0, 1);

            Console.WriteLine($"fib({n}) = {y}");
        }
    }
}

