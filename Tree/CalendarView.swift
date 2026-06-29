import SwiftUI
import SwiftData

struct CalendarView: View {
    @Query private var allSessions: [WorkoutSession]
    @State private var displayedMonth: Date = Calendar.current.startOfMonth(for: Date())

    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible()), count: 7)
    private let weekdaySymbols = ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]

    // All days to display in the current month grid (includes leading blanks)
    private var gridDays: [Date?] {
        let firstOfMonth = displayedMonth
        let weekdayOfFirst = calendar.component(.weekday, from: firstOfMonth) - 1  // 0=Sun
        let daysInMonth = calendar.range(of: .day, in: .month, for: firstOfMonth)!.count

        var days: [Date?] = Array(repeating: nil, count: weekdayOfFirst)
        for day in 1...daysInMonth {
            var comps = calendar.dateComponents([.year, .month], from: firstOfMonth)
            comps.day = day
            days.append(calendar.date(from: comps))
        }
        // Pad to complete the last row
        while days.count % 7 != 0 { days.append(nil) }
        return days
    }

    // Map date → session for fast lookup
    private var sessionsByDay: [Date: WorkoutSession] {
        var map: [Date: WorkoutSession] = [:]
        for session in allSessions {
            let key = calendar.startOfDay(for: session.date)
            map[key] = session
        }
        return map
    }

    private var monthTitle: String {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        return f.string(from: displayedMonth)
    }

    // Streak = consecutive fully-completed workout days up to today
    private var currentStreak: Int {
        var streak = 0
        var checking = calendar.startOfDay(for: Date())
        let map = sessionsByDay
        while true {
            if let session = map[checking], session.isFullyComplete {
                streak += 1
            } else {
                // Allow today to be in-progress without breaking streak
                if checking == calendar.startOfDay(for: Date()) {
                    // skip today if not yet done
                } else {
                    break
                }
            }
            guard let prev = calendar.date(byAdding: .day, value: -1, to: checking) else { break }
            checking = prev
            if streak > 365 { break }   // safety cap
        }
        return streak
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {

                    // Streak banner
                    if currentStreak > 0 {
                        HStack(spacing: 10) {
                            Image(systemName: "flame.fill")
                                .foregroundStyle(.orange)
                            Text("\(currentStreak) day streak")
                                .font(.subheadline.weight(.semibold))
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.orange.opacity(0.12))
                        .clipShape(Capsule())
                    }

                    // Month navigation
                    HStack {
                        Button {
                            withAnimation { displayedMonth = calendar.date(byAdding: .month, value: -1, to: displayedMonth)! }
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.body.weight(.semibold))
                                .padding(10)
                                .background(Color.primary.opacity(0.06))
                                .clipShape(Circle())
                        }

                        Spacer()
                        Text(monthTitle)
                            .font(.title3.weight(.semibold))
                        Spacer()

                        Button {
                            withAnimation { displayedMonth = calendar.date(byAdding: .month, value: 1, to: displayedMonth)! }
                        } label: {
                            Image(systemName: "chevron.right")
                                .font(.body.weight(.semibold))
                                .padding(10)
                                Color.gray.opacity(0.25)
                                .clipShape(Circle())
                        }
                    }
                    .padding(.horizontal)

                    // Weekday headers
                    HStack(spacing: 0) {
                        ForEach(weekdaySymbols, id: \.self) { sym in
                            Text(sym)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.horizontal, 8)

                    // Day grid
                    LazyVGrid(columns: columns, spacing: 10) {
                        ForEach(Array(gridDays.enumerated()), id: \.offset) { _, day in
                            DayCellView(
                                date: day,
                                session: day.flatMap { sessionsByDay[calendar.startOfDay(for: $0)] }
                            )
                        }
                    }
                    .padding(.horizontal, 8)
                }
                .padding(.top, 12)
                .padding(.bottom, 32)
            }
            .navigationTitle("Calendar")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.large)
            #endif
        }
    }
}

// ─── Individual day cell ──────────────────────────────────────────────────────

struct DayCellView: View {
    var date: Date?
    var session: WorkoutSession?

    private let calendar = Calendar.current

    private var isToday: Bool {
        guard let date else { return false }
        return calendar.isDateInToday(date)
    }

    private var dayNumber: String {
        guard let date else { return "" }
        return "\(calendar.component(.day, from: date))"
    }

    // Is this a scheduled workout day?
    private var isWorkoutDay: Bool {
        guard let date else { return false }
        let f = DateFormatter()
        f.dateFormat = "EEEE"
        let name = f.string(from: date)
        return workoutPlan[name] != nil
    }

    var body: some View {
        ZStack {
            // Background
            if isToday {
                Circle().fill(Color.blue.opacity(0.15))
            } else if session?.isFullyComplete == true {
                Circle().fill(Color.green.opacity(0.18))
            }

            VStack(spacing: 3) {
                Text(dayNumber)
                    .font(.system(size: 15, weight: isToday ? .bold : .regular))
                    .foregroundStyle(date == nil ? .clear : isToday ? .blue : .primary)

                // Status indicator
                if let session {
                    if session.isFullyComplete {
                        Image(systemName: "checkmark")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.green)
                    } else {
                        // Partial: show filled dots ratio
                        Text("\(session.logs.filter(\.isCompleted).count)/\(session.logs.count)")
                            .font(.system(size: 8))
                            .foregroundStyle(.orange)
                    }
                } else if isWorkoutDay && date != nil {
                    // Scheduled but no session (future or skipped)
                    let isPast = (date ?? Date()) < calendar.startOfDay(for: Date())
                    Circle()
                        .fill(isPast ? Color.red.opacity(0.5) : Color.gray.opacity(0.4))
                        .frame(width: 5, height: 5)
                } else {
                    // Spacer to keep rows uniform height
                    Color.clear.frame(height: 9)
                }
            }
        }
        .frame(height: 50)
    }
}

// ─── Calendar helper ──────────────────────────────────────────────────────────

extension Calendar {
    func startOfMonth(for date: Date) -> Date {
        let comps = dateComponents([.year, .month], from: date)
        return self.date(from: comps)!
    }
}
