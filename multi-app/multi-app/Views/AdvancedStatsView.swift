import SwiftUI
import CoreData
import UIKit

struct AdvancedStatsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Task.creationDate, ascending: true)],
        animation: .default)
    private var allTasks: FetchedResults<Task>
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Habit.creationDate, ascending: true)],
        animation: .default)
    private var habits: FetchedResults<Habit>
    
    private let weekdays = ["Dim", "Lun", "Mar", "Mer", "Jeu", "Ven", "Sam"]
    private let months = ["Jan", "Fév", "Mar", "Avr", "Mai", "Jun", "Jul", "Aoû", "Sep", "Oct", "Nov", "Déc"]
    @State private var selectedTimeRange: TimeRange = .week
    
    private var completedTasksCount: Int {
        allTasks.filter { $0.completed }.count
    }
    
    private var priorityTasksCount: Int {
        allTasks.filter { $0.isPriority }.count
    }
    
    private var completionRate: Double {
        allTasks.isEmpty ? 0 : Double(completedTasksCount) / Double(allTasks.count)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 25) {
                    // Segmented control pour choisir la période
                    Picker("Plage de temps", selection: $selectedTimeRange) {
                        Text("Semaine").tag(TimeRange.week)
                        Text("Mois").tag(TimeRange.month)
                        Text("Année").tag(TimeRange.year)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                    
                    // Carte principale - Taux de complétion
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Taux de complétion des tâches")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        CompletionRingView(percentage: Int(completionRate * 100))
                            .frame(height: 200)
                            .padding()
                        
                        HStack(spacing: 0) {
                            StatisticItemView(
                                title: "Total",
                                value: "\(allTasks.count)",
                                icon: "list.bullet",
                                color: .blue
                            )
                            
                            StatisticItemView(
                                title: "Terminées",
                                value: "\(completedTasksCount)",
                                icon: "checkmark.circle",
                                color: .green
                            )
                            
                            StatisticItemView(
                                title: "Prioritaires",
                                value: "\(priorityTasksCount)",
                                icon: "star.fill",
                                color: .orange
                            )
                        }
                    }
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // Graphique d'activité
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Activité des tâches")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        TaskActivityChart(selectedRange: selectedTimeRange)
                            .frame(height: 200)
                            .padding(.horizontal)
                    }
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // Habitudes - Taux de réussite
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Taux de réussite des habitudes")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        HabitsSuccessRateChart(selectedRange: selectedTimeRange)
                            .frame(height: 200)
                            .padding(.horizontal)
                    }
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // Tendances quotidiennes
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Tendances quotidiennes")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        DailyTrendsView()
                            .padding(.horizontal)
                    }
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("Statistiques")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fermer") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Time Range Enum
enum TimeRange {
    case week, month, year
}

// MARK: - Completion Ring View
struct CompletionRingView: View {
    let percentage: Int
    
    var body: some View {
        ZStack {
            // Cercle de fond
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 20)
            
            // Cercle de progression
            Circle()
                .trim(from: 0, to: CGFloat(min(percentage, 100)) / 100)
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [.blue, .teal]),
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(lineWidth: 20, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
            
            // Texte de pourcentage
            VStack(spacing: 5) {
                Text("\(percentage)%")
                    .font(.system(size: 40, weight: .bold))
                
                Text("Complété")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Statistic Item View
struct StatisticItemView: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 18, weight: .bold))
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }
}

// MARK: - Task Activity Chart
struct TaskActivityChart: View {
    @Environment(\.managedObjectContext) private var viewContext
    let selectedRange: TimeRange
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Task.creationDate, ascending: true)],
        animation: .default)
    private var allTasks: FetchedResults<Task>
    
    private let weekdays = ["Dim", "Lun", "Mar", "Mer", "Jeu", "Ven", "Sam"]
    private let months = ["Jan", "Fév", "Mar", "Avr", "Mai", "Jun", "Jul", "Aoû", "Sep", "Oct", "Nov", "Déc"]
    
    var body: some View {
        VStack {
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(chartData.indices, id: \.self) { index in
                    let item = chartData[index]
                    
                    VStack(spacing: 8) {
                        // Complétion
                        ZStack(alignment: .bottom) {
                            // Bar for completed tasks
                            RoundedRectangle(cornerRadius: 5)
                                .fill(Color.green.opacity(0.7))
                                .frame(height: calculateBarHeight(value: item.completed, maxValue: chartMaxValue))
                            
                            // Bar for total tasks (behind)
                            RoundedRectangle(cornerRadius: 5)
                                .fill(Color.blue.opacity(0.3))
                                .frame(height: calculateBarHeight(value: item.total, maxValue: chartMaxValue))
                                .zIndex(-1)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 150)
                        
                        // Label
                        Text(item.label)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Legend
            HStack(spacing: 20) {
                HStack(spacing:.zero) {
                    Rectangle()
                        .fill(Color.blue.opacity(0.3))
                        .frame(width: 12, height: 12)
                    
                    Text(" Total")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                HStack(spacing: .zero) {
                    Rectangle()
                        .fill(Color.green.opacity(0.7))
                        .frame(width: 12, height: 12)
                    
                    Text(" Terminées")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.top, 8)
        }
    }
    
    private var chartData: [(label: String, total: Int, completed: Int)] {
        switch selectedRange {
        case .week:
            return last7DaysData
        case .month:
            return last4WeeksData
        case .year:
            return last12MonthsData
        }
    }
    
    private var chartMaxValue: Int {
        let maxTotal = chartData.map { $0.total }.max() ?? 0
        return max(maxTotal, 5) // Au moins 5 pour éviter les divisions par zéro
    }
    
    private func calculateBarHeight(value: Int, maxValue: Int) -> CGFloat {
        if maxValue == 0 { return 0 }
        return CGFloat(value) / CGFloat(maxValue) * 150 // 150 est la hauteur max
    }
    
    // Données pour les 7 derniers jours
    private var last7DaysData: [(label: String, total: Int, completed: Int)] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        return (0..<7).map { dayOffset -> (String, Int, Int) in
            let date = calendar.date(byAdding: .day, value: -dayOffset, to: today)!
            let dayIndex = calendar.component(.weekday, from: date) - 1
            let label = weekdays[dayIndex]
            
            let tasksForDay = allTasks.filter { task in
                guard let creationDate = task.creationDate else { return false }
                return calendar.isDate(creationDate, inSameDayAs: date)
            }
            
            let total = tasksForDay.count
            let completed = tasksForDay.filter { $0.completed }.count
            
            return (label, total, completed)
        }.reversed()
    }
    
    // Données pour les 4 dernières semaines
    private var last4WeeksData: [(label: String, total: Int, completed: Int)] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        return (0..<4).map { weekOffset -> (String, Int, Int) in
            let startDate = calendar.date(byAdding: .weekOfYear, value: -weekOffset, to: today)!
            let endDate = calendar.date(byAdding: .day, value: 7, to: startDate)!
            let weekNumber = calendar.component(.weekOfMonth, from: startDate)
            let label = "S\(weekNumber)"
            
            let tasksForWeek = allTasks.filter { task in
                guard let creationDate = task.creationDate else { return false }
                return creationDate >= startDate && creationDate < endDate
            }
            
            let total = tasksForWeek.count
            let completed = tasksForWeek.filter { $0.completed }.count
            
            return (label, total, completed)
        }.reversed()
    }
    
    // Données pour les 12 derniers mois
    private var last12MonthsData: [(label: String, total: Int, completed: Int)] {
        let calendar = Calendar.current
        let today = Date()
        
        return (0..<12).map { monthOffset -> (String, Int, Int) in
            let date = calendar.date(byAdding: .month, value: -monthOffset, to: today)!
            let month = calendar.component(.month, from: date) - 1
            let label = months[month]
            
            let year = calendar.component(.year, from: date)
            let monthInt = calendar.component(.month, from: date)
            
            let startOfMonth = calendar.date(from: DateComponents(year: year, month: monthInt, day: 1))!
            let nextMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth)!
            
            let tasksForMonth = allTasks.filter { task in
                guard let creationDate = task.creationDate else { return false }
                return creationDate >= startOfMonth && creationDate < nextMonth
            }
            
            let total = tasksForMonth.count
            let completed = tasksForMonth.filter { $0.completed }.count
            
            return (label, total, completed)
        }.reversed()
    }
}

// MARK: - Habits Success Rate Chart
struct HabitsSuccessRateChart: View {
    @Environment(\.managedObjectContext) private var viewContext
    let selectedRange: TimeRange
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Habit.creationDate, ascending: true)],
        animation: .default)
    private var habits: FetchedResults<Habit>
    
    private let weekdays = ["Dim", "Lun", "Mar", "Mer", "Jeu", "Ven", "Sam"]
    
    var body: some View {
        VStack {
            // Chart
            GeometryReader { geometry in
                let width = geometry.size.width
                let height = geometry.size.height
                
                Path { path in
                    // Draw line chart
                    if !habitSuccessData.isEmpty {
                        let stepX = width / CGFloat(habitSuccessData.count - 1)
                        
                        // Start point
                        path.move(to: CGPoint(x: 0, y: height * (1 - CGFloat(habitSuccessData[0]) / 100)))
                        
                        // Connect points
                        for i in 1..<habitSuccessData.count {
                            let point = CGPoint(
                                x: stepX * CGFloat(i),
                                y: height * (1 - CGFloat(habitSuccessData[i]) / 100)
                            )
                            path.addLine(to: point)
                        }
                    }
                }
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [.blue, .teal]),
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
                )
                
                // Data points
                ForEach(habitSuccessData.indices, id: \.self) { index in
                    let rate = habitSuccessData[index]
                    let x = width / CGFloat(habitSuccessData.count - 1) * CGFloat(index)
                    let y = height * (1 - CGFloat(rate) / 100)
                    
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 8, height: 8)
                        .position(x: x, y: y)
                    
                    // Display percentage
                    Text("\(rate)%")
                        .font(.caption2)
                        .position(x: x, y: max(y - 15, 10))
                }
                
                // Labels on X axis
                ForEach(labels.indices, id: \.self) { index in
                    let label = labels[index]
                    let x = width / CGFloat(labels.count - 1) * CGFloat(index)
                    
                    Text(label)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .position(x: x, y: height + 15)
                }
            }
            .padding(.bottom, 20) // Space for labels
            
            // Average success rate
            Text("Taux de réussite moyen: \(averageSuccessRate)%")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 8)
        }
    }
    
    // Labels for X axis based on selected time range
    private var labels: [String] {
        switch selectedRange {
        case .week:
            return weekdays
        case .month:
            return (1...4).map { "S\($0)" }
        case .year:
            return ["Jan", "Fév", "Mar", "Avr", "Mai", "Jun", 
                    "Jul", "Aoû", "Sep", "Oct", "Nov", "Déc"]
        }
    }
    
    // Habit success rate data
    private var habitSuccessData: [Int] {
        switch selectedRange {
        case .week:
            return (0..<7).map { dayIndex in
                calculateDailySuccessRate(dayOffset: dayIndex)
            }
        case .month:
            return (1...4).map { _ in Int.random(in: 50...95) } // Exemple simplifié
        case .year:
            return (1...12).map { _ in Int.random(in: 50...95) } // Exemple simplifié
        }
    }
    
    // Calcule le taux de réussite quotidien des habitudes
    private func calculateDailySuccessRate(dayOffset: Int) -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let date = calendar.date(byAdding: .day, value: -dayOffset, to: today)!
        
        var totalCompletions = 0
        var totalPossible = 0
        
        for habit in habits {
            totalPossible += 1
            
            guard let completions = habit.completions as? Set<HabitCompletion> else {
                continue
            }
            
            let startOfTargetDay = calendar.startOfDay(for: date)
            let endOfTargetDay = calendar.date(byAdding: .day, value: 1, to: startOfTargetDay)!
            
            let isCompleted = completions.contains { completion in
                guard let completionDate = completion.date else { return false }
                return completionDate >= startOfTargetDay && completionDate < endOfTargetDay
            }
            
            if isCompleted {
                totalCompletions += 1
            }
        }
        
        return totalPossible > 0 ? (totalCompletions * 100) / totalPossible : 0
    }
    
    // Taux de réussite moyen
    private var averageSuccessRate: Int {
        if habitSuccessData.isEmpty { return 0 }
        let sum = habitSuccessData.reduce(0, +)
        return sum / habitSuccessData.count
    }
}

// MARK: - Daily Trends View
struct DailyTrendsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    // Données de tendances quotidiennes (simulées)
    private let trends = [
        TrendData(id: 1, title: "Tâches matinales", percentage: 75, color: .blue),
        TrendData(id: 2, title: "Tâches après-midi", percentage: 60, color: .teal),
        TrendData(id: 3, title: "Tâches soirée", percentage: 45, color: .purple)
    ]
    
    var body: some View {
        VStack(spacing: 15) {
            ForEach(trends) { trend in
                HStack {
                    Text(trend.title)
                        .font(.subheadline)
                    
                    Spacer()
                    
                    Text("\(trend.percentage)%")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(trend.color)
                }
                
                ProgressView(value: Double(trend.percentage) / 100)
                    .progressViewStyle(LinearProgressViewStyle(tint: trend.color))
                    .frame(height: 8)
                
                if trends.last?.id != trend.id {
                    Divider()
                }
            }
            
            // Conseil du jour
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                    .font(.headline)
                
                Text("Conseil : Vous êtes plus productif le matin, essayez d'y planifier vos tâches importantes.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 10)
            .padding(.horizontal, 5)
        }
    }
    
    // Structure pour les données de tendance
    struct TrendData: Identifiable {
        let id: Int
        let title: String
        let percentage: Int
        let color: Color
    }
}

#Preview {
    AdvancedStatsView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
} 