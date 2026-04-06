import Foundation

/// All API credentials are loaded from environment variables or Info.plist.
/// Never hardcode secrets in source code.
///
/// Setup: Add keys to Layman/Resources/Config.xcconfig, then reference
/// them in Info.plist as $(KEY_NAME). The .xcconfig file must be
/// added to .gitignore.
enum AppConfig {

    // MARK: - Supabase

    static var supabaseURL: String {
        value(forKey: "SUPABASE_URL", default: "")
    }

    static var supabaseAnonKey: String {
        value(forKey: "SUPABASE_ANON_KEY", default: "")
    }

    // MARK: - News API (newsdata.io)

    static var newsAPIKey: String {
        value(forKey: "NEWSDATA_API_KEY", default: "")
    }

    // MARK: - AI (Groq — free tier)

    static var groqAPIKey: String {
        value(forKey: "GROQ_API_KEY", default: "")
    }

    static var supabaseBaseURL: URL? {
        URL(string: supabaseURL)
    }

    // MARK: - Private

    private static func value(forKey key: String, default defaultValue: String) -> String {
        if let value = Bundle.main.infoDictionary?[key] as? String, !value.isEmpty {
            return value
        } else {
            #if DEBUG
            print("⚠️  AppConfig: Missing Info.plist key '\(key)'. Falling back to default.")
            #endif
            return defaultValue
        }
    }
}
