import SwiftUI
import CoreData
import UIKit
import UserNotifications

// Énumération pour les filtres de tâches
enum TaskFilter: String, CaseIterable {
    case today = "Aujourd'hui"
    case important = "Important"
    case upcoming = "À venir"
}

struct TasksView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.colorScheme) private var colorScheme
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Task.dueDate, ascending: true)],
        animation: .default)
    private var tasks: FetchedResults<Task>
    
    @State private var newTaskTitle = ""
    @State private var showingCompletedTasks = false
    @State private var isNewTaskPriority = false
    @State private var selectedFilter: TaskFilter = .today
    @State private var dueDate = Date()
    @State private var showingAddTaskSheet = false
    @State private var enableNotification = false
    @State private var reminderTime = 30 // minutes avant échéance
    
    // Options de temps de rappel
    private let reminderOptions = [5, 10, 15, 30, 60, 120, 180, 1440] // Minutes (1440 = 24h)
    
    // Définition de la couleur de fond bleue claire
    private let lightBlueBackground = Color(red: 0.9, green: 0.95, blue: 1.0)
    
    var body: some View {
        NavigationView {
            ZStack {
                // Fond bleu clair en mode light
                if colorScheme == .light {
                    lightBlueBackground
                        .ignoresSafeArea()
                }
                
                VStack {
                    // Header
                    HStack {
                        Text("Mes tâches")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        Button {
                            withAnimation {
                                showingCompletedTasks.toggle()
                            }
                        } label: {
                            Label(showingCompletedTasks ? "Masquer terminées" : "Afficher terminées", 
                                  systemImage: showingCompletedTasks ? "eye.slash" : "eye")
                                .foregroundColor(.blue)
                                .font(.caption)
                        }
                        .padding(8)
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(8)
                    }
                    .padding(.horizontal)
                    
                    // Filtre catégories
                    HStack(spacing: 8) {
                        ForEach(TaskFilter.allCases, id: \.self) { filter in
                            FilterButton(
                                title: filter.rawValue,
                                isSelected: selectedFilter == filter,
                                action: {
                                    withAnimation(.spring(response: 0.3)) {
                                        selectedFilter = filter
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 5)
                    
                    // Bouton Ajouter Tâche
                    Button {
                        // Réinitialiser les valeurs avant d'ouvrir la feuille
                        newTaskTitle = ""
                        isNewTaskPriority = false
                        dueDate = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
                        enableNotification = false
                        reminderTime = 30
                        showingAddTaskSheet = true
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Ajouter une tâche")
                        }
                        .foregroundColor(.white)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(10)
                        .shadow(color: Color.blue.opacity(0.3), radius: 5, x: 0, y: 2)
                    }
                    .padding(.horizontal)
                    .padding(.top, 5)
                    
                    // Instructions
                    Text("Glissez vers la gauche pour supprimer une tâche")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 5)
                    
                    // Task List
                    List {
                        ForEach(filteredTasks) { task in
                            TaskRowWithActions(task: task)
                        }
                        .onDelete(perform: deleteTasks)
                    }
                    .listStyle(PlainListStyle())
                }
                .navigationBarHidden(true)
            }
            .sheet(isPresented: $showingAddTaskSheet) {
                AddTaskSheet(
                    newTaskTitle: $newTaskTitle, 
                    isNewTaskPriority: $isNewTaskPriority, 
                    dueDate: $dueDate,
                    enableNotification: $enableNotification,
                    reminderTime: $reminderTime,
                    reminderOptions: reminderOptions,
                    addTask: addTask,
                    close: { showingAddTaskSheet = false }
                )
            }
        }
    }
    
    private var filteredTasks: [Task] {
        // Filtrer d'abord par complétées/non complétées
        var result = tasks.filter { task in
            showingCompletedTasks || !task.completed
        }
        
        // Ensuite appliquer le filtre sélectionné
        result = result.filter { task in
            guard let taskDate = task.dueDate else { return false }
            
            switch selectedFilter {
            case .today:
                // Vérifier si la date d'échéance est aujourd'hui
                return Calendar.current.isDateInToday(taskDate)
                
            case .important:
                return task.isPriority
                
            case .upcoming:
                // Vérifier si la date d'échéance est dans le futur (demain ou après)
                let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: Date())) ?? Date()
                return taskDate >= tomorrow
            }
        }
        
        // Tri: tâches importantes en premier, puis par date d'échéance
        result.sort { task1, task2 in
            if task1.isPriority != task2.isPriority {
                return task1.isPriority
            }
            
            let date1 = task1.dueDate ?? Date.distantFuture
            let date2 = task2.dueDate ?? Date.distantFuture
            return date1 < date2
        }
        
        return result
    }
    
    private func addTask() {
        withAnimation {
            let newTask = Task(context: viewContext)
            newTask.id = UUID()
            newTask.title = newTaskTitle
            newTask.completed = false
            newTask.creationDate = Date()
            newTask.dueDate = dueDate
            newTask.isPriority = isNewTaskPriority
            newTask.notificationEnabled = enableNotification
            newTask.reminderMinutes = Int16(reminderTime)
            
            do {
                try viewContext.save()
                
                // Planifier la notification si activée
                if enableNotification {
                    NotificationManager.shared.scheduleTaskReminder(for: newTask, minutes: Int(newTask.reminderMinutes))
                }
                
                newTaskTitle = ""
                isNewTaskPriority = false
                // Fermer la feuille d'ajout
                showingAddTaskSheet = false
            } catch {
                let nsError = error as NSError
                print("Error adding task: \(nsError)")
            }
        }
    }
    
    private func deleteTasks(offsets: IndexSet) {
        withAnimation {
            offsets.map { filteredTasks[$0] }.forEach(viewContext.delete)
            
            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                print("Error deleting tasks: \(nsError)")
            }
        }
    }
}

// Feuille pour ajouter une nouvelle tâche
struct AddTaskSheet: View {
    @Binding var newTaskTitle: String
    @Binding var isNewTaskPriority: Bool
    @Binding var dueDate: Date
    @Binding var enableNotification: Bool
    @Binding var reminderTime: Int
    let reminderOptions: [Int]
    var addTask: () -> Void
    var close: () -> Void
    
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
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Détails de la tâche")) {
                    TextField("Titre de la tâche", text: $newTaskTitle)
                        .padding(.vertical, 8)
                    
                    DatePicker("Date et heure d'échéance", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                        .datePickerStyle(.graphical)
                        .padding(.vertical, 8)
                    
                    Toggle(isOn: $isNewTaskPriority) {
                        Label("Marquer comme importante", systemImage: "star")
                            .foregroundColor(.primary)
                    }
                    .toggleStyle(SwitchToggleStyle(tint: .yellow))
                    .padding(.vertical, 8)
                }
                
                Section(header: Text("Notification")) {
                    Toggle("Me notifier avant l'échéance", isOn: $enableNotification)
                        .padding(.vertical, 6)
                    
                    if enableNotification {
                        Picker("Rappel", selection: $reminderTime) {
                            ForEach(reminderOptions, id: \.self) { minutes in
                                Text(formatMinutes(minutes))
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        
                        Text("Rappel \(formatMinutes(reminderTime)) avant l'échéance")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Nouvelle tâche")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") {
                        close()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Ajouter") {
                        addTask()
                    }
                    .disabled(newTaskTitle.isEmpty)
                }
            }
        }
    }
}

// Bouton de filtre stylisé
struct FilterButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.blue : Color(UIColor.systemGray6))
                .cornerRadius(20)
                .shadow(color: isSelected ? Color.blue.opacity(0.3) : .clear, radius: 3)
        }
        .buttonStyle(BorderlessButtonStyle())
        .scaleEffect(isSelected ? 1.05 : 1.0)
    }
}

struct TaskRowWithActions: View {
    @ObservedObject var task: Task
    @Environment(\.managedObjectContext) private var viewContext
    @State private var showingEditSheet = false
    @State private var editDueDate: Date
    @State private var editNotificationEnabled: Bool
    @State private var editReminderMinutes: Int
    
    // Options de temps de rappel
    private let reminderOptions = [5, 10, 15, 30, 60, 120, 180, 1440]
    
    init(task: Task) {
        self.task = task
        // Initialiser les états d'édition avec les valeurs actuelles
        _editDueDate = State(initialValue: task.dueDate ?? Date())
        _editNotificationEnabled = State(initialValue: task.notificationEnabled)
        _editReminderMinutes = State(initialValue: Int(task.reminderMinutes))
    }
    
    var body: some View {
        HStack {
            Button {
                task.completed.toggle()
                try? viewContext.save()
                
                // Si une notification est active et que la tâche est marquée comme terminée, annuler la notification
                if task.completed && task.notificationEnabled {
                    if let taskId = task.id?.uuidString {
                        NotificationManager.shared.cancelNotification(for: taskId)
                    }
                }
            } label: {
                Image(systemName: task.completed ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(task.completed ? .blue : .secondary)
                    .font(.title2)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title ?? "Tâche sans titre")
                    .strikethrough(task.completed)
                    .foregroundColor(task.completed ? .secondary : .primary)
                
                HStack(spacing: 6) {
                    if task.isPriority {
                        Text("Prioritaire")
                            .font(.caption2)
                            .foregroundColor(.orange)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.2))
                            .cornerRadius(4)
                    }
                    
                    // Afficher la date et l'heure de la tâche
                    if let date = task.dueDate {
                        Text(formatDate(date))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    if task.notificationEnabled {
                        Image(systemName: "bell.fill")
                            .font(.caption2)
                            .foregroundColor(.blue.opacity(0.7))
                    }
                }
            }
            .onTapGesture {
                // Mettre à jour les valeurs d'édition
                editDueDate = task.dueDate ?? Date()
                editNotificationEnabled = task.notificationEnabled
                editReminderMinutes = Int(task.reminderMinutes)
                showingEditSheet = true
            }
            
            Spacer()
            
            Button {
                task.isPriority.toggle()
                try? viewContext.save()
            } label: {
                Image(systemName: task.isPriority ? "star.fill" : "star")
                    .foregroundColor(task.isPriority ? .yellow : .secondary)
                    .font(.subheadline)
            }
            .buttonStyle(BorderlessButtonStyle())
            .padding(8)
            .background(Color(UIColor.systemGray6).opacity(0.5))
            .cornerRadius(8)
        }
        .padding(.vertical, 4)
        .sheet(isPresented: $showingEditSheet) {
            editTaskView
        }
    }
    
    private var editTaskView: some View {
        NavigationView {
            Form {
                Section(header: Text("Date et heure d'échéance")) {
                    DatePicker("Échéance", selection: $editDueDate, displayedComponents: [.date, .hourAndMinute])
                        .datePickerStyle(.graphical)
                        .padding(.vertical, 8)
                }
                
                Section(header: Text("Notification")) {
                    Toggle("Me notifier avant l'échéance", isOn: $editNotificationEnabled)
                        .padding(.vertical, 6)
                    
                    if editNotificationEnabled {
                        Picker("Rappel", selection: $editReminderMinutes) {
                            ForEach(reminderOptions, id: \.self) { minutes in
                                Text(formatMinutes(minutes))
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        
                        Text("Rappel \(formatMinutes(editReminderMinutes)) avant l'échéance")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Modifier la tâche")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") {
                        showingEditSheet = false
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Enregistrer") {
                        updateTask()
                        showingEditSheet = false
                    }
                }
            }
        }
    }
    
    private func updateTask() {
        task.dueDate = editDueDate
        task.notificationEnabled = editNotificationEnabled
        task.reminderMinutes = Int16(editReminderMinutes)
        
        try? viewContext.save()
        
        // Gérer la notification
        if let taskId = task.id?.uuidString {
            // Annuler toute notification existante
            NotificationManager.shared.cancelNotification(for: taskId)
            
            // Recréer la notification si activée
            if task.notificationEnabled && !task.completed {
                NotificationManager.shared.scheduleTaskReminder(for: task, minutes: Int(task.reminderMinutes))
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
    
    // Formater la date de façon utilisateur
    private func formatDate(_ date: Date) -> String {
        let calendar = Calendar.current
        
        if calendar.isDateInToday(date) {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return "Aujourd'hui à " + formatter.string(from: date)
        } else if calendar.isDateInTomorrow(date) {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return "Demain à " + formatter.string(from: date)
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            return formatter.string(from: date)
        }
    }
}

#Preview {
    TasksView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
} 