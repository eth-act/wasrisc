using System;
using System.IO;
using System.Runtime.InteropServices;
using System.Security.Cryptography;
using System.Text;

using Org.BouncyCastle.Crypto.Digests;
using SixLabors.ImageSharp;
using SixLabors.ImageSharp.PixelFormats;
using SixLabors.ImageSharp.Processing;

namespace Example
{
    public unsafe class Example
    {
        [UnmanagedCallersOnly(EntryPoint = "Example_Free")]
        public static void Free(void* p)
        {
            NativeMemory.Free(p);
        }

        public void asciiImage() {
            Console.WriteLine("asciiImage: read image...");
            var newWidth = 80;
            using var image = Image.Load<Rgba32>(CustomImports.InputDataBytes());

            int newHeight = (int)(image.Height / (double)image.Width * newWidth * 0.5);
            image.Mutate(x => x.Resize(newWidth, newHeight));

            string chars = "@%#*+=-:. ";

            for (int y = 0; y < image.Height; y++)
            {
                for (int x = 0; x < image.Width; x++)
                {
                    var pixel = image[x, y];
                    int gray = (int)(0.2126 * pixel.R + 0.7152 * pixel.G + 0.0722 * pixel.B);
                    int index = (gray * (chars.Length - 1)) / 255;
                    Console.Write(chars[index]);
                }
                Console.Write('\n');
            }
        }

        static void HashTest()
        {
            var input = CustomImports.InputDataBytes();
            Sha256Digest digest = new Sha256Digest();
            digest.BlockUpdate(input, 0, input.Length);
            byte[] result = new byte[digest.GetDigestSize()];
            digest.DoFinal(result, 0);

            string hashHex = BitConverter.ToString(result).Replace("-", "").ToLowerInvariant();
            Console.WriteLine($"sha256 of input data:: {hashHex}");
        }

        public void memoryTest() {
            // 180 MB allocated through wasmAllocate
            // 512 MB in principle available from ziskemu
            Console.WriteLine("test filling up memory...\n");

            int memChunkSz = 1024*1024;
            int numChunks = 180;
            byte[][] memChunks = new byte[numChunks][];
            var j = 0;
            for (var i = 1; i <= numChunks; i++)
            {
                memChunks[i-1] = new byte[memChunkSz];
                if (i % 10 == 0)
                {
                    Console.WriteLine($"mem test: filled up {i} MB...");
                }
            }
        }

        [UnmanagedCallersOnly(EntryPoint = "_start")]
        public static void Run()
        {
            var example = new Example();
            example.memoryTest();
            GC.Collect();
            example.memoryTest();
            GC.Collect();

            HashTest();

            var input = CustomImports.InputDataBytes();
            bool isBmp = input.Length >= 2 && input[0] == 0x42 && input[1] == 0x4D;
            if (isBmp)
            {
                Console.WriteLine("bmp image detected:");
                example.asciiImage();
            }

            uint a = 7;
            uint b = 13;
            Console.WriteLine($"testfunc(a={a}, b={b}) = {CustomImports.Testfunc(a, b)}");
        }
    }
}

