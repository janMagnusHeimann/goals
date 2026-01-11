import SwiftUI

struct PersonalRecordsView: View {
    let records: [PersonalRecord]
    var onAddRecord: (() -> Void)?

    private var groupedRecords: [PRCategory: [PersonalRecord]] {
        Dictionary(grouping: records) { $0.category }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack {
                Image(systemName: "trophy.fill")
                    .font(.title2)
                    .foregroundStyle(.yellow)
                Text("Personal Records")
                    .font(.headline)
                Spacer()

                if let onAdd = onAddRecord {
                    Button(action: onAdd) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
            }

            if records.isEmpty {
                ContentUnavailableView {
                    Label("No Records Yet", systemImage: "trophy")
                } description: {
                    Text("Add your first personal record to track your progress")
                } actions: {
                    if let onAdd = onAddRecord {
                        Button("Add Record", action: onAdd)
                            .buttonStyle(.borderedProminent)
                    }
                }
                .frame(height: 200)
            } else {
                // Records by category
                ForEach(PRCategory.allCases.filter { groupedRecords[$0] != nil }) { category in
                    if let categoryRecords = groupedRecords[category] {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: category.icon)
                                    .foregroundStyle(.secondary)
                                Text(category.displayName)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }

                            ForEach(categoryRecords.sorted { $0.achievedDate > $1.achievedDate }) { record in
                                PersonalRecordRow(record: record)
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.goalCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Personal Record Row

struct PersonalRecordRow: View {
    let record: PersonalRecord

    var body: some View {
        HStack(spacing: 12) {
            // Trophy indicator
            Image(systemName: "trophy.fill")
                .font(.title3)
                .foregroundStyle(.yellow)

            VStack(alignment: .leading, spacing: 2) {
                Text(record.exercise)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(record.achievedDate, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(record.formattedValue)
                    .font(.title3)
                    .fontWeight(.bold)

                if let improvement = record.formattedImprovement {
                    HStack(spacing: 2) {
                        Image(systemName: record.isImprovement ? "arrow.up" : "arrow.down")
                            .font(.caption2)
                        Text(improvement)
                    }
                    .font(.caption)
                    .foregroundStyle(record.isImprovement ? .green : .red)
                }
            }
        }
        .padding()
        .background(Color.yellow.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Personal Record Card (Compact)

struct PersonalRecordCard: View {
    let record: PersonalRecord

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: record.category.icon)
                    .foregroundStyle(.yellow)
                Spacer()
                Image(systemName: "trophy.fill")
                    .foregroundStyle(.yellow.opacity(0.5))
            }

            VStack(spacing: 4) {
                Text(record.formattedValue)
                    .font(.system(size: 24, weight: .bold, design: .rounded))

                Text(record.exercise)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let improvement = record.formattedImprovement {
                HStack(spacing: 4) {
                    Image(systemName: record.isImprovement ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                    Text(improvement)
                }
                .font(.caption)
                .foregroundStyle(record.isImprovement ? .green : .red)
            }
        }
        .padding()
        .background(Color.goalCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Add Personal Record Sheet

struct AddPersonalRecordSheet: View {
    @Environment(\.dismiss) private var dismiss

    let goal: Goal
    let onSave: (PersonalRecord) -> Void

    @State private var category: PRCategory = .running
    @State private var exercise: String = ""
    @State private var value: String = ""
    @State private var unit: String = ""
    @State private var date: Date = Date()
    @State private var notes: String = ""

    private var isValid: Bool {
        !exercise.isEmpty && Double(value) != nil
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("New Personal Record")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Category Picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Category")
                            .font(.headline)

                        Picker("Category", selection: $category) {
                            ForEach(PRCategory.allCases) { cat in
                                Label(cat.displayName, systemImage: cat.icon)
                                    .tag(cat)
                            }
                        }
                        .pickerStyle(.segmented)
                        .onChange(of: category) { _, newValue in
                            unit = newValue.defaultUnit
                            exercise = ""
                        }
                    }

                    // Exercise
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Exercise / Distance")
                            .font(.headline)

                        if !category.commonExercises.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack {
                                    ForEach(category.commonExercises, id: \.self) { ex in
                                        Button(ex) {
                                            exercise = ex
                                        }
                                        .buttonStyle(.bordered)
                                        .tint(exercise == ex ? .blue : .secondary)
                                    }
                                }
                            }
                        }

                        TextField("Exercise name", text: $exercise)
                            .textFieldStyle(.roundedBorder)
                    }

                    // Value and Unit
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Value")
                                .font(.headline)
                            TextField("Value", text: $value)
                                .textFieldStyle(.roundedBorder)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Unit")
                                .font(.headline)
                            TextField("Unit", text: $unit)
                                .textFieldStyle(.roundedBorder)
                        }
                        .frame(width: 100)
                    }

                    // Date
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Date Achieved")
                            .font(.headline)
                        DatePicker("Date", selection: $date, displayedComponents: .date)
                            .labelsHidden()
                    }

                    // Notes
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Notes (optional)")
                            .font(.headline)
                        TextField("Notes", text: $notes, axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                            .lineLimit(2...4)
                    }
                }
                .padding()
            }

            Divider()

            // Footer
            HStack {
                Spacer()
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.escape)

                Button("Save Record") {
                    saveRecord()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!isValid)
                .keyboardShortcut(.return)
            }
            .padding()
        }
        .frame(width: 450, height: 550)
        .onAppear {
            unit = category.defaultUnit
        }
    }

    private func saveRecord() {
        guard let numericValue = Double(value) else { return }

        let record = PersonalRecord(
            exercise: exercise,
            category: category,
            value: numericValue,
            unit: unit,
            achievedDate: date,
            notes: notes.isEmpty ? nil : notes
        )
        record.goal = goal

        onSave(record)
        dismiss()
    }
}

// MARK: - Preview

#Preview {
    let records = [
        PersonalRecord(exercise: "5K", category: .running, value: 1200, unit: "seconds", achievedDate: Date()),
        PersonalRecord(exercise: "10K", category: .running, value: 2580, unit: "seconds", achievedDate: Date()),
        PersonalRecord(exercise: "Bench Press", category: .strength, value: 100, unit: "kg", achievedDate: Date())
    ]
    records[0].previousValue = 1260 // 60 seconds slower before

    return VStack {
        PersonalRecordsView(records: records) {
            print("Add record")
        }

        HStack {
            PersonalRecordCard(record: records[0])
            PersonalRecordCard(record: records[2])
        }
    }
    .padding()
    .frame(width: 500)
}
