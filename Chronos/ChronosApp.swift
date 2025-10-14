//
//  ChronosApp.swift
//  Chronos
//
//  Created by Atharva Gour on 09/02/25.
//

import SwiftUI

@main
struct ChronosApp: App {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding: Bool = false
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .sheet(isPresented: .constant(!hasSeenOnboarding)) {
                    OnboardingView()
                }
        }
    }
}
