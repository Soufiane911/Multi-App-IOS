import SwiftUI
import CoreData
import UserNotifications

struct ReminderSettingsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var isNotificationsEnabled = false
    @State private var taskReminderMinutes = 30
    @State private var habitReminderMinutes = 15
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    // Options de temps de rappel
    private let reminderOptions = [5, 10, 15, 30, 60, 120, 180, 1440] // Minutes (1440 = 24h)
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Notifications")) {
                    Toggle("Activer les notifications", isOn: $isNotificationsEnabled)
                        .onChange(of: isNotificationsEnabled) { oldValue, newValue in
                            if newValue {
                                requestNotificationPermission()
                            }
                        }
                }
                
                if isNotificationsEnabled {
                    Section(header: Text("Rappels de tâches")) {
                        Picker("Rappeler", selection: $taskReminderMinutes) {
                            ForEach(reminderOptions, id: \.self) { minutes in
                                Text(formatMinutes(minutes))
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        
                        Text("Rappel \(formatMinutes(taskReminderMinutes)) avant l'échéance")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Button("Appliquer à toutes les tâches") {
                            applyReminderToAllTasks()
                        }
                        .foregroundColor(.blue)
                    }
                    
                    Section(header: Text("Rappels d'habitudes")) {
                        Picker("Rappeler", selection: $habitReminderMinutes) {
                            ForEach(reminderOptions, id: \.self) { minutes in
                                Text(formatMinutes(minutes))
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        
                        Text("Rappel \(formatMinutes(habitReminderMinutes)) avant l'heure cible")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Button("Appliquer à toutes les habitudes") {
                            applyReminderToAllHabits()
                        }
                        .foregroundColor(.blue)
                    }
                    
                    Section {
                        Button("Supprimer tous les rappels") {
                            deleteAllReminders()
                        }
                        .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Paramètres de rappel")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                checkNotificationStatus()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fermer") {
                        dismiss()
                    }
                }
            }
            .alert(isPresented: $showingAlert) {
                Alert(
                    title: Text("Notifications"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
    
    // Formatter les minutes en texte
    private func formatMinutes(_ minutes: Int) -> String {
        switch minutes {
        case 5, 10, 15, 30:
            return "\(minutes) minutes"
        case 60:
            return "1 heure"
        case 120:
            return "2 heures"
        case 180:
            return "3 heures"
        case 1440:
            return "1 jour"
        default:
            return "\(minutes) minutes"
        }
    }
    
    // Vérifier le statut des notifications
    private func checkNotificationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                isNotificationsEnabled = settings.authorizationStatus == .authorized
            }
        }
    }
    
    // Demander l'autorisation pour les notifications
    private func requestNotificationPermission() {
        NotificationManager.shared.requestAuthorization { granted in
            if granted {
                isNotificationsEnabled = true
            } else {
                isNotificationsEnabled = false
                alertMessage = "Veuillez autoriser les notifications dans les paramètres pour utiliser cette fonctionnalité."
                showingAlert = true
            }
        }
    }
    
    // Appliquer le rappel à toutes les tâches
    private func applyReminderToAllTasks() {
        let fetchRequest: NSFetchRequest<Task> = Task.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "completed == false")
        
        do {
            let tasks = try viewContext.fetch(fetchRequest)
            
            for task in tasks {
                NotificationManager.shared.scheduleTaskReminder(for: task, minutes: taskReminderMinutes)
            }
            
            alertMessage = "Rappels appliqués à \(tasks.count) tâches"
            showingAlert = true
        } catch {
            print("Erreur lors de la récupération des tâches: \(error.localizedDescription)")
        }
    }
    
    // Appliquer le rappel à toutes les habitudes
    private func applyReminderToAllHabits() {
        let fetchRequest: NSFetchRequest<Habit> = Habit.fetchRequest()
        
        do {
            let habits = try viewContext.fetch(fetchRequest)
            
            for habit in habits {
                NotificationManager.shared.scheduleHabitReminder(for: habit, minutes: habitReminderMinutes)
            }
            
            alertMessage = "Rappels appliqués à \(habits.count) habitudes"
            showingAlert = true
        } catch {
            print("Erreur lors de la récupération des habitudes: \(error.localizedDescription)")
        }
    }
    
    // Supprimer tous les rappels
    private func deleteAllReminders() {
        NotificationManager.shared.cancelAllNotifications()
        alertMessage = "Tous les rappels ont été supprimés"
        showingAlert = true
    }
}

#Preview {
    ReminderSettingsView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
} 