// HealthSyncAI-mobile-project/Views/Shared/SplashScreenView.swift
// NEW FILE

import SwiftUI

struct SplashScreenView: View {
    var body: some View {
        ZStack {
            // Background Color (Optional - match your app's theme)
            // Color(.systemBackground) // Use system background
            Color("Primblue") // Or a specific color like your app's accent
                .ignoresSafeArea() // Fill the entire screen

            // Your Icon
            VStack {
                // --- Option A: If you have a custom icon asset named "PlusIcon" ---
                 Image("plus") // Replace "PlusIcon" with your actual asset name
                     .resizable()
                     .scaledToFit()
                     .frame(width: 100, height: 100) // Adjust size as needed
                     // .foregroundColor(.accentColor) // Optional: Apply tint

//                 Optional: App Name Text
                 Text("HealthSyncAI")
                    .font(.title2)
                    .padding(.top)
                    .foregroundStyle(.white)
                    
            }
        }
    }
}

// MARK: - Preview
#Preview {
    SplashScreenView()
}

extension Color {
    init(hex: Int, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xff) / 255,
            green: Double((hex >> 08) & 0xff) / 255,
            blue: Double((hex >> 00) & 0xff) / 255,
            opacity: opacity
        )
    }
}
