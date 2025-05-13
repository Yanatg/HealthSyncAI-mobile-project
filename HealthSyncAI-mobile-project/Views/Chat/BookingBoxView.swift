import SwiftUI

struct BookingBoxView: View {
    @ObservedObject var viewModel: BookingViewModel // Passed from ChatViewModel
    var onBack: () -> Void // Action to go back to chat

    // For Calendar Display
    @State private var selectedCalendarDate = Date() // Internal state for calendar UI interaction
    private let calendar = Calendar.current
    private let monthFormatter: DateFormatter
    private let dayFormatter: DateFormatter
    private let weekdaySymbols = Calendar.current.shortWeekdaySymbols

     init(viewModel: BookingViewModel, onBack: @escaping () -> Void) {
         self.viewModel = viewModel
         self.onBack = onBack

         // Initialize formatters
         monthFormatter = DateFormatter()
         monthFormatter.dateFormat = "MMMM yyyy"
         dayFormatter = DateFormatter()
         dayFormatter.dateFormat = "d"

         // Set initial selectedDate in ViewModel if not already set
         // Check against a very old date as a proxy for "not set" if necessary,
         // but usually, the ViewModel should handle the default value.
         // if viewModel.selectedDate == Date(timeIntervalSinceReferenceDate: 0) {
         //    viewModel.selectedDate = selectedCalendarDate
         // }
     }


    var body: some View {
        ScrollView { // Make content scrollable if it exceeds screen height
            VStack(alignment: .leading, spacing: 20) {

                // --- Back Button ---
                 Button(action: onBack) {
                     Image(systemName: "arrow.left")
                         .font(.title2.weight(.semibold))
                         .padding(8) // Add padding to increase tap area
                         .background(Color(.systemGray5))
                         .clipShape(Circle())
                 }
                 .padding(.bottom, 5) // Space below back button


                // --- Selected Doctor Info ---
                 if let doctor = viewModel.selectedDoctor {
                     VStack(alignment: .leading, spacing: 4) {
                         Text("Dr. \(doctor.fullName)")
                             .font(.title2).bold()
                         if let spec = doctor.specialization, !spec.isEmpty {
                             Text(spec)
                                 .font(.subheadline)
                                 .foregroundColor(.secondary)
                         }
                         if let exp = doctor.yearsExperience {
                             Text("\(exp) years experience")
                                 .font(.caption)
                                 .foregroundColor(.gray)
                         }
                          if let rating = doctor.rating {
                             HStack {
                                 Image(systemName: "star.fill").foregroundColor(.yellow)
                                 Text(String(format: "%.1f", rating))
                             }
                             .font(.caption)
                             .foregroundColor(.gray)
                         }
                     }
                 } else if viewModel.isLoadingDoctors {
                     ProgressView() // Show loading indicator while doctor loads
                 } else {
                     Text("Select a doctor")
                         .foregroundColor(.secondary)
                 }


                // --- Doctor List ---
                 if !viewModel.doctors.isEmpty {
                     VStack(alignment: .leading) {
                         Text("Other Doctors")
                             .font(.headline)
                         // Use a ScrollView for potentially long lists
                         ScrollView(.horizontal, showsIndicators: false) {
                             HStack(spacing: 15) {
                                 ForEach(viewModel.doctors) { doctor in
                                     DoctorSelectionCard(
                                         doctor: doctor,
                                         isSelected: viewModel.selectedDoctor?.id == doctor.id
                                     ) {
                                         viewModel.selectDoctor(doctor)
                                     }
                                 }
                             }
                             .padding(.vertical, 5) // Add padding inside scroll view
                         }
                     }
                 } else if let error = viewModel.doctorError {
                     Text("Error loading doctors: \(error)")
                         .font(.caption)
                         .foregroundColor(.red)
                 }


                Divider().padding(.vertical, 10)

                // --- Date and Time Selection ---
                 Text("Select Date and Time")
                     .font(.title3).bold()

                 // Custom Calendar View (Simplified)
                 calendarView
                     .padding(.bottom)

                // --- Selected Date Display ---
                 Text("Selected Date: \(viewModel.selectedDate, style: .date)")
                     .font(.headline)


                // --- Time Slot Selection ---
                timeSlotSelectionGrid
            }
            .padding() // Add padding around the entire VStack
        }
        // --- UPDATED onChange ---
        .onChange(of: selectedCalendarDate) { oldValue, newValue in
             // Update ViewModel's selectedDate when the calendar UI changes
             print("Calendar date changed from \(oldValue) to \(newValue)")
             viewModel.selectedDate = newValue
             viewModel.selectedTimeSlot = nil // Reset time slot when date changes
         }
         .onAppear {
            // Sync calendar UI with ViewModel's date on appear
            selectedCalendarDate = viewModel.selectedDate
         }
    }

    // MARK: - Calendar View Components

     private var calendarView: some View {
         VStack {
             // Header with Month and Navigation
             HStack {
                 Button { changeMonth(by: -1) } label: { Image(systemName: "chevron.left") }
                 Spacer()
                 Text(monthFormatter.string(from: selectedCalendarDate))
                     .font(.headline)
                 Spacer()
                 Button { changeMonth(by: 1) } label: { Image(systemName: "chevron.right") }
             }
             .padding(.bottom, 5)

             // Weekday Symbols
             HStack {
                 ForEach(weekdaySymbols, id: \.self) { symbol in
                     Text(symbol)
                         .font(.caption)
                         .frame(maxWidth: .infinity)
                 }
             }

             // Days Grid
             LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 10) {
                 let daysInMonth = calculateDaysInMonth(for: selectedCalendarDate)
                 let firstWeekday = calculateFirstWeekdayOfMonth(for: selectedCalendarDate)
                 let today = Date()

                 // Empty cells before the first day
                 ForEach(0..<firstWeekday, id: \.self) { _ in
                     Text("")
                 }

                 // Actual days
                 ForEach(daysInMonth, id: \.self) { dayDate in
                     let dayNumber = dayFormatter.string(from: dayDate)
                     let isSelected = calendar.isDate(dayDate, inSameDayAs: selectedCalendarDate)
                     let isPast = calendar.compare(dayDate, to: today, toGranularity: .day) == .orderedAscending && !calendar.isDate(dayDate, inSameDayAs: today)

                     Button {
                         if !isPast {
                             selectedCalendarDate = dayDate
                         }
                     } label: {
                         Text(dayNumber)
                             .frame(maxWidth: .infinity)
                             .padding(.vertical, 8)
                              .background(isSelected ? Color.accentColor : Color.clear)
                             .foregroundColor(isSelected ? .white : (isPast ? .gray : .primary))
                             .clipShape(Circle())
                     }
                     .disabled(isPast)
                 }
             }
         }
         .padding(.horizontal, 5) // Padding for the calendar container
     }


     // MARK: - Time Slot Selection Grid
    private var timeSlotSelectionGrid: some View {
        // Use LazyVGrid for adaptive layout
         LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 10) {
            ForEach(viewModel.availableTimeSlots, id: \.self) { time in
                Button {
                    viewModel.selectTime(time)
                } label: {
                    Text(time)
                        .font(.system(size: 14))
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity) // Make buttons fill width
                        .background(viewModel.selectedTimeSlot == time ? Color.accentColor.opacity(0.2) : Color(.systemGray6))
                        .foregroundColor(viewModel.selectedTimeSlot == time ? Color.accentColor : .primary)
                        .cornerRadius(8)
                         .overlay(
                             RoundedRectangle(cornerRadius: 8)
                                .stroke(viewModel.selectedTimeSlot == time ? Color.accentColor : Color.clear, lineWidth: 1)
                         )
                }
                 .buttonStyle(.plain) // Use plain style to avoid default button highlighting interfering
            }
        }
    }

    // MARK: - Calendar Helper Functions

    // --- UPDATED calculateDaysInMonth ---
    private func calculateDaysInMonth(for date: Date) -> [Date] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: date) else {
            print("Error: Could not calculate month interval for \(date)")
            return []
        }

        var dates: [Date] = []
        var currentDate = monthInterval.start
        while currentDate < monthInterval.end {
            dates.append(currentDate)
            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else {
                print("Error: Could not increment day for \(currentDate)")
                break // Exit loop if date calculation fails
            }
            currentDate = nextDate
        }
        return dates
    }
    // --- End Update ---

    private func calculateFirstWeekdayOfMonth(for date: Date) -> Int {
        guard let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: date)) else {
            return 0
        }
        // Adjust for calendar starting on Sunday (1) vs. weekdaySymbols starting Monday (index 0)
        // Or adjust weekdaySymbols array based on your locale/preference
        let weekday = calendar.component(.weekday, from: monthStart) // 1 = Sun, 2 = Mon, ... 7 = Sat
        return (weekday - calendar.firstWeekday + 7) % 7 // Adjust to be 0-indexed (assuming firstWeekday=1 for Sun)
        // If firstWeekday is 2 (Monday), calculation is simpler: (weekday - 2 + 7) % 7
    }

    private func changeMonth(by amount: Int) {
        if let newDate = calendar.date(byAdding: .month, value: amount, to: selectedCalendarDate) {
            selectedCalendarDate = newDate
            viewModel.selectedDate = newDate // Also update the ViewModel's date
            viewModel.selectedTimeSlot = nil // Reset time when month changes
        }
    }
}

// MARK: - Doctor Selection Card
struct DoctorSelectionCard: View {
    let doctor: Doctor
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                // Initials Circle
                 Text(doctor.initials)
                     .font(.caption.weight(.bold))
                     .frame(width: 30, height: 30)
                     .background(isSelected ? Color.accentColor : Color.gray.opacity(0.3))
                     .foregroundColor(isSelected ? .white : .primary)
                     .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text("Dr. \(doctor.lastName)")
                        .font(.system(size: 14, weight: .medium))
                         .foregroundColor(isSelected ? Color.accentColor : .primary)
                    if let spec = doctor.specialization, !spec.isEmpty {
                         Text(spec)
                             .font(.caption)
                             .foregroundColor(.secondary)
                     }
                }
            }
            .padding(8)
            .background(isSelected ? Color.accentColor.opacity(0.1) : Color(.systemGray6))
            .cornerRadius(8)
             .overlay(
                 RoundedRectangle(cornerRadius: 8)
                     .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 1.5)
             )
        }
         .buttonStyle(.plain) // Prevent default button styling
    }
}


// --- Preview ---
struct BookingBoxView_Previews: PreviewProvider {
    static var previews: some View {
         // Create a dummy ViewModel for preview
         let previewViewModel = BookingViewModel()
         previewViewModel.doctors = [
             Doctor(id: 1, firstName: "Alice", lastName: "Smith", specialization: "Cardiology", yearsExperience: 10, rating: 4.8),
             Doctor(id: 2, firstName: "Bob", lastName: "Jones", specialization: "Pediatrics", yearsExperience: 5, rating: 4.5),
             Doctor(id: 3, firstName: "Charlie", lastName: "Davis", specialization: "Neurology", yearsExperience: 15, rating: 4.9)
         ]
         previewViewModel.selectedDoctor = previewViewModel.doctors[0]

         return BookingBoxView(viewModel: previewViewModel, onBack: {})
    }
}
