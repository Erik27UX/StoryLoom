import Foundation
import Supabase

// MARK: - Supabase Client Singleton

final class SupabaseManager {
    static let shared = SupabaseManager()

    let client: SupabaseClient

    private init() {
        client = SupabaseClient(
            supabaseURL: URL(string: "https://snczqjrrlymkzgkjxbce.supabase.co")!,
            supabaseKey: "sb_publishable_akxRlftGdKi2h-R9xJT63g_FuxRhpUg"
        )
    }
}
