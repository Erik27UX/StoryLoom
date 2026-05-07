import Foundation
import Supabase

// MARK: - Supabase Client Singleton

final class SupabaseManager {
    static let shared = SupabaseManager()

    let client: SupabaseClient

    private init() {
        // The URL constant is validated at compile time — fatalError surfaces any
        // misconfiguration immediately during development rather than silently at runtime.
        guard let supabaseURL = URL(string: "https://snczqjrrlymkzgkjxbce.supabase.co") else {
            fatalError("SupabaseManager: invalid Supabase URL — check project configuration")
        }
        client = SupabaseClient(
            supabaseURL: supabaseURL,
            supabaseKey: "sb_publishable_akxRlftGdKi2h-R9xJT63g_FuxRhpUg"
        )
    }
}
