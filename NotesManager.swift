import Foundation

class NotesManager: ObservableObject {
    @Published private(set) var notesDict: [String: [Note]] = [:]
    
    init() {
        loadNotes()
    }
    
    func notes(for songTitle: String) -> [Note] {
        return notesDict[songTitle] ?? []
    }
    
    func addNote(for songTitle: String, note: Note) {
        notesDict[songTitle, default: []].append(note)
        saveNotes()
    }
    
    func deleteNotes(at offsets: IndexSet, for songTitle: String) {
        notesDict[songTitle]?.remove(atOffsets: offsets)
        saveNotes()
    }
    
    private func saveNotes() {
        if let data = try? JSONEncoder().encode(notesDict) {
            UserDefaults.standard.set(data, forKey: "notesDict")
        }
    }
    
    private func loadNotes() {
        if let data = UserDefaults.standard.data(forKey: "notesDict"),
           let notesDict = try? JSONDecoder().decode([String: [Note]].self, from: data) {
            self.notesDict = notesDict
        }
    }
}

struct Note: Identifiable, Codable {
    let id = UUID()
    let text: String
    let timestamp: TimeInterval
    
    var timestampString: String {
        let minutes = Int(timestamp) / 60
        let seconds = Int(timestamp) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
