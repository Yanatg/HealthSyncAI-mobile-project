// HealthSyncAI-mobile-project/Views/Chat/ChatMessageView.swift
// NEW FILE
import SwiftUI
// If using MarkdownUI: import MarkdownUI

struct ChatMessageView: View {
    let message: DisplayMessage

    var body: some View {
        HStack {
            if message.sender == .user {
                Spacer() // Push user messages to the right
            }

            // TODO: Replace Text with Markdown rendering if needed
            Text(message.text)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .font(.system(size: 16)) // Match React's text-[14px] roughly
                .foregroundColor(message.sender == .user ? .white : Color(.label)) // Use system label color for bot text
                .background(message.sender == .user ? Color.accentColor : Color(.systemGray5)) // Use system gray for bot background
                .clipShape(RoundedRectangle(cornerRadius: 16)) // Use standard corner radius
                /* Apply different corner rounding based on sender (like React) */
//                .clipShape(ChatBubbleShape(isFromCurrentUser: message.sender == .user))

            if message.sender == .bot {
                Spacer() // Push bot messages to the left
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 2) // Small vertical padding between messages
    }
}

// --- Optional: Custom Shape for Chat Bubbles ---
// Uncomment and use this in .clipShape above if you want the specific corner rounding
/*
struct ChatBubbleShape: Shape {
    let isFromCurrentUser: Bool

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect,
                                byRoundingCorners: isFromCurrentUser
                                    ? [.topLeft, .bottomLeft, .bottomRight]
                                    : [.topRight, .bottomLeft, .bottomRight], // Adjust corners for bot
                                cornerRadii: CGSize(width: 16, height: 16))
        return Path(path.cgPath)
    }
}
*/

// --- Preview ---
struct ChatMessageView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            ChatMessageView(message: DisplayMessage(sender: .user, text: "Hello, I have a cough."))
            ChatMessageView(message: DisplayMessage(sender: .bot, text: "Okay, how long have you had the cough?"))
            ChatMessageView(message: DisplayMessage(sender: .bot, text: "Here is some *markdown* text with a [link](https://example.com). \n\nAnd another paragraph.")) // Example with markdown
        }
        .padding()
    }
}
