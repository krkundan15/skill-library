import SwiftUI

enum PlanningPeriod: String, CaseIterable {
    case day = "Day"
    case week = "Week"
    case month = "Month"
}

struct PlanningView: View {

    @State private var period: PlanningPeriod = .day
    @State private var selectedDate = Date()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Period picker
                Picker("Period", selection: $period) {
                    ForEach(PlanningPeriod.allCases, id: \.self) {
                        Text($0.rawValue).tag($0)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                // View for selected period
                Group {
                    switch period {
                    case .day:   DayView(date: $selectedDate)
                    case .week:  WeekView(selectedDate: $selectedDate)
                    case .month: MonthView(selectedDate: $selectedDate)
                    }
                }
                .animation(.easeInOut(duration: 0.2), value: period)
            }
            .background(AppColor.background)
            .navigationTitle("Plan")
        }
    }
}
