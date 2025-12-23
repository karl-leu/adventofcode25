using AoC_CommandLine;
using System;
using System.Collections.Generic;
using System.Text;

namespace AoC_CommandLine
{

    internal class Matrix
    {
        private int rows;
        private int cols;
        private int[,] data;

        public int Rows => rows;
        public int Cols => cols;
        public int this[int row, int col]
        {
            get { return data[row, col]; }
            set { data[row, col] = value; }
        }

        public Matrix(int rows, int cols)
        {
            this.rows = rows;
            this.cols = cols;
            data = new int[rows + 2, cols + 2];
        }

        public Matrix(string filePath)
        {
            var raw = File.ReadAllLines(filePath)
                          .Select(l => l.Trim())
                          .Where(l => l.Length > 0)
                          .ToList();

            if (raw.Count == 0)
                throw new InvalidOperationException("Input file is empty or contains only blank lines.");

            rows = raw.Count;
            cols = raw[0].Length;

            if (raw.Any(l => l.Length != cols))
                throw new InvalidOperationException("Inconsistent line lengths in input file.");

            data = new int[rows + 2, cols + 2];

            // The `matrix` stores data in an array sized [rows+2, cols+2].
            // We place file contents starting at index 1..rows and 1..cols (padding at 0 and rows+1 / cols+1).
            for (int r = 0; r < rows; r++)
            {
                for (int c = 0; c < cols; c++)
                {
                    char ch = raw[r][c];
                    // Map '@' -> 1, '.' -> 0. Any other char -> 0 (adjust if needed).
                    data[r + 1, c + 1] = ch == '@' ? 1 : 0;
                }
            }
        }

        public void FillPadding()
        {
            //first row > bottom padding
            for (int c = 1; c < data.GetLength(1) - 1; c++)
            {
                data[data.GetLength(0) - 1, c] = data[1, c];
            }
            //last row > top padding
            for (int c = 1; c < data.GetLength(1) - 1; c++)
            {
                data[0, c] = data[data.GetLength(0) - 2, c];
            }
            //first col > right padding
            for (int r = 1; r < data.GetLength(0) - 1; r++)
            {
                data[r, data.GetLength(1) - 1] = data[r, 1];
            }
            //last col > left padding
            for (int r = 1; r < data.GetLength(0) - 1; r++)
            {
                data[r, 0] = data[r, data.GetLength(1) - 2];
            }
        }
        public int CountNeighbors(int row, int col)
        {
            int count = 0;
            for (int dr = -1; dr <= 1; dr++)
            {
                for (int dc = -1; dc <= 1; dc++)
                {
                    if (dr == 0 && dc == 0)
                        continue; // Skip the cell itself
                    int x = data[row + dr, col + dc];
                    if (x > 0)
                    {
                        count++;
                    }
                }
            }
            return count;
        }

        public int CountAccessibleRolls()
        {
            int accessibleCount = 0;
            for (int r = 1; r <= rows; r++)
            {
                for (int c = 1; c <= cols; c++)
                {
                    if (data[r, c] == 0)
                        continue; // Skip empty cells
                    if (CountNeighbors(r, c) < 4) 
                    {
                        data[r, c] = 0; // Mark as accessible
                        accessibleCount++;
                    }
                }
            }
            return accessibleCount;
        }
    }
    internal class Day4
    {
        // read from file and fill the matrix
        public static void Execute()
        {
            try
            {
                string relative = "input.txt";
                string path = FindFile(relative);
                if (path is null)
                {
                    Console.Error.WriteLine($"File not found: \"{relative}\". Make sure the file is present next to the executable or in the project and set __Copy to Output Directory__ = __Copy if newer__.");
                    return;
                }
                Matrix m = new Matrix(path);
                // m.FillPadding();
                int totalRolls = 0;
                int accessibleRolls = m.CountAccessibleRolls();
                Console.WriteLine("Accessible Rolls: {0}", accessibleRolls);

                while (accessibleRolls > 0)
                {
                    totalRolls += accessibleRolls;
                    accessibleRolls = m.CountAccessibleRolls();
                }

                Console.WriteLine("Total Accessible Rolls: {0}", totalRolls);

                Console.WriteLine("Matrix loaded. Dimensions: {0} x {1}", m.Rows, m.Cols);
                // Print matrix to console (1 for '@', 0 for '.')
                for (int r = 0; r <= m.Rows + 1; r++)
                {
                    var sb = new StringBuilder();
                    for (int c = 0; c <= m.Cols + 1; c++)
                    {
                        sb.Append(m[r, c]);
                    }
                    Console.WriteLine(sb.ToString());
                }

                Console.WriteLine(m.CountNeighbors(2, 2));
            }
            catch (Exception ex)
            {
                Console.Error.WriteLine("Error reading matrix: " + ex.Message);
            }
        }

        private static string FindFile(string relativePath)
        {
            // Look in common locations: current working dir, output directory, project root
            string[] bases = new[]
            {
                Environment.CurrentDirectory,
                AppContext.BaseDirectory,
                Path.GetFullPath(Path.Combine(AppContext.BaseDirectory, "..", "..", ".."))
            };

            foreach (var b in bases)
            {
                if (string.IsNullOrEmpty(b))
                    continue;

                string candidate = Path.GetFullPath(Path.Combine(b, relativePath));
                if (File.Exists(candidate))
                    return candidate;
            }

            // Also check the relative path as-is
            if (File.Exists(relativePath))
                return Path.GetFullPath(relativePath);

            return null;
        }
    }
}

