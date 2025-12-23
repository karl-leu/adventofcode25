
// Program.cs
using System;

namespace Day5
{
    internal static class Program
    {
        // The process entry point
        static void Main(string[] args)
        {
            Console.WriteLine("Program.Main starting…");

            // Call the other static class' Main
            MyCli.Main(args);

            Console.WriteLine("Program.Main done.");
        }
    }

    public static class MyCli
    {
        // You *can* name this Main, but it's not the entry point.
        public static void Main(string[] args)
        {
            Console.WriteLine("MyCli.Main running with args: " + string.Join(", ", args));
            // …your logic…
        }
    }
}
