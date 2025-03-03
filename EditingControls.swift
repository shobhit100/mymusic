import SwiftUI

struct EditingControls: View {
    @Binding var selectedSongURLs: Set<URL>
    @Binding var playlists: [Playlist]
    @Binding var isEditing: Bool
    @Binding var showDeleteConfirmation: Bool
    let deleteSelectedSongs: () -> Void
    let addToPlaylist: (Playlist) -> Void

    var body: some View {
        HStack {
            Button(action: {
                selectAllSongs()
            }) {
                Text("Select All")
            }
            Spacer()
            Button(action: {
                showDeleteConfirmation = true
            }) {
                Text("Delete")
                    .foregroundColor(.red)
            }
            .alert(isPresented: $showDeleteConfirmation) {
                Alert(
                    title: Text("Delete Songs"),
                    message: Text("Are you sure you want to delete the selected songs?"),
                    primaryButton: .destructive(Text("Delete")) {
                        deleteSelectedSongs()
                    },
                    secondaryButton: .cancel()
                )
            }
            Spacer()
            Menu {
                ForEach(playlists, id: \.id) { playlist in
                    Button(action: {
                        addToPlaylist(playlist)
                    }) {
                        Text(playlist.name)
                    }
                }
            } label: {
                Text("Add to Playlist")
            }
        }
        .padding()
    }

    private func selectAllSongs() {
        selectedSongURLs = Set(playlists.flatMap { $0.songs })
    }
}
