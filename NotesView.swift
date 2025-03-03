import SwiftUI

struct NotesView: View {
    @Binding var isPresented: Bool
    var onSave: (String) -> Void
    @State private var noteText: String = ""
    
    var body: some View {
        NavigationView {
            VStack {
                TextEditor(text: $noteText)
                    .padding()
                Spacer()
            }
            .navigationTitle("Add Note")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(noteText)
                        isPresented = false
                    }
                    .disabled(noteText.isEmpty)
                }
            }
        }
    }
}
