import SwiftUI
import SwiftData

@main
struct TreeApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [WorkoutSession.self, ExerciseLog.self, ProteinEntry.self])
    }
}
