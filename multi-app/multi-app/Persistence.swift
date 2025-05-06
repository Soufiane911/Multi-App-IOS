//
//  Persistence.swift
//  multi-app
//
//  Created by Soufiane Hamzaoui on 06/05/2025.
//

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    @MainActor
    static let preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        
        // Créer des exemples de tâches
        for i in 1...5 {
            let task = Task(context: viewContext)
            task.id = UUID()
            task.title = "Tâche exemple \(i)"
            task.creationDate = Date()
            task.completed = Bool.random()
            task.isPriority = i <= 2
        }
        
        // Créer des exemples d'habitudes
        for i in 1...3 {
            let habit = Habit(context: viewContext)
            habit.id = UUID()
            habit.title = "Habitude exemple \(i)"
            habit.creationDate = Date()
            
            // Ajouter quelques complétion d'habitudes
            let completion = HabitCompletion(context: viewContext)
            completion.id = UUID()
            completion.date = Date().addingTimeInterval(-Double(i * 86400))
            completion.habit = habit
        }
        
        // Créer des exemples de notes
        for i in 1...4 {
            let note = Note(context: viewContext)
            note.id = UUID()
            note.title = "Note exemple \(i)"
            note.content = "Contenu de la note exemple \(i). Ceci est un texte d'exemple."
            note.creationDate = Date()
        }
        
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Erreur non résolue \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "multi_app")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Erreur lors du chargement des données: \(error), \(error.userInfo)")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}
