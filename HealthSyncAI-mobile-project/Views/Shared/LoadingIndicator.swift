import SwiftUI

struct LoadingIndicator: View {
    let message: String?

    init(_ message: String? = nil) {
        self.message = message
    }

    var body: some View {
        HStack(spacing: 10) {
            ProgressView()
            if let msg = message {
                Text(msg)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(.thinMaterial) // Use material background
        .cornerRadius(10)
    }
}

struct LoadingIndicator_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            LoadingIndicator()
            LoadingIndicator("Loading chats...")
        }
    }
}
