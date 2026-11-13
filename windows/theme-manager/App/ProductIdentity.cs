namespace DreamSkin.ThemeManager;

internal static class ProductIdentity
{
    public const string DisplayName = "Codex Dream Skin Yuuka";
    public const string StateDirectoryName = "CodexDreamSkinYuuka";
    public static string StateRoot => Path.Combine(
        Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), StateDirectoryName);
}
