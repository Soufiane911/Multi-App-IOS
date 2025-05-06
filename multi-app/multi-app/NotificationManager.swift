import Foundation
import UserNotifications
import CoreData

class NotificationManager {
    static let shared = NotificationManager()
    
    private init() {}
    
    // Demander l'autorisation pour les notifications
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }
    
    // Planifier une notification pour une tâche
    func scheduleTaskReminder(for task: Task, minutes: Int) {
        guard let taskId = task.id?.uuidString,
              let taskTitle = task.title,
              let dueDate = task.dueDate else {
            return
        }
        
        // Supprimer toute notification existante pour cette tâche
        cancelNotification(for: taskId)
        
        // Créer le contenu de la notification
        let content = UNMutableNotificationContent()
        content.title = "Rappel de tâche"
        content.body = "N'oubliez pas : \(taskTitle)"
        content.sound = .default
        content.badge = 1
        
        // Calculer le temps de notification (date d'échéance - délai de rappel)
        let calendar = Calendar.current
        let reminderDate = calendar.date(byAdding: .minute, value: -minutes, to: dueDate) ?? dueDate
        
        // Vérifier que la date de rappel est dans le futur
        if reminderDate <= Date() {
            // Si la date de rappel est déjà passée, ne pas planifier la notification
            print("La date de rappel est déjà passée, notification non planifiée pour: \(taskTitle)")
            return
        }
        
        // Créer le déclencheur avec la date calculée
        let dateComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: reminderDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        
        // Créer la requête de notification
        let request = UNNotificationRequest(identifier: taskId, content: content, trigger: trigger)
        
        // Ajouter la notification
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Erreur lors de la planification de la notification: \(error.localizedDescription)")
            } else {
                print("Notification planifiée pour \(taskTitle) à \(reminderDate)")
            }
        }
    }
    
    // Planifier une notification pour une habitude
    func scheduleHabitReminder(for habit: Habit, minutes: Int) {
        guard let habitId = habit.id?.uuidString,
              let habitTitle = habit.title else {
            return
        }
        
        // Supprimer toute notification existante pour cette habitude
        cancelNotification(for: habitId)
        
        // Créer le contenu de la notification
        let content = UNMutableNotificationContent()
        content.title = "Rappel d'habitude"
        content.body = "Moment de pratiquer : \(habitTitle)"
        content.sound = .default
        
        // Calculer le déclencheur en fonction du temps cible
        let dateComponents = getDateComponentsForHabit(habit, minutesBefore: minutes)
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        // Créer la requête de notification
        let request = UNNotificationRequest(identifier: habitId, content: content, trigger: trigger)
        
        // Ajouter la notification
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Erreur lors de la planification de la notification: \(error.localizedDescription)")
            } else {
                print("Notification quotidienne planifiée pour l'habitude: \(habitTitle)")
            }
        }
    }
    
    // Obtenir les composants de date pour une habitude
    private func getDateComponentsForHabit(_ habit: Habit, minutesBefore: Int) -> DateComponents {
        var components = DateComponents()
        let calendar = Calendar.current
        
        // Utiliser l'heure cible de l'habitude si définie, sinon 20h00 par défaut
        if let targetTime = habit.targetTime {
            let timeComponents = calendar.dateComponents([.hour, .minute], from: targetTime)
            components.hour = timeComponents.hour
            components.minute = timeComponents.minute
        } else {
            // Valeur par défaut si aucune heure cible n'est définie
            components.hour = 20
            components.minute = 0
        }
        
        // Soustraire les minutes avant
        if minutesBefore > 0 {
            guard let targetDate = calendar.date(from: components) else {
                return components
            }
            
            let adjustedDate = targetDate.addingTimeInterval(-Double(minutesBefore * 60))
            let adjustedComponents = calendar.dateComponents([.hour, .minute], from: adjustedDate)
            
            components.hour = adjustedComponents.hour
            components.minute = adjustedComponents.minute
        }
        
        return components
    }
    
    // Annuler une notification spécifique
    func cancelNotification(for identifier: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }
    
    // Annuler toutes les notifications
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
} 