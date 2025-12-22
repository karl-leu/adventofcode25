using System;
using System.Diagnostics;
using System.IO;
using System.Threading.Tasks;

class Program
{
    static async Task<int> Main(string[] args)
    {
        string relative = Path.Combine("Day3", "day3.ps1");
        string scriptPath = FindScriptPath(relative);

        if (scriptPath is null)
        {
            Console.Error.WriteLine($"PowerShell script not found. Checked: \"{relative}\" relative to working and output directories.");
            Console.Error.WriteLine("Make sure the script is included in the project and copied to the build output.");
            Console.Error.WriteLine("In Visual Studio: set the file's __Copy to Output Directory__ property to __Copy if newer__ or __Copy always__.");
            return 1;
        }

        // Try pwsh (PowerShell Core) first, fallback to Windows PowerShell on Windows
        string[] candidates = Environment.OSVersion.Platform == PlatformID.Win32NT
            ? new[] { "pwsh", "powershell.exe" }
            : new[] { "pwsh", "powershell" };

        foreach (var shell in candidates)
        {
            try
            {
                var psi = new ProcessStartInfo
                {
                    FileName = shell,
                    Arguments = $"-NoProfile -ExecutionPolicy Bypass -File \"{scriptPath}\"",
                    RedirectStandardOutput = true,
                    RedirectStandardError = true,
                    UseShellExecute = false,
                    CreateNoWindow = true
                };

                using var proc = Process.Start(psi);
                if (proc == null)
                    continue;

                var stdOutTask = proc.StandardOutput.ReadToEndAsync();
                var stdErrTask = proc.StandardError.ReadToEndAsync();

                await proc.WaitForExitAsync();

                string stdout = await stdOutTask;
                string stderr = await stdErrTask;

                if (!string.IsNullOrEmpty(stdout))
                    Console.WriteLine(stdout.TrimEnd());
                if (!string.IsNullOrEmpty(stderr))
                    Console.Error.WriteLine(stderr.TrimEnd());

                return proc.ExitCode;
            }
            catch (System.ComponentModel.Win32Exception)
            {
                // Shell not found, try next candidate
                continue;
            }
        }

        Console.Error.WriteLine("No suitable PowerShell executable found on PATH. Install PowerShell or ensure 'pwsh'/'powershell' is available.");
        return 2;
    }

    static string? FindScriptPath(string relativePath)
    {
        // Common locations: current working dir, AppContext.BaseDirectory (output), parent directories for IDE run
        string[] bases = new[]
        {
            Environment.CurrentDirectory,
            AppContext.BaseDirectory,
            Path.GetFullPath(Path.Combine(AppContext.BaseDirectory, "..", "..", "..")) // project root when running from bin
        };

        foreach (var b in bases)
        {
            if (string.IsNullOrEmpty(b))
                continue;

            string candidate = Path.GetFullPath(Path.Combine(b, relativePath));
            if (File.Exists(candidate))
                return candidate;
        }

        // Also check relative to the project layout directly
        if (File.Exists(relativePath))
            return Path.GetFullPath(relativePath);

        return null;
    }
}
