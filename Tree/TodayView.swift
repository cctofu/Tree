import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allSessions: [WorkoutSession]
    @State private var selectedDate: Date = Calendar.current.startOfDay(for: Date())

    private let dates: [Date] = {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        return (0..<14).map { cal.date(byAdding: .day, value: $0, to: today)! }
    }()

    private var navigationTitle: String {
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMMM d"
        return f.string(from: selectedDate)
    }

    var body: some View {
        NavigationStack {
            TabView(selection: $selectedDate) {
                ForEach(dates, id: \.self) { date in
                    DayPageView(date: date, allSessions: allSessions)
                        .tag(date)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .navigationTitle(navigationTitle)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.large)
            #endif
        }
    }
}

// ─── Per-day page ─────────────────────────────────────────────────────────────

struct DayPageView: View {
    @Environment(\.modelContext) private var modelContext
    let date: Date
    let allSessions: [WorkoutSession]

    private var isToday: Bool { Calendar.current.isDateInToday(date) }

    private var dayKey: String {
        let f = DateFormatter()
        f.dateFormat = "EEEE"
        return f.string(from: date)
    }

    private var plan: [PlannedExercise]? { workoutPlan[dayKey] }

    private var session: WorkoutSession? {
        allSessions.first { Calendar.current.isDate($0.date, inSameDayAs: date) }
    }

    var body: some View {
        Group {
            if isToday {
                if let session = session {
                    WorkoutSessionView(session: session)
                } else if plan != nil {
                    Color.clear.onAppear { createSession() }
                } else {
                    RestDayView()
                }
            } else {
                if let exercises = plan {
                    FutureWorkoutView(exercises: exercises)
                } else {
                    RestDayView()
                }
            }
        }
    }

    private func createSession() {
        guard let exercises = plan else { return }
        let session = WorkoutSession(date: date, dayKey: dayKey)
        modelContext.insert(session)
        for ex in exercises {
            let log = ExerciseLog(
                exerciseName: ex.name,
                sets: ex.sets,
                reps: ex.reps,
                weight: ex.weight
            )
            session.logs.append(log)
            modelContext.insert(log)
        }
        try? modelContext.save()
    }
}

// ─── Active workout session ───────────────────────────────────────────────────

struct WorkoutSessionView: View {
    @Environment(\.modelContext) private var modelContext
    var session: WorkoutSession

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                ProgressRingView(ratio: session.completionRatio)
                    .padding(.top, 8)

                VStack(spacing: 12) {
                    ForEach(session.logs) { log in
                        ExerciseRowView(log: log) {
                            if log.completedSets < log.sets {
                                log.completedSets += 1
                            } else {
                                log.completedSets = 0
                            }
                            try? modelContext.save()
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.bottom, 32)
        }
    }
}

// ─── Future workout preview ───────────────────────────────────────────────────

struct FutureWorkoutView: View {
    let exercises: [PlannedExercise]

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(exercises, id: \.name) { ex in
                    HStack(spacing: 14) {
                        Circle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 28, height: 28)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(ex.name)
                                .font(.body.weight(.medium))
                            Text(ex.weight.isEmpty
                                 ? "\(ex.sets) sets · \(ex.reps) reps"
                                 : "\(ex.sets) sets · \(ex.reps) reps · \(ex.weight)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(Color.primary.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 32)
        }
    }
}

// ─── Progress ring ────────────────────────────────────────────────────────────

struct ProgressRingView: View {
    var ratio: Double

    private var percentText: String { "\(Int(ratio * 100))%" }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 14)
                .frame(width: 120, height: 120)

            Circle()
                .trim(from: 0, to: ratio)
                .stroke(
                    ratio == 1.0 ? Color.green : Color.blue,
                    style: StrokeStyle(lineWidth: 14, lineCap: .round)
                )
                .frame(width: 120, height: 120)
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.4), value: ratio)

            VStack(spacing: 2) {
                Text(percentText)
                    .font(.title2.bold())
                Text("done")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// ─── Exercise row ─────────────────────────────────────────────────────────────

struct ExerciseRowView: View {
    var log: ExerciseLog
    var onToggle: () -> Void

    private var progress: Double {
        guard log.sets > 0 else { return 0 }
        return Double(min(log.completedSets, log.sets)) / Double(log.sets)
    }

    private var ringColor: Color {
        log.isCompleted ? .green : .blue
    }

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 14) {
                // Arc progress indicator
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 3)
                        .frame(width: 36, height: 36)

                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(ringColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .frame(width: 36, height: 36)
                        .rotationEffect(.degrees(-90))
                        .animation(.spring(response: 0.3), value: progress)

                    if log.isCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.green)
                    } else if log.completedSets > 0 {
                        Text("\(log.completedSets)")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.blue)
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(log.exerciseName)
                        .font(.body.weight(.medium))
                        .foregroundStyle(log.isCompleted ? .secondary : .primary)
                        .strikethrough(log.isCompleted)

                    Text(log.weight.isEmpty
                         ? "\(log.sets) sets · \(log.reps) reps"
                         : "\(log.sets) sets · \(log.reps) reps · \(log.weight)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color.primary.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

// ─── Rest day placeholder ─────────────────────────────────────────────────────

struct RestDayView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "moon.zzz.fill")
                .font(.system(size: 56))
                .foregroundStyle(.secondary)
            Text("Rest day")
                .font(.title2.bold())
            Text("Enjoy the recovery.")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
