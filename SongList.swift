import SwiftUI

struct SongList: View {
    @Binding var songs: [URL]
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
    @State private var isNotesListViewPresented: Bool = false
    @State private var selectedSongForNotes: URL?

    var filteredSongs: [URL] {
        if searchText.isEmpty {
            return songs
        } else {
            return songs.filter { $0.lastPathComponent.localizedCaseInsensitiveContains(searchText) }
        }
    }

    var body: some View {
        List {
            ForEach(filteredSongs, id: \.self) { song in
                HStack {
                    VStack(alignment: .leading) {
                        Text(song.lastPathComponent)
                            .foregroundColor(song == songs[currentSongIndex] ? .blue : .primary)
                            .onTapGesture {
                                if !isEditing {
                                    if let index = songs.firstIndex(of: song) {
                                        playSong(index)
                                    }
                                    searchText = ""
                                    isSearchFocused = false
                                    areControlsVisible = true
                                }
                            }
                            .padding(.vertical, 8)
                            .background(song == songs[currentSongIndex] ? Color.blue.opacity(0.1) : Color.clear)
                            .cornerRadius(8)
                    }
                    Spacer()
                    Button(action: {
                        selectedSongForNotes = song
                        isNotesListViewPresented = true
                    }) {
                        Image(systemName: "note.text")
                            .foregroundColor(.blue)
                            .padding(.leading, 8)
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(PlainButtonStyle())
                    if isEditing {
                        Image(systemName: selectedSongs.contains(song) ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 20))
                            .foregroundColor(selectedSongs.contains(song) ? .blue : .gray)
                            .transition(.opacity)
                            .onTapGesture {
                                if selectedSongs.contains(song) {
                                    selectedSongs.remove(song)
                                } else {
                                    selectedSongs.insert(song)
                                }
                            }
                    }
                }
                .contentShape(Rectangle())
                .onLongPressGesture {
                    isEditing = true
                    selectedSongs.insert(song)
                    areControlsVisible = false
                }
            }
            .onDelete { indexSet in
                deleteSongs(indexSet)
            }
        }
        .listStyle(InsetGroupedListStyle())
        .environment(\.editMode, .constant(isEditing ? .active : .inactive))
        .sheet(isPresented: $isNotesListViewPresented) {
            if let songForNotes = selectedSongForNotes {
                NotesListView(notesManager: notesManager, songTitle: songForNotes.lastPathComponent)
            }
        }
    }
}
