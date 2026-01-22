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

        [UnmanagedCallersOnly(EntryPoint = "_start")]
        public static void Run()
        {
        }
    }
}
