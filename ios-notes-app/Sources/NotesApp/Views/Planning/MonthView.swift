import SwiftUI
import SwiftData
import NotesShared

struct MonthView: View {

    @Binding var selectedDate: Date
    @Query(sort: \Note.createdAt) private var allNotes: [Note]

    private let columns = Array(repeating: GridItem(.flexible()), count: 7)
    private let weekdaySymbols = Calendar.current.veryShortWeekdaySymbols

    private var monthStart: Date {
        Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: selectedDate)) ?? selectedDate
    }

    private var daysInMonth: [Date?] {
        let cal = Calendar.current
        guard let range = cal.range(of: .day, in: .month, for: monthStart) else { return [] }
        let firstWeekday = cal.component(.weekday, from: monthStart)
        let leadingBlanks = Array(repeating: Date?.none, count: (firstWeekday - cal.firstWeekday + 7) % 7)
        let days = range.map { day -> Date? in
            cal.date(byAdding: .day, value: day - 1, to: monthStart)
        }
        return leadingBlanks + days
    }

    private func notes(for day: Date) -> [Note] {
        let (start, end) = DateFormatters.dayBounds(for: day)
        return allNotes.filter { $0.createdAt >= start && $0.createdAt < end }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Month navigation
            HStack {
                Button {
                    selectedDate = Calendar.current.date(byAdding: .month, value: -1, to: selectedDate) ?? selectedDate
                } label: {
                    Image(systemName: "chevron.left")
                }
                Spacer()
                Text(DateFormatters.monthYear.string(from: selectedDate))
                    .font(.headline)
                Spacer()
                Button {
                    selectedDate = Calendar.current.date(byAdding: .month, value: 1, to: selectedDate) ?? selectedDate
                } label: {
                    Image(systemName: "chevron.right")
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 8)

            // Weekday headers
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(weekdaySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal)

            // Day cells
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(daysInMonth.indices, id: \.self) { i in
                    if let day = daysInMonth[i] {
                        MonthDayCell(
                            day: day,
                            notes: notes(for: day),
                            isSelected: Calendar.current.isDate(day, inSameDayAs: selectedDate)
                        )
                        .onTapGesture { selectedDate = day }
                    } else {
                        Color.clear.frame(height: 44)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

private struct MonthDayCell: View {

    let day: Date
    let notes: [Note]
    let isSelected: Bool

    private var isToday: Bool { Calendar.current.isDateInToday(day) }
    private var hasPersonal: Bool { notes.contains { $0.category == .personal } }
    private var hasWork: Bool { notes.contains { $0.category == .work } }

    var body: some View {
        VStack(spacing: 2) {
            ZStack {
                Circle()
                    .fill(isSelected ? Color.accentColor : (isToday ? Color.accentColor.opacity(0.15) : .clear))
                    .frame(width: 28, height: 28)
                Text(Calendar.current.component(.day, from: day).description)
                    .font(.system(size: 13, weight: isToday ? .bold : .regular))
                    .foregroundStyle(isSelected ? .white : (isToday ? Color.accentColor : AppColor.primaryText))
            }

            // Category dot indicators
            HStack(spacing: 2) {
                if hasPersonal {
                    Circle().fill(NoteCategory.personal.color).frame(width: 4, height: 4)
                }
                if hasWork {
                    Circle().fill(NoteCategory.work.color).frame(width: 4, height: 4)
                }
            }
            .frame(height: 6)
        }
        .frame(height: 44)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color.accentColor.opacity(0.08) : .clear)
        )
    }
}
