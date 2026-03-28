import SwiftUI
import SwiftData
import NotesShared

struct WeekView: View {

    @Binding var selectedDate: Date
    @Query(sort: \Note.createdAt, order: .reverse) private var allNotes: [Note]

    private var weekDays: [Date] { DateFormatters.week(containing: selectedDate) }

    private func notes(for day: Date) -> [Note] {
        let (start, end) = DateFormatters.dayBounds(for: day)
        return allNotes.filter { $0.createdAt >= start && $0.createdAt < end }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Week navigation
            HStack {
                Button {
                    selectedDate = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: selectedDate)!
                } label: {
                    Image(systemName: "chevron.left")
                }

                Spacer()
                Text("Week of \(DateFormatters.shortDate.string(from: weekDays.first ?? selectedDate))")
                    .font(.headline)
                Spacer()

                Button {
                    selectedDate = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: selectedDate)!
                } label: {
                    Image(systemName: "chevron.right")
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 8)

            // 7-column header
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(weekDays, id: \.self) { day in
                        WeekDayColumn(
                            day: day,
                            notes: notes(for: day),
                            isSelected: Calendar.current.isDate(day, inSameDayAs: selectedDate)
                        )
                        .onTapGesture { selectedDate = day }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

private struct WeekDayColumn: View {

    let day: Date
    let notes: [Note]
    let isSelected: Bool

    private var allActions: [ActionItem] { notes.flatMap { $0.actionItems } }
    private var isToday: Bool { Calendar.current.isDateInToday(day) }

    var body: some View {
        VStack(spacing: 6) {
            // Day header
            VStack(spacing: 2) {
                Text(DateFormatters.weekday.string(from: day).uppercased())
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(isToday ? Color.accentColor : .secondary)

                ZStack {
                    Circle()
                        .fill(isSelected ? Color.accentColor : (isToday ? Color.accentColor.opacity(0.15) : Color.clear))
                        .frame(width: 30, height: 30)
                    Text(Calendar.current.component(.day, from: day).description)
                        .font(.subheadline.weight(isToday ? .bold : .regular))
                        .foregroundStyle(isSelected ? .white : (isToday ? Color.accentColor : AppColor.primaryText))
                }
            }

            // Note count bubble
            if !notes.isEmpty {
                HStack(spacing: 2) {
                    Circle().fill(NoteCategory.personal.color)
                        .frame(width: 6, height: 6)
                        .opacity(notes.contains { $0.category == .personal } ? 1 : 0)
                    Circle().fill(NoteCategory.work.color)
                        .frame(width: 6, height: 6)
                        .opacity(notes.contains { $0.category == .work } ? 1 : 0)
                }

                Text("\(notes.count)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(width: 20, height: 20)
                    .background(Color.accentColor)
                    .clipShape(Circle())
            }

            // Up to 3 action titles
            VStack(alignment: .leading, spacing: 3) {
                ForEach(allActions.prefix(3)) { item in
                    Text("• \(item.title)")
                        .font(.system(size: 9))
                        .foregroundStyle(item.isCompleted ? .secondary : AppColor.primaryText)
                        .strikethrough(item.isCompleted)
                        .lineLimit(2)
                }
            }
            .frame(width: 90, alignment: .leading)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 6)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? Color.accentColor.opacity(0.08) : AppColor.cardBackground)
        )
        .frame(width: 100)
    }
}
