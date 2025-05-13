import Foundation

struct StatisticsData: Codable, Identifiable {
    // Use an ID if needed for lists, otherwise optional. Can use a computed one.
    var id = UUID()

    let totalUsers: Int
    let totalDoctors: Int
    let totalPatients: Int
    let totalAppointments: Int
    let totalChatSessions: Int
    let totalHealthRecords: Int
    let totalTriageRecords: Int
    let totalDoctorNotes: Int

    enum CodingKeys: String, CodingKey {
        case totalUsers = "total_users"
        case totalDoctors = "total_doctors"
        case totalPatients = "total_patients"
        case totalAppointments = "total_appointments"
        case totalChatSessions = "total_chat_sessions"
        case totalHealthRecords = "total_health_records"
        case totalTriageRecords = "total_triage_records"
        case totalDoctorNotes = "total_doctor_notes"
    }
}
