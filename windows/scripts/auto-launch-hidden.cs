using System;
using System.Diagnostics;
using System.IO;

// GUI-subsystem bootstrap: no console is allocated or delegated to Terminal.
internal static class DreamSkinAutoLaunchHidden {
    [STAThread]
    private static int Main(string[] args) {
        if (args.Length != 0) return 2;
        try {
            string directory = AppDomain.CurrentDomain.BaseDirectory;
            string script = Path.Combine(directory, "auto-launch-dream-skin.ps1");
            if (!File.Exists(script)) return 3;
            string powershell = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.System),
                @"WindowsPowerShell\v1.0\powershell.exe");
            var start = new ProcessStartInfo(powershell,
                "-NoProfile -NonInteractive -WindowStyle Hidden -ExecutionPolicy RemoteSigned -File \"" +
                script + "\" -TakeOverStartupSession");
            start.UseShellExecute = false;
            start.CreateNoWindow = true;
            start.WindowStyle = ProcessWindowStyle.Hidden;
            start.WorkingDirectory = Path.GetDirectoryName(directory.TrimEnd(Path.DirectorySeparatorChar));
            using (Process process = Process.Start(start)) { }
            return 0;
        } catch (Exception error) {
            try {
                string root = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "CodexDreamSkinYuuka");
                File.AppendAllText(Path.Combine(root, "auto-launch-bootstrap.log"),
                    DateTime.UtcNow.ToString("o") + " " + error.GetType().Name + ": " + error.Message + Environment.NewLine);
            } catch { }
            return 1;
        }
    }
}
