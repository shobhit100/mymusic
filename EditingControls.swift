import SwiftUI

struct EditingControls: View {
    @Binding var selectedSongs: Set<URL>
    @Binding var songs: [URL]
    @Binding var isEditing: Bool
    @Binding var showDeleteConfirmation: Bool
    let deleteSelectedSongs: () -> Void
    let selectAllSongs: () -> Void

    var body: some View {
        VStack {
            HStack {
                Button(action: {
                    showDeleteConfirmation = true
                }) {
                    Text("Delete (\(selectedSongs.count))")
                        .foregroundColor(.red)
                }
                .disabled(selectedSongs.isEmpty)
                Spacer()
                Button(action: {
                    selectAllSongs()
                }) {
                    Text("Select All")
                }
            }
            .padding()
        }
        .background(Color(.systemGray6))
        .cornerRadius(8)
        .padding(.horizontal)
    }
}
