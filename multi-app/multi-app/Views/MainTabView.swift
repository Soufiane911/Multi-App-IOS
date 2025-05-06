import SwiftUI
import UIKit

struct MainTabView: View {
    @State private var selectedTab = 0
    @Binding var isDarkMode: Bool
    @Namespace private var animation
    
    // Paramètres des onglets
    private let tabs = [
        TabItem(title: "Tableau", icon: "chart.bar.fill", selectedIcon: "chart.bar.fill"),
        TabItem(title: "Tâches", icon: "checklist", selectedIcon: "checklist.checked"),
        TabItem(title: "Habitudes", icon: "calendar", selectedIcon: "calendar.badge.clock"),
        TabItem(title: "Notes", icon: "note.text", selectedIcon: "note.text.badge.plus"),
        TabItem(title: "Profil", icon: "person.circle", selectedIcon: "person.circle.fill")
    ]
    
    // Nouvelle palette de couleurs
    private var gradient: LinearGradient {
        LinearGradient(
            colors: [Color.primaryColor, Color.primaryColor.opacity(0.7)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // Couleur de fond bleue claire
    private let lightBlueBackground = Color(red: 0.9, green: 0.95, blue: 1.0)
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // AJOUT: Fond bleu clair si mode clair
            if !isDarkMode {
                lightBlueBackground
                    .ignoresSafeArea()
            }

            TabView(selection: $selectedTab) {
                DashboardView(isDarkMode: $isDarkMode)
                    .tag(0)
                
                TasksView()
                    .tag(1)
                
                HabitsView()
                    .tag(2)
                
                NotesView()
                    .tag(3)
                
                ProfileView(isDarkMode: $isDarkMode)
                    .tag(4)
            }
            .ignoresSafeArea(edges: .bottom)
            
            // Barre d'onglets personnalisée plus petite et en bas
            HStack {
                ForEach(0..<tabs.count, id: \.self) { index in
                    let tab = tabs[index]
                    Spacer()
                    
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedTab = index
                        }
                    } label: {
                        VStack(spacing: 3) {
                            ZStack {
                                if selectedTab == index {
                                    Circle()
                                        .fill(gradient)
                                        .matchedGeometryEffect(id: "TabBackground", in: animation)
                                        .frame(width: 36, height: 36)
                                        .shadow(color: .red.opacity(0.2), radius: 4, x: 0, y: 2)
                                }
                                
                                Image(systemName: selectedTab == index ? tab.selectedIcon : tab.icon)
                                    .font(.system(size: 15, weight: selectedTab == index ? .semibold : .regular))
                                    .foregroundColor(selectedTab == index ? .white : .gray)
                            }
                            
                            Text(tab.title)
                                .font(.system(size: 9))
                                .fontWeight(selectedTab == index ? .medium : .regular)
                                .foregroundColor(selectedTab == index ? Color.primaryColor : .gray)
                        }
                    }
                    .scaleEffect(selectedTab == index ? 1.05 : 1.0)
                    
                    Spacer()
                }
            }
            .padding(.top, 6)
            .padding(.bottom, 6)
            .background(
                Rectangle()
                    .fill(.ultraThinMaterial.opacity(0.8))
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: -3)
                    .edgesIgnoringSafeArea(.bottom)
            )
            .clipShape(
                CustomShape()
            )
        }
    }
}

// Structure pour les éléments de la barre d'onglets
struct TabItem {
    let title: String
    let icon: String
    let selectedIcon: String
}

// Forme personnalisée pour la barre de navigation (coins supérieurs arrondis uniquement)
struct CustomShape: Shape {
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: [.topLeft, .topRight],
            cornerRadii: CGSize(width: 20, height: 20)
        )
        return Path(path.cgPath)
    }
}

#Preview {
    MainTabView(isDarkMode: .constant(false))
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
