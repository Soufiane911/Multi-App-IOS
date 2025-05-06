import SwiftUI
import CoreData

struct NotesView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Namespace private var animation
    @Environment(\.colorScheme) private var colorScheme
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Note.creationDate, ascending: false)],
        animation: .default)
    private var notes: FetchedResults<Note>
    
    @State private var newNoteContent = ""
    @State private var showingAddNoteSheet = false
    @State private var selectedTag = ""
    @State private var filterTag: String? = nil
    
    private let availableTags = ["Travail", "Personnel", "Idée", "Important", "Achats"]
    
    // Couleur de fond bleue claire pour le mode clair
    private let lightBlueBackground = Color(red: 0.9, green: 0.95, blue: 1.0)
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Fond bleu clair en mode light
            if colorScheme == .light {
                lightBlueBackground
                    .ignoresSafeArea()
            }
            
            ScrollView {
                VStack {
                    Color.clear.frame(height: 120)
                    
                    Text("Appuyez longuement sur une note pour la supprimer")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 5)
                    
                    LazyVStack(spacing: 12) {
                        ForEach(filteredNotes) { note in
                            NoteCardInList(note: note)
                                .padding(.horizontal)
                                .matchedGeometryEffect(id: note.id ?? UUID(), in: animation)
                                .transition(.asymmetric(
                                    insertion: .scale.combined(with: .opacity),
                                    removal: .scale.combined(with: .opacity)
                                ))
                        }
                    }
                    
                    Color.clear.frame(height: 100)
                }
            }
            
            VStack(spacing: 0) {
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .frame(height: 120)
                    .overlay {
                        VStack(spacing: 12) {
                            HStack {
                                Text("Notes rapides")
                                    .font(.system(size: 34, weight: .bold))
                                    .foregroundColor(.blue)
                                
                                Spacer()
                                
                                Button {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        showingAddNoteSheet = true
                                    }
                                } label: {
                                    Image(systemName: "square.and.pencil")
                                        .font(.system(size: 24, weight: .semibold))
                                        .foregroundColor(.blue)
                                }
                            }
                            .padding(.horizontal)
                            .padding(.top, 20)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack {
                                    TagButton(title: "Tous", isSelected: filterTag == nil) {
                                        withAnimation(.spring(response: 0.3)) {
                                            filterTag = nil
                                        }
                                    }
                                    
                                    ForEach(availableTags, id: \.self) { tag in
                                        TagButton(title: tag, isSelected: filterTag == tag) {
                                            withAnimation(.spring(response: 0.3)) {
                                                filterTag = tag
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 120)
            .frame(maxHeight: .infinity, alignment: .top)
        }
        .sheet(isPresented: $showingAddNoteSheet) {
            addNoteView
        }
    }
    
    var filteredNotes: [Note] {
        guard let filterTag = filterTag else {
            return Array(notes)
        }
        
        return notes.filter { note in
            if let tagArray = note.tags {
                return tagArray.contains(filterTag)
            }
            return false
        }
    }
    
    private var addNoteView: some View {
        NavigationView {
            Form {
                Section(header: Text("Nouvelle note")) {
                    TextEditor(text: $newNoteContent)
                        .frame(minHeight: 150)
                }
                
                Section(header: Text("Tags")) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(availableTags, id: \.self) { tag in
                                TagButton(title: tag, isSelected: selectedTag == tag) {
                                    withAnimation(.spring(response: 0.3)) {
                                        selectedTag = tag
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 5)
                    }
                }
            }
            .navigationTitle("Ajouter une note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") {
                        showingAddNoteSheet = false
                        newNoteContent = ""
                        selectedTag = ""
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Ajouter") {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            addNote()
                            showingAddNoteSheet = false
                        }
                    }
                    .disabled(newNoteContent.isEmpty)
                }
            }
        }
    }
    
    private func addNote() {
        withAnimation {
            let newNote = Note(context: viewContext)
            newNote.id = UUID()
            newNote.content = newNoteContent
            newNote.creationDate = Date()
            
            if !selectedTag.isEmpty {
                let array = [selectedTag]
                newNote.tags = array
            }
            
            do {
                try viewContext.save()
                newNoteContent = ""
                selectedTag = ""
            } catch {
                print("Error adding note: \(error)")
            }
        }
    }
}

struct TagButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.footnote)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    isSelected ?
                    Color.blue :
                    Color.gray.opacity(0.2)
                )
                .cornerRadius(20)
                .shadow(color: isSelected ? .blue.opacity(0.3) : .clear, radius: 5, x: 0, y: 2)
        }
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.3), value: isSelected)
    }
}

struct NoteCardInList: View {
    @ObservedObject var note: Note
    @Environment(\.managedObjectContext) private var viewContext
    
    private var noteGradient: Color {
        getColorForTag().opacity(0.2)
    }
    
    private func getColorForTag() -> Color {
        guard let tagArray = note.tags, let firstTag = tagArray.first else {
            return .yellow
        }
        
        switch firstTag {
        case "Travail":
            return .blue
        case "Personnel":
            return .green
        case "Idée":
            return .purple
        case "Important":
            return .red
        case "Achats":
            return .orange
        default:
            return .yellow
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(note.content ?? "")
                .font(.body)
                .lineLimit(6)
                .multilineTextAlignment(.leading)
                .padding(.bottom, 5)
            
            Spacer(minLength: 0)
            
            HStack {
                if let tagArray = note.tags, let firstTag = tagArray.first {
                    Text(firstTag)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.ultraThinMaterial)
                        .cornerRadius(8)
                }
                
                Spacer()
                
                if let date = note.creationDate {
                    Text(dateFormatter.string(from: date))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(noteGradient)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.white.opacity(0.5), lineWidth: 1)
                )
        )
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
        .contextMenu {
            Button(role: .destructive) {
                deleteNote()
            } label: {
                Label("Supprimer", systemImage: "trash")
            }
        }
    }
    
    private func deleteNote() {
        withAnimation {
            viewContext.delete(note)
            do {
                try viewContext.save()
            } catch {
                print("Erreur lors de la suppression: \(error)")
            }
        }
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter
    }
}

#Preview {
    NotesView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
