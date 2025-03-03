import SwiftUI

struct NotesListView: View {
    @ObservedObject var notesManager: NotesManager
    var songTitle: String
    
    var body: some View {
        List {
            ForEach(notesManager.notes(for: songTitle)) { note in
                VStack(alignment: .leading) {
                    Text(note.text)
                        .font(.body)
                    Text(note.timestampString)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .onDelete { indexSet in
                notesManager.deleteNotes(at: indexSet, for: songTitle)
            }
        }
        .navigationTitle("Notes")
        .toolbar {
            EditButton()
        }
    }
}
