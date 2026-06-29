import Foundation

// ─────────────────────────────────────────────
// EDIT THIS FILE to change your workout routine.
// dayKey must match the weekday name exactly.
// Rest days: just omit the day or leave it out.
// ─────────────────────────────────────────────

struct PlannedExercise {
    let name: String
    let sets: Int
    let reps: Int
    let weight: String   // e.g. "135 lbs", "BW", "40 kg"
}

let workoutPlan: [String: [PlannedExercise]] = [

    "Monday": [
        PlannedExercise(name: "Bench Press",            sets: 4, reps: 8,  weight: ""),
        PlannedExercise(name: "Incline Bench Press",    sets: 4, reps: 8,  weight: ""),
        PlannedExercise(name: "Shoulder Press",         sets: 3, reps: 10, weight: ""),
        PlannedExercise(name: "Heavy Dumbbell Raises",  sets: 3, reps: 6,  weight: ""),
        PlannedExercise(name: "Shoulder Fly",           sets: 3, reps: 10, weight: ""),
    ],

    "Tuesday": [
        PlannedExercise(name: "Sitting Back Row",       sets: 4, reps: 8,  weight: ""),
        PlannedExercise(name: "Lat Pulldown",           sets: 4, reps: 10, weight: ""),
        PlannedExercise(name: "Standing Single Arm Row",sets: 3, reps: 8,  weight: ""),
        PlannedExercise(name: "Standing Pushdowns",     sets: 3, reps: 10, weight: ""),
        PlannedExercise(name: "Core Workout",           sets: 1, reps: 1,  weight: ""),
    ],

    "Wednesday": [
        PlannedExercise(name: "Cable Raises",           sets: 3, reps: 12, weight: ""),
        PlannedExercise(name: "Incline Front Raises",   sets: 3, reps: 8,  weight: ""),
        PlannedExercise(name: "Light Dumbbell Raises",  sets: 3, reps: 10, weight: ""),
        PlannedExercise(name: "Cable Fly",              sets: 3, reps: 10, weight: ""),
        PlannedExercise(name: "Bicep Cable Curl",       sets: 4, reps: 10, weight: ""),
    ],

    "Thursday": [
        PlannedExercise(name: "Bench Press",            sets: 4, reps: 10, weight: ""),
        PlannedExercise(name: "High to Low Cable Fly",  sets: 3, reps: 12, weight: ""),
        PlannedExercise(name: "Low to High Cable Fly",  sets: 3, reps: 12, weight: ""),
        PlannedExercise(name: "Chest Squeeze",          sets: 4, reps: 10, weight: ""),
        PlannedExercise(name: "Standing Pushdowns",     sets: 3, reps: 10, weight: ""),
        PlannedExercise(name: "Core Workout",           sets: 1, reps: 1,  weight: ""),
    ],

    "Friday": [
        PlannedExercise(name: "Seated Rows",            sets: 4, reps: 10, weight: ""),
        PlannedExercise(name: "Lat Pulldown",           sets: 4, reps: 10, weight: ""),
        PlannedExercise(name: "Standing Single Arm Row",sets: 3, reps: 8,  weight: ""),
        PlannedExercise(name: "Bicep Cable Curl",       sets: 4, reps: 10, weight: ""),
        PlannedExercise(name: "Core Workout",           sets: 1, reps: 1,  weight: ""),
    ],
]

// Computed helper — returns today's exercises or nil if it's a rest day
var todaysPlan: [PlannedExercise]? {
    let formatter = DateFormatter()
    formatter.dateFormat = "EEEE"   // "Monday", "Tuesday", …
    let dayName = formatter.string(from: Date())
    return workoutPlan[dayName]
}
