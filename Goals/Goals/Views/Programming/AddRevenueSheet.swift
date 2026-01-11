import SwiftUI

struct AddRevenueSheet: View {
    @Environment(\.dismiss) private var dismiss

    let project: AppProject
    let onSave: (RevenueEntry) -> Void

    @State private var date: Date = Date()
    @State private var period: RevenuePeriod = .monthly
    @State private var grossRevenue: String = ""
    @State private var netRevenue: String = ""
    @State private var autoCalculateNet: Bool = true
    @State private var downloads: String = ""
    @State private var inAppPurchases: String = ""
    @State private var subscriptions: String = ""
    @State private var notes: String = ""

    private var grossRevenueValue: Double {
        Double(grossRevenue) ?? 0
    }

    private var netRevenueValue: Double {
        if autoCalculateNet {
            return RevenueEntry.calculateNetRevenue(gross: grossRevenueValue, platform: project.platform)
        }
        return Double(netRevenue) ?? 0
    }

    private var platformFee: Double {
        grossRevenueValue - netRevenueValue
    }

    private var platformFeePercentage: Double {
        guard grossRevenueValue > 0 else { return 0 }
        return (platformFee / grossRevenueValue) * 100
    }

    private var isValid: Bool {
        grossRevenueValue > 0
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading) {
                    Text("Log Revenue")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text(project.name)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
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
                VStack(alignment: .leading, spacing: 24) {
                    // Period and Date
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Period")
                                .font(.headline)
                            Picker("Period", selection: $period) {
                                ForEach(RevenuePeriod.allCases) { period in
                                    Text(period.displayName).tag(period)
                                }
                            }
                            .pickerStyle(.segmented)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Date")
                                .font(.headline)
                            DatePicker("", selection: $date, displayedComponents: .date)
                                .labelsHidden()
                        }
                    }

                    // Gross Revenue
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Gross Revenue")
                            .font(.headline)

                        HStack {
                            Text("$")
                                .foregroundStyle(.secondary)
                            TextField("0.00", text: $grossRevenue)
                                .textFieldStyle(.roundedBorder)
                        }

                        Text("Total revenue before platform fees")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    // Net Revenue
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Net Revenue")
                                .font(.headline)
                            Spacer()
                            Toggle("Auto-calculate", isOn: $autoCalculateNet)
                                .font(.caption)
                        }

                        if autoCalculateNet {
                            HStack {
                                Text(formatCurrency(netRevenueValue))
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.green)

                                Spacer()

                                VStack(alignment: .trailing) {
                                    Text("-\(formatCurrency(platformFee))")
                                        .foregroundStyle(.red)
                                    Text("(\(String(format: "%.0f", platformFeePercentage))% fee)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding()
                            .background(Color.green.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        } else {
                            HStack {
                                Text("$")
                                    .foregroundStyle(.secondary)
                                TextField("0.00", text: $netRevenue)
                                    .textFieldStyle(.roundedBorder)
                            }
                        }
                    }

                    // Downloads
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Downloads (optional)")
                            .font(.headline)
                        TextField("Number of downloads", text: $downloads)
                            .textFieldStyle(.roundedBorder)
                    }

                    // Revenue Breakdown
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Revenue Breakdown (optional)")
                            .font(.headline)

                        HStack(spacing: 12) {
                            VStack(alignment: .leading) {
                                Text("In-App Purchases")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                HStack {
                                    Text("$")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    TextField("0", text: $inAppPurchases)
                                        .textFieldStyle(.roundedBorder)
                                }
                            }

                            VStack(alignment: .leading) {
                                Text("Subscriptions")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                HStack {
                                    Text("$")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    TextField("0", text: $subscriptions)
                                        .textFieldStyle(.roundedBorder)
                                }
                            }
                        }
                    }

                    // Notes
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Notes (optional)")
                            .font(.headline)
                        TextField("Any additional notes", text: $notes, axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                            .lineLimit(2...3)
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

                Button("Save Revenue") {
                    saveEntry()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!isValid)
                .keyboardShortcut(.return)
            }
            .padding()
        }
        .frame(width: 480, height: 650)
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }

    private func saveEntry() {
        let entry = RevenueEntry(
            date: date,
            period: period,
            grossRevenue: grossRevenueValue,
            netRevenue: netRevenueValue,
            currency: "USD",
            downloads: Int(downloads)
        )

        entry.inAppPurchases = Double(inAppPurchases)
        entry.subscriptions = Double(subscriptions)
        entry.notes = notes.isEmpty ? nil : notes
        entry.project = project

        onSave(entry)
        dismiss()
    }
}

// MARK: - Revenue Entry Row

struct RevenueEntryRow: View {
    let entry: RevenueEntry
    var onDelete: (() -> Void)?

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.formattedDate)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(entry.periodLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(entry.formattedNetRevenue)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(.green)

                if let downloads = entry.downloads {
                    Text("\(downloads) downloads")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if let onDelete = onDelete {
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Revenue History View

struct RevenueHistoryView: View {
    let project: AppProject
    var onAddRevenue: (() -> Void)?
    var onDeleteEntry: ((RevenueEntry) -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "dollarsign.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.green)
                Text("Revenue History")
                    .font(.headline)
                Spacer()

                if let onAdd = onAddRevenue {
                    Button(action: onAdd) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
            }

            if project.sortedRevenueEntries.isEmpty {
                ContentUnavailableView {
                    Label("No Revenue Data", systemImage: "chart.bar")
                } description: {
                    Text("Log your first revenue entry to start tracking")
                } actions: {
                    if let onAdd = onAddRevenue {
                        Button("Log Revenue", action: onAdd)
                            .buttonStyle(.borderedProminent)
                    }
                }
                .frame(height: 150)
            } else {
                VStack(spacing: 0) {
                    ForEach(project.sortedRevenueEntries.prefix(10)) { entry in
                        RevenueEntryRow(entry: entry) {
                            onDeleteEntry?(entry)
                        }
                        if entry.id != project.sortedRevenueEntries.prefix(10).last?.id {
                            Divider()
                        }
                    }
                }

                if project.sortedRevenueEntries.count > 10 {
                    Text("Showing latest 10 entries")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(Color.goalCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Preview

#Preview {
    let project = AppProject(name: "Goals Tracker", platform: .iOS, launchDate: Date())

    return AddRevenueSheet(project: project) { entry in
        print("Added revenue: \(entry.formattedGrossRevenue)")
    }
}
