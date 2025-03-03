import SwiftUI

struct PlaylistManager: View {
    @Binding var allSongs: [URL]
    @Binding var playlists: [Playlist]
    @Binding var selectedPlaylist: Playlist?
    @State private var showAddPlaylistSheet: Bool = false
    @State private var newPlaylistName: String = "New Playlist 1"
    @State private var showAlert: Bool = false
    
    @Binding var currentSongIndex: Int
    @Binding var isEditing: Bool
    @Binding var selectedSongs: Set<URL>
    let playSong: (Int) -> Void
    let deleteSongs: (IndexSet) -> Void
    @Binding var searchText: String
    @FocusState var isSearchFocused: Bool
    @Binding var areControlsVisible: Bool
    @Binding var showDeleteConfirmation: Bool
    @ObservedObject var notesManager: NotesManager

    var body: some View {
        VStack {
            playlistTabs
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Duplicate Name"), message: Text("A playlist with this name already exists. Please choose a different name."), dismissButton: .default(Text("OK")))
        }
    }

    private var playlistTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(playlists) { playlist in
                    Button(action: {
                        selectedPlaylist = playlist
                    }) {
                        Text(playlist.name)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .background(selectedPlaylist?.id == playlist.id ? Color.blue : Color.gray.opacity(0.2))
                            .foregroundColor(selectedPlaylist?.id == playlist.id ? .white : .black)
                            .cornerRadius(8)
                    }
                }
                addPlaylistButton
            }
            .padding(.horizontal)
        }
    }

    private var addPlaylistButton: some View {
        Button(action: {
            showAddPlaylistSheet = true
        }) {
            Image(systemName: "plus.circle.fill")
                .font(.system(size: 24))
                .foregroundColor(.blue)
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(8)
        }
        .sheet(isPresented: $showAddPlaylistSheet) {
            AddPlaylistView(playlists: $playlists, newPlaylistName: $newPlaylistName, showAlert: $showAlert)
        }
    }
}

struct Playlist: Identifiable {
    let id = UUID()
    var name: String
    var songs: [URL] = []
}

struct PlaylistDetailView: View {
    let playlist: Playlist

    var body: some View {
        VStack {
            if playlist.songs.isEmpty {
                Text("No songs in this playlist")
                    .font(.title2)
                    .foregroundColor(.gray)
                    .padding()
            } else {
                List(playlist.songs, id: \.self) { song in
                    Text(song.lastPathComponent)
                        .font(.headline)
                }
                .listStyle(InsetGroupedListStyle())
            }
        }
        .navigationTitle(playlist.name)
    }
}

struct AddPlaylistView: View {
    @Binding var playlists: [Playlist]
    @Binding var newPlaylistName: String
    @Binding var showAlert: Bool
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        VStack {
            Text("Enter Playlist Name")
                .font(.headline)
                .padding()
            TextField("Playlist Name", text: $newPlaylistName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            HStack {
                Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
                .padding()
                Spacer()
                Button("Save") {
                    if playlists.contains(where: { $0.name == newPlaylistName }) {
                        showAlert = true
                    } else {
                        let newPlaylist = Playlist(name: newPlaylistName)
                        playlists.append(newPlaylist)
                        newPlaylistName = "New Playlist \(playlists.count)"
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                .padding()
                .disabled(newPlaylistName.isEmpty)
            }
            .padding()
        }
        .frame(width: 300)
        .background(Color.white)
        .cornerRadius(10)
        .shadow(radius: 20)
        .padding()
    }
}
