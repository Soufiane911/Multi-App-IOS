import SwiftUI
import CoreData
import UIKit

struct HabitsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.colorScheme) private var colorScheme
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Habit.creationDate, ascending: false)],
        animation: .default)
    private var habits: FetchedResults<Habit>
    
    @State private var showingAddHabitSheet = false
    @State private var newHabitTitle = ""
    @State private var selectedColor = "HabitBlue"
    @State private var selectedDay: Int = Calendar.current.component(.weekday, from: Date()) - 1
    @State private var targetTime = Calendar.current.date(from: DateComponents(hour: 15, minute: 0)) ?? Date()
    @State private var notificationEnabled = false
    @State private var reminderMinutes = 5 // minutes avant l'habitude
    @State private var editMode: EditMode = .inactive
    @State private var habitToDelete: Habit?
    @State private var showingDeleteConfirmation = false
    
    // Options de temps de rappel
    private let reminderOptions = [5, 10, 15, 30, 60, 120] // Minutes
    
    private let habitColors = ["HabitBlue", "HabitGreen", "HabitPurple", "HabitOrange", "HabitPink"]
    private let weekdays = ["Dim", "Lun", "Mar", "Mer", "Jeu", "Ven", "Sam"]
    
    // Définition de la couleur de fond bleue claire
    private let lightBlueBackground = Color(red: 0.9, green: 0.95, blue: 1.0)
    
    // Fonction pour obtenir la couleur à partir du nom
    private func colorFromName(_ name: String) -> Color {
        switch name {
        case "HabitBlue": return .blue
        case "HabitGreen": return .green
        case "HabitPurple": return .purple
        case "HabitOrange": return .orange
        case "HabitPink": return .pink
        default: return .blue
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
        default:
            return "\(minutes) minutes"
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Fond bleu clair en mode light
                if colorScheme == .light {
                    lightBlueBackground
                        .ignoresSafeArea()
                }
                
                // Contenu principal
                ScrollView {
                    VStack(spacing: 20) {
                        // Header avec bouton d'édition
                        HStack {
                            Text("Mes habitudes")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            
                            Spacer()
                            
                            Button {
                                withAnimation {
                                    editMode = editMode == .inactive ? .active : .inactive
                                }
                            } label: {
                                Text(editMode == .inactive ? "Modifier" : "Terminé")
                                    .foregroundColor(.blue)
                            }
                            
                            Button {
                                showingAddHabitSheet = true
                            } label: {
                                Image(systemName: "plus.circle")
                                    .foregroundColor(.blue)
                                    .font(.title2)
                            }
                        }
                        .padding(.horizontal)
                        
                        // Today's date
                        Text(Date(), style: .date)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.bottom)
                        
                        // Instructions pour la suppression
                        if editMode == .active {
                            Text("Appuyez sur la corbeille pour supprimer")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.bottom, 5)
                        } else {
                            Text("Appuyer sur Modifier pour supprimer des habitudes")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.bottom, 5)
                        }
                        
                        // Graphique détaillé
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Suivi hebdomadaire")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            // Sélecteur de jour
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack {
                                    ForEach(0..<7, id: \.self) { index in
                                        Button(action: {
                                            selectedDay = index
                                        }) {
                                            Text(weekdays[index])
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 8)
                                                .background(selectedDay == index ? Color.blue : Color(UIColor.systemGray6))
                                                .foregroundColor(selectedDay == index ? .white : .primary)
                                                .cornerRadius(10)
                                                .font(.subheadline)
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                            
                            // Graphique pour le jour sélectionné
                            VStack(spacing: 15) {
                                HStack {
                                    Text("Habitudes du \(dayName(for: selectedDay))")
                                        .font(.headline)
                                    Spacer()
                                    Text("\(completionPercentage(for: selectedDay))%")
                                        .font(.headline)
                                        .foregroundColor(.blue)
                                }
                                
                                // Barre de progression
                                GeometryReader { geometry in
                                    ZStack(alignment: .leading) {
                                        Rectangle()
                                            .frame(width: geometry.size.width, height: 20)
                                            .opacity(0.3)
                                            .foregroundColor(.gray)
                                        
                                        Rectangle()
                                            .frame(width: geometry.size.width * CGFloat(completionPercentage(for: selectedDay)) / 100, height: 20)
                                            .foregroundColor(.blue)
                                    }
                                    .cornerRadius(10)
                                }
                                .frame(height: 20)
                                
                                // Statistiques par jour
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("Tendance hebdomadaire")
                                        .font(.headline)
                                        .padding(.top)
                                    
                                    HStack(spacing: 0) {
                                        ForEach(0..<7, id: \.self) { day in
                                            VStack(spacing: 5) {
                                                Text("\(completionPercentage(for: day))%")
                                                    .font(.caption)
                                                    .foregroundColor(.primary)
                                                
                                                RoundedRectangle(cornerRadius: 5)
                                                    .fill(Color.blue.opacity(Double(completionPercentage(for: day)) / 100))
                                                    .frame(height: 80 * Double(completionPercentage(for: day)) / 100)
                                                
                                                Text(weekdays[day])
                                                    .font(.caption2)
                                                    .foregroundColor(.secondary)
                                            }
                                            .frame(maxWidth: .infinity)
                                        }
                                    }
                                    .padding(.top, 5)
                                }
                            }
                            .padding()
                            .background(Color(UIColor.systemBackground))
                            .cornerRadius(15)
                            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                            .padding(.horizontal)
                        }
                        
                        // Liste des habitudes pour ce jour
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Habitudes du jour")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            if habits.isEmpty {
                                HStack {
                                    Spacer()
                                    VStack(spacing: 10) {
                                        Image(systemName: "calendar.badge.exclamationmark")
                                            .font(.largeTitle)
                                            .foregroundColor(.secondary)
                                        
                                        Text("Aucune habitude à suivre")
                                            .foregroundColor(.secondary)
                                        
                                        Text("Ajoutez une habitude avec le bouton +")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .multilineTextAlignment(.center)
                                    }
                                    .padding()
                                    Spacer()
                                }
                            } else {
                                ForEach(habits) { habit in
                                    HStack {
                                        Circle()
                                            .fill(colorFromName(habit.color ?? "HabitBlue"))
                                            .frame(width: 16, height: 16)
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(habit.title ?? "")
                                                .foregroundColor(isHabitCompletedForDay(habit, day: selectedDay) ? .secondary : .primary)
                                            
                                            HStack(spacing: 4) {
                                                if let targetTime = habit.targetTime {
                                                    Text(formatTime(targetTime))
                                                        .font(.caption2)
                                                        .foregroundColor(.secondary)
                                                }
                                                
                                                if habit.notificationEnabled {
                                                    Image(systemName: "bell.fill")
                                                        .font(.caption2)
                                                        .foregroundColor(colorFromName(habit.color ?? "HabitBlue").opacity(0.7))
                                                }
                                            }
                                        }
                                        
                                        Spacer()
                                        
                                        if editMode == .active {
                                            Button {
                                                habitToDelete = habit
                                                showingDeleteConfirmation = true
                                            } label: {
                                                Image(systemName: "trash")
                                                    .foregroundColor(.red)
                                                    .padding(10)
                                            }
                                        } else {
                                            Button {
                                                toggleHabitCompletion(habit, day: selectedDay)
                                            } label: {
                                                Image(systemName: isHabitCompletedForDay(habit, day: selectedDay) ? "checkmark.circle.fill" : "circle")
                                                    .foregroundColor(isHabitCompletedForDay(habit, day: selectedDay) ? colorFromName(habit.color ?? "HabitBlue") : .secondary)
                                                    .font(.title2)
                                            }
                                        }
                                    }
                                    .padding(.vertical, 12)
                                    .padding(.horizontal, 16)
                                    .background(Color(UIColor.systemBackground))
                                    .cornerRadius(10)
                                    .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                                    .padding(.horizontal)
                                    .swipeActions(edge: .trailing) {
                                        Button(role: .destructive) {
                                            habitToDelete = habit
                                            showingDeleteConfirmation = true
                                        } label: {
                                            Label("Supprimer", systemImage: "trash")
                                        }
                                    }
                                }
                                .onDelete(perform: deleteHabits)
                            }
                        }
                        .padding(.top)
                    }
                    .padding(.vertical)
                }
            }
            .sheet(isPresented: $showingAddHabitSheet) {
                addHabitView
            }
            .alert("Supprimer l'habitude ?", isPresented: $showingDeleteConfirmation) {
                Button("Annuler", role: .cancel) {}
                Button("Supprimer", role: .destructive) {
                    if let habit = habitToDelete {
                        deleteHabit(habit)
                    }
                }
            } message: {
                Text("Êtes-vous sûr de vouloir supprimer cette habitude ? Cette action est irréversible.")
            }
            .navigationBarHidden(true)
            .environment(\.editMode, $editMode)
        }
    }
    
    private var addHabitView: some View {
        NavigationView {
            Form {
                Section(header: Text("Nouvelle habitude")) {
                    TextField("Titre de l'habitude", text: $newHabitTitle)
                }
                
                Section(header: Text("Heure cible")) {
                    DatePicker("Heure de l'habitude", selection: $targetTime, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.wheel)
                        .padding(.vertical, 8)
                }
                
                Section(header: Text("Couleur")) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 15) {
                            ForEach(habitColors, id: \.self) { colorName in
                                Circle()
                                    .fill(colorFromName(colorName))
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Circle()
                                            .stroke(selectedColor == colorName ? Color.primary : Color.clear, lineWidth: 2)
                                    )
                                    .onTapGesture {
                                        selectedColor = colorName
                                    }
                            }
                        }
                        .padding(.vertical, 5)
                    }
                }
                
                Section(header: Text("Notification")) {
                    Toggle("Me notifier avant l'habitude", isOn: $notificationEnabled)
                        .padding(.vertical, 6)
                    
                    if notificationEnabled {
                        Picker("Rappel", selection: $reminderMinutes) {
                            ForEach(reminderOptions, id: \.self) { minutes in
                                Text(formatMinutes(minutes))
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        
                        Text("Rappel \(formatMinutes(reminderMinutes)) avant l'heure prévue")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Ajouter une habitude")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") {
                        showingAddHabitSheet = false
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Ajouter") {
                        addHabit()
                        showingAddHabitSheet = false
                    }
                    .disabled(newHabitTitle.isEmpty)
                }
            }
        }
    }
    
    private func addHabit() {
        withAnimation {
            let newHabit = Habit(context: viewContext)
            newHabit.id = UUID()
            newHabit.title = newHabitTitle
            newHabit.color = selectedColor
            newHabit.creationDate = Date()
            newHabit.targetTime = targetTime
            newHabit.notificationEnabled = notificationEnabled
            newHabit.reminderMinutes = Int16(reminderMinutes)
            
            do {
                try viewContext.save()
                
                // Planifier la notification si activée
                if notificationEnabled {
                    NotificationManager.shared.scheduleHabitReminder(for: newHabit, minutes: reminderMinutes)
                }
                
                // Réinitialiser les champs
                newHabitTitle = ""
                selectedColor = "HabitBlue"
                notificationEnabled = false
                reminderMinutes = 5
                targetTime = Calendar.current.date(from: DateComponents(hour: 15, minute: 0)) ?? Date()
            } catch {
                let nsError = error as NSError
                print("Error adding habit: \(nsError)")
            }
        }
    }
    
    private func deleteHabit(_ habit: Habit) {
        withAnimation {
            // Annuler toute notification associée
            if let habitId = habit.id?.uuidString {
                NotificationManager.shared.cancelNotification(for: habitId)
            }
            
            viewContext.delete(habit)
            
            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                print("Error deleting habit: \(nsError)")
            }
        }
    }
    
    private func deleteHabits(offsets: IndexSet) {
        withAnimation {
            offsets.map { habits[$0] }.forEach { habit in
                // Annuler toute notification associée
                if let habitId = habit.id?.uuidString {
                    NotificationManager.shared.cancelNotification(for: habitId)
                }
                viewContext.delete(habit)
            }
            
            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                print("Error deleting habits: \(nsError)")
            }
        }
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
    
    // Toggle la complétion d'une habitude pour un jour spécifique
    private func toggleHabitCompletion(_ habit: Habit, day: Int) {
        withAnimation {
            // Obtenir la date du jour spécifié
            let currentDate = Date()
            let calendar = Calendar.current
            let weekday = calendar.component(.weekday, from: currentDate) - 1
            let daysToSubtract = (weekday - day + 7) % 7
            
            let targetDate = calendar.date(byAdding: .day, value: -daysToSubtract, to: currentDate)!
            
            if isHabitCompletedForDay(habit, day: day) {
                // Supprimer la complétion pour ce jour
                if let completions = habit.completions as? Set<HabitCompletion> {
                    let completionsToDelete = completions.filter { completion in
                        guard let date = completion.date else { return false }
                        return calendar.isDate(date, inSameDayAs: targetDate)
                    }
                    
                    completionsToDelete.forEach(viewContext.delete)
                }
            } else {
                // Ajouter une complétion pour ce jour
                let newCompletion = HabitCompletion(context: viewContext)
                newCompletion.id = UUID()
                newCompletion.date = targetDate
                newCompletion.habit = habit
            }
            
            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                print("Error toggling habit completion: \(nsError)")
            }
        }
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
    
    // Obtenir le nom complet du jour
    private func dayName(for day: Int) -> String {
        let fullWeekdays = ["Dimanche", "Lundi", "Mardi", "Mercredi", "Jeudi", "Vendredi", "Samedi"]
        return fullWeekdays[day]
    }
    
    // Formater l'heure
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: date)
    }
}

#Preview {
    HabitsView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
} 
