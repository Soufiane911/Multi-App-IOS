import SwiftUI

struct ProfileView: View {
    @Binding var isDarkMode: Bool
    @State private var showingReminderSettings = false
    @Namespace private var animation
    
    private let gradient = LinearGradient(
        colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.8)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    // En-tête du profil avec animation
                    VStack(spacing: 15) {
                        // Avatar fixe, sans animation de rotation
                        Circle()
                            .fill(gradient)
                            .frame(width: 80, height: 80)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.white)
                            )
                            .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                        
                        Text("Mon Profil")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(gradient)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .listRowBackground(Color.clear)
                }
                
                Section {
                    // Bouton Notifications avec animation hover
                    Button(action: {
                        withAnimation(.spring()) {
                            showingReminderSettings = true
                        }
                    }) {
                        HStack {
                            Label {
                                Text("Notifications")
                            } icon: {
                                Image(systemName: "bell.fill")
                                    .foregroundColor(.white)
                                    .padding(8)
                                    .background(gradient)
                                    .clipShape(Circle())
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.gray)
                        }
                    }
                    .buttonStyle(ProfileButtonStyle())
                    
                    // Toggle Mode Sombre avec animation
                    HStack {
                        Label {
                            Text("Mode Sombre")
                        } icon: {
                            Image(systemName: isDarkMode ? "moon.fill" : "sun.max.fill")
                                .foregroundColor(.white)
                                .padding(8)
                                .background(gradient)
                                .clipShape(Circle())
                                .rotationEffect(.degrees(isDarkMode ? 360 : 0))
                                .animation(.spring(response: 0.5, dampingFraction: 0.6), value: isDarkMode)
                        }
                        
                        Spacer()
                        
                        Toggle("", isOn: $isDarkMode)
                            .tint(.blue)
                    }
                } header: {
                    Text("Préférences")
                        .textCase(.uppercase)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Section {
                    // Statistiques avec animation
                    HStack {
                        ProfileStatView(title: "Notes", value: "12", icon: "note.text", gradient: gradient)
                        ProfileStatView(title: "Tâches", value: "8", icon: "checkmark.circle", gradient: gradient)
                        ProfileStatView(title: "Habitudes", value: "5", icon: "calendar", gradient: gradient)
                    }
                    .padding(.vertical, 10)
                } header: {
                    Text("Statistiques")
                        .textCase(.uppercase)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Section {
                    Link(destination: URL(string: "https://www.example.com/aide")!) {
                        Label("Aide et Support", systemImage: "questionmark.circle")
                    }
                    .buttonStyle(ProfileButtonStyle())
                    
                    Link(destination: URL(string: "https://www.example.com/confidentialite")!) {
                        Label("Politique de confidentialité", systemImage: "lock.shield")
                    }
                    .buttonStyle(ProfileButtonStyle())
                } header: {
                    Text("Support")
                        .textCase(.uppercase)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Section {
                    HStack {
                        Text("Version 1.0.0")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("2025")
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("À propos")
                        .textCase(.uppercase)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $showingReminderSettings) {
            ReminderSettingsView()
        }
    }
}

// Style de bouton animé spécifique au profil
struct ProfileButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.spring(response: 0.3), value: configuration.isPressed)
    }
}

// Vue pour les statistiques spécifique au profil
struct ProfileStatView: View {
    let title: String
    let value: String
    let icon: String
    let gradient: LinearGradient
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundStyle(gradient)
                .scaleEffect(isAnimating ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: isAnimating)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(gradient)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .onAppear {
            isAnimating = true
        }
    }
}
