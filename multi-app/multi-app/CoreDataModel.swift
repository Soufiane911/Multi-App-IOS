import Foundation
import CoreData

// Cette classe auxiliaire est utilisée pour initialiser le modèle CoreData
class CoreDataModel {
    
    static func configureModel(context: NSManagedObjectContext) {
        // Vérifier si le modèle a déjà été configuré
        let fetchRequest: NSFetchRequest<Task> = Task.fetchRequest()
        fetchRequest.fetchLimit = 1
        
        do {
            let count = try context.count(for: fetchRequest)
            if count > 0 {
                // Modèle déjà configuré
                return
            }
        } catch {
            print("Erreur lors de la vérification du modèle: \(error)")
        }
        
        // Créer des tâches exemple
        createExampleTasks(context: context)
        
        // Créer des habitudes exemple
        createExampleHabits(context: context)
        
        // Créer des notes exemple
        createExampleNotes(context: context)
        
        // Sauvegarder le contexte
        do {
            try context.save()
        } catch {
            print("Erreur lors de la sauvegarde du contexte: \(error)")
        }
    }
    
    private static func createExampleTasks(context: NSManagedObjectContext) {
        let titles = ["Faire les courses", "Appeler le médecin", "Préparer la présentation", 
                     "Répondre aux emails", "Réviser pour l'examen"]
        
        for (index, title) in titles.enumerated() {
            let task = Task(context: context)
            task.id = UUID()
            task.title = title
            task.creationDate = Date()
            task.completed = index > 3
            task.isPriority = index < 2
        }
    }
    
    private static func createExampleHabits(context: NSManagedObjectContext) {
        let habits = [
            (title: "Méditation", color: "HabitBlue"),
            (title: "Lecture", color: "HabitGreen"),
            (title: "Exercice", color: "HabitOrange")
        ]
        
        for (index, habitData) in habits.enumerated() {
            let habit = Habit(context: context)
            habit.id = UUID()
            habit.title = habitData.title
            habit.color = habitData.color
            habit.creationDate = Date()
            
            // Ajouter quelques complétion d'habitudes pour les jours précédents
            for day in 1...3 {
                if day % (index + 1) == 0 {  // Varier les complétions
                    let completion = HabitCompletion(context: context)
                    completion.id = UUID()
                    completion.date = Calendar.current.date(byAdding: .day, value: -day, to: Date())!
                    completion.habit = habit
                }
            }
        }
    }
    
    private static func createExampleNotes(context: NSManagedObjectContext) {
        let notes = [
            (title: "Idées de projet", content: "1. Application de productivité\n2. Site web de recettes\n3. Jeu mobile éducatif"),
            (title: "Liste de courses", content: "- Lait\n- Pain\n- Œufs\n- Fromage\n- Fruits"),
            (title: "Citations inspirantes", content: "\"La seule façon de faire du bon travail est d'aimer ce que vous faites.\" - Steve Jobs"),
            (title: "Objectifs du mois", content: "1. Terminer le projet principal\n2. Commencer à apprendre une nouvelle langue\n3. Lire au moins 2 livres")
        ]
        
        for (index, noteData) in notes.enumerated() {
            let note = Note(context: context)
            note.id = UUID()
            // Essayer d'utiliser l'attribut 'title' s'il existe, sinon stocker dans 'content'
            if note.entity.attributesByName["title"] != nil {
                note.setValue(noteData.title, forKey: "title")
                note.setValue(noteData.content, forKey: "content")
            } else {
                // Si 'title' n'existe pas, fusion du titre et du contenu
                note.content = "\(noteData.title)\n\n\(noteData.content)"
            }
            note.creationDate = Date().addingTimeInterval(-Double(index * 86400))
        }
    }
} 