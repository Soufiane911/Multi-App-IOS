//
//  multi_appApp.swift
//  multi-app
//
//  Created by Soufiane Hamzaoui on 06/05/2025.
//

import SwiftUI
import CoreData

@main
struct multi_appApp: App {
    let persistenceController = PersistenceController.shared
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    init() {
        // Configurer le modèle avec des données exemple
        let context = persistenceController.container.viewContext
        CoreDataModel.configureModel(context: context)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .preferredColorScheme(isDarkMode ? .dark : .light)
                .onAppear {
                    // Demander l'autorisation des notifications au démarrage
                    requestNotificationPermission()
                    
                    // Restaurer les notifications programmées
                    restoreScheduledNotifications()
                }
        }
    }
    
    // Demander l'autorisation pour les notifications
    private func requestNotificationPermission() {
        NotificationManager.shared.requestAuthorization { granted in
            print("Autorisation de notification : \(granted ? "accordée" : "refusée")")
        }
    }
    
    // Restaurer toutes les notifications programmées à partir des entités CoreData
    private func restoreScheduledNotifications() {
        let context = persistenceController.container.viewContext
        
        // Restaurer les notifications pour les tâches
        let taskRequest = NSFetchRequest<Task>(entityName: "Task")
        taskRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "notificationEnabled == %@", NSNumber(value: true)),
            NSPredicate(format: "completed == %@", NSNumber(value: false)),
            NSPredicate(format: "dueDate > %@", Date() as NSDate)
        ])
        
        do {
            let tasks = try context.fetch(taskRequest)
            for task in tasks {
                NotificationManager.shared.scheduleTaskReminder(for: task, minutes: Int(task.reminderMinutes))
            }
            print("Restauré \(tasks.count) notifications de tâches")
        } catch {
            print("Erreur lors de la restauration des notifications de tâches: \(error)")
        }
        
        // Restaurer les notifications pour les habitudes
        let habitRequest = NSFetchRequest<Habit>(entityName: "Habit")
        habitRequest.predicate = NSPredicate(format: "notificationEnabled == %@", NSNumber(value: true))
        
        do {
            let habits = try context.fetch(habitRequest)
            for habit in habits {
                NotificationManager.shared.scheduleHabitReminder(for: habit, minutes: Int(habit.reminderMinutes))
            }
            print("Restauré \(habits.count) notifications d'habitudes")
        } catch {
            print("Erreur lors de la restauration des notifications d'habitudes: \(error)")
        }
    }
}
