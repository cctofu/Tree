import Foundation
import SwiftData

// One session per workout day.
// Created automatically when you open the app on a workout day.
@Model
class WorkoutSession {
    var date: Date
    var dayKey: String              // e.g. "Monday"

    @Relationship(deleteRule: .cascade)
    var logs: [ExerciseLog] = []

    init(date: Date, dayKey: String) {
        self.date = date
        self.dayKey = dayKey
    }

    // Percentage of total sets completed across all exercises (0.0 – 1.0)
    var completionRatio: Double {
        let totalSets = logs.reduce(0) { $0 + $1.sets }
        guard totalSets > 0 else { return 0 }
        let doneSets = logs.reduce(0) { $0 + min($1.completedSets, $1.sets) }
        return Double(doneSets) / Double(totalSets)
    }

    var isFullyComplete: Bool {
        !logs.isEmpty && logs.allSatisfy { $0.isCompleted }
    }
}

// One protein entry per logging action.
@Model
class ProteinEntry {
    var grams: Double
    var note: String
    var timestamp: Date

    init(grams: Double, note: String = "", timestamp: Date = Date()) {
        self.grams = grams
        self.note = note
        self.timestamp = timestamp
    }
}

// One log entry per exercise per session.
@Model
class ExerciseLog {
    var exerciseName: String
    var sets: Int
    var reps: Int
    var weight: String
    var completedSets: Int

    var isCompleted: Bool { completedSets >= sets }

    init(exerciseName: String, sets: Int, reps: Int, weight: String) {
        self.exerciseName = exerciseName
        self.sets = sets
        self.reps = reps
        self.weight = weight
        self.completedSets = 0
    }
}
