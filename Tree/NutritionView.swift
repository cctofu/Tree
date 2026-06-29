import SwiftUI
import SwiftData

struct NutritionView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(
        filter: #Predicate<ProteinEntry> { _ in true },
        sort: \ProteinEntry.timestamp,
        order: .reverse
    ) private var allEntries: [ProteinEntry]

    @State private var showingAddSheet = false

    private let goal: Double = 150

    private var todayEntries: [ProteinEntry] {
        allEntries.filter { Calendar.current.isDateInToday($0.timestamp) }
    }

    private var todayTotal: Double {
        todayEntries.reduce(0) { $0 + $1.grams }
    }

    private var progress: Double {
        min(todayTotal / goal, 1.0)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    proteinRing
                        .padding(.top, 24)

                    dailyLog
                }
                .padding(.bottom, 32)
            }
            .navigationTitle("Nutrition")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.large)
            #endif
            .background(Color.appBackground)
            .toolbarBackground(Color.appBackground, for: .navigationBar)
            .sheet(isPresented: $showingAddSheet) {
                AddProteinSheet { grams, note in
                    let entry = ProteinEntry(grams: grams, note: note)
                    modelContext.insert(entry)
                    try? modelContext.save()
                }
            }
        }
    }

    // MARK: - Circular progress

    private var proteinRing: some View {
        Button {
            showingAddSheet = true
        } label: {
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 16)
                    .frame(width: 180, height: 180)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        progress >= 1.0 ? Color.green : Color.orange,
                        style: StrokeStyle(lineWidth: 16, lineCap: .round)
                    )
                    .frame(width: 180, height: 180)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.4), value: progress)

                VStack(spacing: 4) {
                    Text("\(Int(todayTotal))g")
                        .font(.title.bold())
                    Text("/ \(Int(goal))g protein")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("Tap to add")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Daily progression

    private var dailyLog: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today's Entries")
                .font(.headline)
                .padding(.horizontal)

            if todayEntries.isEmpty {
                Text("No entries yet — tap the ring to log protein.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
            } else {
                ForEach(todayEntries) { entry in
                    HStack(spacing: 12) {
                        Circle()
                            .fill(Color.orange.opacity(0.2))
                            .frame(width: 8, height: 8)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(Int(entry.grams))g protein")
                                .font(.body.weight(.medium))
                            if !entry.note.isEmpty {
                                Text(entry.note)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Spacer()

                        Text(entry.timestamp, format: .dateTime.hour().minute())
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Button {
                            modelContext.delete(entry)
                            try? modelContext.save()
                        } label: {
                            Image(systemName: "trash")
                                .font(.caption)
                                .foregroundStyle(.red.opacity(0.7))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.primary.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)
                }
            }
        }
    }
}

// MARK: - Add Protein Sheet

struct AddProteinSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var gramsText = ""
    @State private var note = ""
    @FocusState private var gramsFocused: Bool

    var onSave: (Double, String) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Amount") {
                    TextField("Grams of protein", text: $gramsText)
                        .keyboardType(.decimalPad)
                        .focused($gramsFocused)
                }
                Section("Note (optional)") {
                    TextField("e.g. Chicken breast, Shake…", text: $note)
                }
            }
            .navigationTitle("Log Protein")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if let grams = Double(gramsText), grams > 0 {
                            onSave(grams, note)
                        }
                        dismiss()
                    }
                    .disabled(Double(gramsText) == nil || (Double(gramsText) ?? 0) <= 0)
                }
            }
            .onAppear { gramsFocused = true }
        }
        .presentationDetents([.medium])
    }
}
