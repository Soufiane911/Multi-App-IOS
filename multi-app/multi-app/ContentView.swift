//
//  ContentView.swift
//  multi-app
//
//  Created by Soufiane Hamzaoui on 06/05/2025.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    // Définition de la couleur de fond bleue claire
    private let lightBlueBackground = Color(red: 0.9, green: 0.95, blue: 1.0)
    
    var body: some View {
        ZStack {
            // Fond bleu clair en mode light
            if !isDarkMode {
                lightBlueBackground
                    .ignoresSafeArea()
            } else {
                Color.black.opacity(0.05)
                    .ignoresSafeArea()
            }
            
            // Contenu principal
            if hasCompletedOnboarding {
                MainTabView(isDarkMode: $isDarkMode)
            } else {
                WelcomeView(hasCompletedOnboarding: $hasCompletedOnboarding)
            }
        }
        .preferredColorScheme(isDarkMode ? .dark : .light)
    }
}

#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
