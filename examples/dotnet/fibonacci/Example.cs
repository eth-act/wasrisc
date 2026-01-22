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

        public uint fibonacci(uint n) {
            if (n <= 1) {
                return n;
            }
            return fibonacci(n-1) + fibonacci(n-2);
        }

        [UnmanagedCallersOnly(EntryPoint = "_start")]
        public static void Run()
        {
            var example = new Example();

            uint n = 10;
            uint y = example.fibonacci(n);

            Console.WriteLine($"fib({n}) = {y}");
        }
    }
}

