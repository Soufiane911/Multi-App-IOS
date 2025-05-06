import SwiftUI
import CoreData

struct DashboardView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.colorScheme) private var colorScheme
    @State private var showProfileMenu = false
    @State private var showingAdvancedStats = false
    @Binding var isDarkMode: Bool
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Task.creationDate, ascending: false)],
        predicate: NSPredicate(format: "isPriority == true AND completed == false"),
        animation: .default)
    private var priorityTasks: FetchedResults<Task>
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Habit.creationDate, ascending: true)],
        animation: .default)
    private var habits: FetchedResults<Habit>
    
    // Statistiques
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Task.creationDate, ascending: true)],
        animation: .default)
    private var allTasks: FetchedResults<Task>
    
    // Jours de la semaine
    private let weekdays = ["D", "L", "M", "M", "J", "V", "S"]
    
    // Utilisation des couleurs centralisées
    private var primaryColor: Color { Color.red.opacity(0.8) }
    private var secondaryColor: Color { Color(red: 0.3, green: 0.5, blue: 0.9) }
    private var accentColor: Color { Color(red: 0.9, green: 0.6, blue: 0.3) }
    
    // Définition de la couleur de fond bleue claire
    private let lightBlueBackground = Color(red: 0.9, green: 0.95, blue: 1.0)

    var body: some View {
        NavigationView {
            ZStack {
                // Fond bleu clair seulement en mode light
                if colorScheme == .light {
                    lightBlueBackground
                        .ignoresSafeArea()
                }
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        // En-tête avec date et profil
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Tableau de bord")
                                    .font(.system(size: 34, weight: .bold))
                                    .foregroundColor(Color.red.opacity(0.8))
                                
                                Text(today)
                                    .font(.callout)
                                    .foregroundColor(.white)
                            }
                            
                            Spacer()
                            
                            // Bouton de stats amélioré
                            Button {
                                showingAdvancedStats = true
                            } label: {
                                Image(systemName: "chart.xyaxis.line")
                                    .font(.system(size: 20))
                                    .foregroundColor(.white)
                                    .padding(10)
                                    .background(Color(red: 0.3, green: 0.5, blue: 0.9))
                                    .clipShape(Circle())
                                    .shadow(radius: 5)
                            }
                            .padding(.trailing, 8)
                            
                            // Menu profil
                            Button {
                                showProfileMenu.toggle()
                            } label: {
                                Circle()
                                    .fill(Color.red.opacity(0.8))
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Image(systemName: "person.crop.circle.fill")
                                            .font(.system(size: 22))
                                            .foregroundColor(.white)
                                    )
                                    .shadow(radius: 5)
                            }
                            .popover(isPresented: $showProfileMenu) {
                                ProfileMenuView(isDarkMode: $isDarkMode)
                            }
                        }
                        .padding(.horizontal)
                        
                        // Message motivant avec style amélioré
                        Text(motivationalMessage())
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(Color(red: 0.3, green: 0.5, blue: 0.9).opacity(0.6))
                            .cornerRadius(12)
                            .padding(.horizontal)
                        
                        // Stats des tâches
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Résumé")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.horizontal)
                            
                            HStack(spacing: 15) {
                                StatCard(
                                    title: "Tâches",
                                    value: "\(allTasks.count)",
                                    icon: "checklist",
                                    color: Color(red: 0.3, green: 0.5, blue: 0.9)
                                )
                                
                                StatCard(
                                    title: "Terminées",
                                    value: "\(allTasks.filter { $0.completed }.count)",
                                    icon: "checkmark.circle",
                                    color: Color(red: 0.9, green: 0.6, blue: 0.3)
                                )
                                
                                StatCard(
                                    title: "Prioritaires",
                                    value: "\(allTasks.filter { $0.isPriority }.count)",
                                    icon: "star.fill",
                                    color: Color.red.opacity(0.8)
                                )
                            }
                            .padding(.horizontal)
                        }
                        .padding(.vertical)
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color(red: 0.3, green: 0.5, blue: 0.9).opacity(0.5))
                                .shadow(color: Color.blue.opacity(0.15), radius: 5, x: 0, y: 2)
                        )
                        .padding(.horizontal)
                        
                        // Priority Tasks Section
                        VStack(alignment: .leading, spacing: 15) {
                            HStack {
                                Text("Tâches prioritaires")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                NavigationLink(destination: TasksView()) {
                                    HStack(spacing: 4) {
                                        Text("Voir tout")
                                            .font(.caption)
                                        
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 9, weight: .semibold))
                                    }
                                    .foregroundColor(.white)
                                    .padding(.vertical, 6)
                                    .padding(.horizontal, 10)
                                    .background(Color.red.opacity(0.6))
                                    .cornerRadius(15)
                                }
                            }
                            .padding(.horizontal)
                            
                            if priorityTasks.isEmpty {
                                HStack {
                                    Spacer()
                                    VStack(spacing: 10) {
                                        Image(systemName: "star.slash")
                                            .font(.largeTitle)
                                            .foregroundColor(.white)
                                            .padding()
                                            .background(Circle().fill(Color.red.opacity(0.4)))
                                        
                                        Text("Aucune tâche prioritaire")
                                            .fontWeight(.medium)
                                            .foregroundColor(.white)
                                        
                                        Text("Pour ajouter une tâche prioritaire, allez dans l'onglet Tâches")
                                            .font(.caption)
                                            .foregroundColor(.white)
                                            .multilineTextAlignment(.center)
                                            .padding(.horizontal)
                                    }
                                    .padding()
                                    Spacer()
                                }
                            } else {
                                ForEach(priorityTasks) { task in
                                    TaskRow(task: task)
                                }
                                .padding(.horizontal)
                            }
                        }
                        .padding(.vertical)
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color.red.opacity(0.5))
                                .shadow(color: Color.red.opacity(0.15), radius: 5, x: 0, y: 2)
                        )
                        .padding(.horizontal)
                        
                        // Habits Tracking Section - Version simplifiée
                        VStack(alignment: .leading, spacing: 15) {
                            HStack {
                                Text("Suivi des habitudes")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                NavigationLink(destination: HabitsView()) {
                                    HStack(spacing: 4) {
                                        Text("Voir tout")
                                            .font(.caption)
                                        
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 9, weight: .semibold))
                                    }
                                    .foregroundColor(.white)
                                    .padding(.vertical, 6)
                                    .padding(.horizontal, 10)
                                    .background(Color(red: 0.9, green: 0.6, blue: 0.3).opacity(0.6))
                                    .cornerRadius(15)
                                }
                            }
                            .padding(.horizontal)
                            
                            if habits.isEmpty {
                                HStack {
                                    Spacer()
                                    VStack(spacing: 10) {
                                        Image(systemName: "calendar.badge.exclamationmark")
                                            .font(.largeTitle)
                                            .foregroundColor(.gray)
                                            .padding()
                                            .background(Circle().fill(Color.black.opacity(0.5)))
                                        
                                        Text("Aucune habitude à suivre")
                                            .fontWeight(.medium)
                                            .foregroundColor(.white)
                                        
                                        Text("Pour ajouter des habitudes, allez dans l'onglet Habitudes")
                                            .font(.caption)
                                            .foregroundColor(.white)
                                            .multilineTextAlignment(.center)
                                            .padding(.horizontal)
                                    }
                                    .padding()
                                    Spacer()
                                }
                            } else {
                                // Graphique simplifié
                                VStack(spacing: 15) {
                                    HStack {
                                        Text("Progression hebdomadaire")
                                            .font(.headline)
                                            .foregroundColor(.white)
                                        Spacer()
                                        Text("\(averageCompletionPercentage())%")
                                            .font(.headline)
                                            .foregroundColor(.white)
                                            .padding(.vertical, 2)
                                            .padding(.horizontal, 8)
                                            .background(Color(red: 0.9, green: 0.6, blue: 0.3).opacity(0.6))
                                            .cornerRadius(10)
                                    }
                                    .padding(.horizontal)
                                    
                                    // Graphique en barres simplifié avec animation
                                    HStack(spacing: 8) {
                                        ForEach(0..<7, id: \.self) { day in
                                            VStack(spacing: 8) {
                                                Spacer()
                                                
                                                RoundedRectangle(cornerRadius: 6)
                                                    .fill(colorForPercentage(completionPercentage(for: day)))
                                                    .frame(height: max(20, 100 * Double(completionPercentage(for: day)) / 100))
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 6)
                                                            .stroke(Color.white, lineWidth: 1)
                                                    )
                                                
                                                Text(weekdays[day])
                                                    .font(.caption2)
                                                    .foregroundColor(.white)
                                            }
                                            .frame(height: 120)
                                            .frame(maxWidth: .infinity)
                                            .overlay(
                                                Group {
                                                    if isTodayIndex(day) {
                                                        RoundedRectangle(cornerRadius: 6)
                                                            .stroke(Color(red: 0.9, green: 0.8, blue: 0.3), lineWidth: 1)
                                                            .padding(.bottom, 22)
                                                    }
                                                }
                                            )
                                        }
                                    }
                                    .padding(.horizontal)
                                    .padding(.top, 5)
                                    .animation(.spring(), value: habits.count)
                                    
                                    // Statistiques pour aujourd'hui
                                    if let todayIndex = getTodayIndex(), habits.count > 0 {
                                        HStack {
                                            Spacer()
                                            
                                            VStack(spacing: 4) {
                                                Text("Aujourd'hui")
                                                    .font(.caption)
                                                    .foregroundColor(.white)
                                                
                                                Text("\(completionPercentage(for: todayIndex))% complété")
                                                    .font(.caption)
                                                    .fontWeight(.medium)
                                                    .foregroundColor(.white)
                                            }
                                            .padding(.vertical, 8)
                                            .padding(.horizontal, 12)
                                            .background(Color(red: 0.3, green: 0.5, blue: 0.9).opacity(0.6))
                                            .cornerRadius(10)
                                            
                                            Spacer()
                                        }
                                        .padding(.top, 5)
                                    }
                                }
                            }
                        }
                        .padding(.vertical)
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color.black.opacity(0.6))
                                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                        )
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
            }
            .sheet(isPresented: $showingAdvancedStats) {
                AdvancedStatsView()
            }
            .navigationBarHidden(true)
        }
    }
    
    // Vérifier si l'index correspond à aujourd'hui
    private func isTodayIndex(_ index: Int) -> Bool {
        return index == Calendar.current.component(.weekday, from: Date()) - 1
    }
    
    // Obtenir l'index du jour actuel
    private func getTodayIndex() -> Int? {
        return Calendar.current.component(.weekday, from: Date()) - 1
    }
    
    // Calculer le pourcentage de complétion pour un jour spécifique
    private func completionPercentage(for day: Int) -> Int {
        if habits.isEmpty {
            return 0
        }
        
        var completedHabits = 0
        for habit in habits {
            if isHabitCompletedForDay(habit, day: day) {
                completedHabits += 1
            }
        }
        
        return Int((Double(completedHabits) / Double(habits.count)) * 100)
    }
    
    // Vérifier si une habitude est complétée pour le jour spécifié
    private func isHabitCompletedForDay(_ habit: Habit, day: Int) -> Bool {
        guard let completions = habit.completions as? Set<HabitCompletion> else {
            return false
        }
        
        // Obtenir la date du jour spécifié dans la semaine courante
        let currentDate = Date()
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: currentDate) - 1  // 0 = dimanche
        let daysToSubtract = (weekday - day + 7) % 7
        
        let targetDate = calendar.date(byAdding: .day, value: -daysToSubtract, to: currentDate)!
        let startOfTargetDay = calendar.startOfDay(for: targetDate)
        let endOfTargetDay = calendar.date(byAdding: .day, value: 1, to: startOfTargetDay)!
        
        return completions.contains { completion in
            guard let date = completion.date else { return false }
            return date >= startOfTargetDay && date < endOfTargetDay
        }
    }
    
    // Calculer le pourcentage moyen sur la semaine
    private func averageCompletionPercentage() -> Int {
        var total = 0
        for day in 0..<7 {
            total += completionPercentage(for: day)
        }
        return total / 7
    }
    
    // Couleur basée sur le pourcentage
    private func colorForPercentage(_ percentage: Int) -> Color {
        if percentage >= 75 {
            return Color(red: 0.3, green: 0.5, blue: 0.9)
        } else if percentage >= 50 {
            return Color(red: 0.9, green: 0.6, blue: 0.3)
        } else if percentage >= 25 {
            return Color.red.opacity(0.7)
        } else if percentage > 0 {
            return Color(red: 0.3, green: 0.5, blue: 0.9).opacity(0.4)
        } else {
            return Color.gray.opacity(0.3)
        }
    }
    
    // Message motivant basé sur l'heure
    private func motivationalMessage() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        
        if hour < 12 {
            return "Bonne journée ! Commencez fort avec vos tâches prioritaires."
        } else if hour < 17 {
            return "Continuez sur votre lancée ! Vous pouvez accomplir beaucoup aujourd'hui."
        } else {
            return "Belle soirée ! Prenez le temps de planifier vos tâches pour demain."
        }
    }
    
    // Date du jour
    private var today: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE d MMMM"
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter.string(from: Date()).capitalized
    }
}

// Modification du StatCard pour un style plus moderne
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            // Icône avec nouveau style
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [color.opacity(0.8), color.opacity(0.4)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 50, height: 50)
                
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.white)
            }
            .shadow(color: color.opacity(0.3), radius: 5, x: 0, y: 3)
            
            // Valeur avec style amélioré
            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
            
            // Titre
            Text(title)
                .font(.caption)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 15)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(color.opacity(0.5))
                .shadow(color: color.opacity(0.2), radius: 10, x: 0, y: 5)
        )
    }
}

// TaskRow avec style amélioré
struct TaskRow: View {
    @ObservedObject var task: Task
    @Environment(\.managedObjectContext) private var viewContext
    
    var body: some View {
        HStack {
            Button {
                task.completed.toggle()
                try? viewContext.save()
            } label: {
                Image(systemName: task.completed ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(task.completed ? Color(red: 0.9, green: 0.6, blue: 0.3) : .white)
                    .font(.title2)
            }
            .buttonStyle(ScaleButtonStyle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title ?? "Tâche sans titre")
                    .strikethrough(task.completed)
                    .foregroundColor(.white)
                    .fontWeight(.medium)
                
                if let date = task.creationDate {
                    Text("Ajoutée le \(dateFormatter.string(from: date))")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            
            Spacer()
            
            Image(systemName: "star.fill")
                .foregroundColor(Color(red: 0.9, green: 0.8, blue: 0.3))
                .font(.subheadline)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 15)
        .background(
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .fill(Color.red.opacity(0.4))
                .shadow(color: Color.red.opacity(0.15), radius: 5, x: 0, y: 3)
        )
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter
    }
}

// Nouveau ButtonStyle pour une meilleure interaction
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}

// Nouvelle vue pour le menu profil
struct ProfileMenuView: View {
    @Binding var isDarkMode: Bool
    @State private var showingReminderSettings = false
    
    var body: some View {
        VStack(spacing: 20) {
            // En-tête
            Text("Paramètres")
                .font(.headline)
                .padding(.top)
            
            Divider()
            
            // Options
            VStack(spacing: 15) {
                Button {
                    showingReminderSettings = true
                } label: {
                    Label("Notifications", systemImage: "bell.fill")
                        .foregroundColor(.primary)
                }
                
                Toggle(isOn: $isDarkMode) {
                    Label("Mode Sombre", systemImage: isDarkMode ? "moon.fill" : "sun.max.fill")
                }
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .frame(width: 250, height: 200)
        .sheet(isPresented: $showingReminderSettings) {
            ReminderSettingsView()
        }
    }
}

#Preview {
    DashboardView(isDarkMode: .constant(false)).environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
