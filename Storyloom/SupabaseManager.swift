import Foundation
import Supabase

// MARK: - Supabase Client Singleton

final class SupabaseManager {
    static let shared = SupabaseManager()

    let client: SupabaseClient

    private init() {
        // Credentials come from SupabaseConfig.swift, which is git-ignored.
        // If the build fails here, copy SupabaseConfig.example.swift → SupabaseConfig.swift
        // and fill in the real host and anon key.
        guard let supabaseURL = URL(string: "https://\(SupabaseConfig.host)") else {
            fatalError("SupabaseManager: invalid Supabase host in SupabaseConfig.swift")
        }
        client = SupabaseClient(
            supabaseURL: supabaseURL,
            supabaseKey: SupabaseConfig.anonKey
        )
    }
}
