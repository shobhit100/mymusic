import SwiftUI

struct SongList: View {
    @Binding var songs: [URL]
    @Binding var playlists: [Playlist]
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
    @State private var showAddToPlaylistSheet: Bool = false
    @State private var newPlaylistName: String = ""

    var body: some View {
        if songs.isEmpty {
            Text("No songs available")
                .font(.title2)
                .foregroundColor(.gray)
                .padding()
        } else {
            List {
                ForEach(filteredSongs(), id: \.self) { song in
                    HStack {
                        Text(song.lastPathComponent)
                            .font(.headline)
                            .onTapGesture {
                                if !isEditing {
                                    if let index = songs.firstIndex(of: song) {
                                        playSong(index)
                                    }
                                } else {
                                    if selectedSongs.contains(song) {
                                        selectedSongs.remove(song)
                                    } else {
                                        selectedSongs.insert(song)
                                    }
                                }
                            }
                            .contextMenu {
                                Button(action: {
                                    if selectedSongs.contains(song) {
                                        selectedSongs.remove(song)
                                    } else {
                                        selectedSongs.insert(song)
                                    }
                                }) {
                                    Text(selectedSongs.contains(song) ? "Deselect" : "Select")
                                }
                                Button(action: {
                                    showAddToPlaylistSheet = true
                                }) {
                                    Text("Add to Playlist")
                                }
                            }
                            .onLongPressGesture {
                                if !isEditing {
                                    isEditing = true
                                    selectedSongs.insert(song)
                                    areControlsVisible = false
                                }
                            }
                        Spacer()
                        if isEditing {
                            Image(systemName: selectedSongs.contains(song) ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(selectedSongs.contains(song) ? .blue : .gray)
                                .onTapGesture {
                                    if selectedSongs.contains(song) {
                                        selectedSongs.remove(song)
                                    } else {
                                        selectedSongs.insert(song)
                                    }
                                }
                        }
                    }
                }
                .onDelete(perform: deleteSongs)
            }
            .listStyle(InsetGroupedListStyle())
            .focused($isSearchFocused)
            .onChange(of: searchText) { _ in
                areControlsVisible = searchText.isEmpty
            }
            .sheet(isPresented: $showAddToPlaylistSheet) {
                AddToPlaylistView(playlists: $playlists, selectedSongs: Array(selectedSongs), newPlaylistName: $newPlaylistName, showAddToPlaylistSheet: $showAddToPlaylistSheet)
            }
        }
    }

    private func filteredSongs() -> [URL] {
        if searchText.isEmpty {
            return songs
        } else {
            return songs.filter { $0.lastPathComponent.lowercased().contains(searchText.lowercased()) }
        }
    }
}
