import Foundation

/// Lightweight runtime localization.
///
/// AquaPaste ships for a global audience, so English is the default. When the
/// user's system language is Vietnamese, the Vietnamese string is shown instead.
/// This avoids a full `.strings`/bundle setup while still covering both audiences.
enum AppLanguage {
    /// True when the current system language is Vietnamese.
    static let isVietnamese: Bool = {
        let code = Locale.current.language.languageCode?.identifier.lowercased()
        return code == "vi"
    }()
}

/// Returns the Vietnamese string on Vietnamese systems, English otherwise.
/// - Parameters:
///   - en: English text (default, shown worldwide).
///   - vi: Vietnamese text (shown only when the system language is Vietnamese).
func L(_ en: String, _ vi: String) -> String {
    AppLanguage.isVietnamese ? vi : en
}
