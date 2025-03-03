import SwiftUI

struct AddToPlaylistView: View {
    @Binding var playlists: [Playlist]
    var selectedSongs: [URL]
    @Binding var newPlaylistName: String
    @Binding var showAddToPlaylistSheet: Bool
    @State private var selectedPlaylist: Playlist?

    var body: some View {
        NavigationView {
            VStack {
                List {
                    ForEach(playlists) { playlist in
                        Button(action: {
                            selectedPlaylist = playlist
                        }) {
                            HStack {
                                Text(playlist.name)
                                Spacer()
                                if selectedPlaylist?.id == playlist.id {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                    TextField("New Playlist Name", text: $newPlaylistName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                }
                .navigationTitle("Add to Playlist")
                .navigationBarItems(leading: Button("Cancel") {
                    showAddToPlaylistSheet = false
                }, trailing: Button("Done") {
                    addSongsToPlaylist()
                    showAddToPlaylistSheet = false
                }.disabled(selectedPlaylist == nil && newPlaylistName.isEmpty))
            }
        }
    }

    private func addSongsToPlaylist() {
        if let selectedPlaylist = selectedPlaylist {
            for song in selectedSongs {
                if !selectedPlaylist.songs.contains(song) {
                    if let index = playlists.firstIndex(where: { $0.id == selectedPlaylist.id }) {
                        playlists[index].songs.append(song)
                    }
                }
            }
        } else if !newPlaylistName.isEmpty {
            let newPlaylist = Playlist(name: newPlaylistName, songs: selectedSongs)
            playlists.append(newPlaylist)
            newPlaylistName = ""
        }
    }
}
