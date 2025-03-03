import SwiftUI
import AVKit

struct ContentViewSubViews {
    static func searchBarSection(searchText: Binding<String>, isSearchFocused: FocusState<Bool>.Binding, areControlsVisible: Binding<Bool>) -> some View {
        SearchBar(
            searchText: searchText,
            isSearchFocused: isSearchFocused.projectedValue, // Correctly converting FocusState.Binding
            areControlsVisible: areControlsVisible
        )
        .padding(.horizontal)
    }

    static func playlistTabsSection(playlists: Binding<[Playlist]>, selectedPlaylist: Binding<Playlist?>) -> some View {
        PlaylistTabsView(playlists: playlists, selectedPlaylist: selectedPlaylist)
    }

    static func songListSection(songs: Binding<[URL]>, playlists: Binding<[Playlist]>, currentSongIndex: Binding<Int>, isEditing: Binding<Bool>, selectedSongs: Binding<Set<URL>>, playSong: @escaping (Int) -> Void, deleteSongs: @escaping (IndexSet) -> Void, searchText: Binding<String>, isSearchFocused: FocusState<Bool>.Binding, areControlsVisible: Binding<Bool>, showDeleteConfirmation: Binding<Bool>, notesManager: NotesManager) -> some View {
        SongList(
            songs: songs,
            playlists: playlists,
            currentSongIndex: currentSongIndex,
            isEditing: isEditing,
            selectedSongs: selectedSongs,
            playSong: playSong,
            deleteSongs: deleteSongs,
            searchText: searchText,
            isSearchFocused: isSearchFocused.projectedValue, // Correctly converting FocusState.Binding
            areControlsVisible: areControlsVisible,
            showDeleteConfirmation: showDeleteConfirmation,
            notesManager: notesManager
        )
    }

    static func musicPlayerControlsSection(player: Binding<AVAudioPlayer?>, isPlaying: Binding<Bool>, currentTime: Binding<TimeInterval>, totalTime: Binding<TimeInterval>, currentSongIndex: Binding<Int>, songs: Binding<[URL]>, previousSong: @escaping () -> Void, togglePlayPause: @escaping () -> Void, skip: @escaping (Double) -> Void, nextSong: @escaping () -> Void) -> some View {
        MusicPlayerControls(
            player: player,
            isPlaying: isPlaying,
            currentTime: currentTime,
            totalTime: totalTime,
            currentSongIndex: currentSongIndex,
            songs: songs,
            previousSong: previousSong,
            togglePlayPause: togglePlayPause,
            skip: skip,
            nextSong: nextSong
        )
    }

    static func editingControlsSection(selectedSongURLs: Binding<Set<URL>>, playlists: Binding<[Playlist]>, isEditing: Binding<Bool>, showDeleteConfirmation: Binding<Bool>, deleteSelectedSongs: @escaping () -> Void, addToPlaylist: @escaping (Playlist) -> Void) -> some View {
        EditingControls(
            selectedSongs: selectedSongURLs,
            songs: playlists.wrappedValue.flatMap { $0.songs },
            isEditing: isEditing,
            showDeleteConfirmation: showDeleteConfirmation,
            deleteSelectedSongs: deleteSelectedSongs
        )
    }

    static func addNoteButton(isNotesViewPresented: Binding<Bool>, player: AVAudioPlayer?, currentSongIndex: Int, songURLs: [URL], notesManager: NotesManager) -> some View {
        Button("Add Note") {
            isNotesViewPresented.wrappedValue = true
        }
        .padding()
        .sheet(isPresented: isNotesViewPresented) {
            NotesView(isPresented: isNotesViewPresented) { noteText in
                let currentTime = player?.currentTime ?? 0.0
                let note = Note(text: noteText, timestamp: currentTime)
                if currentSongIndex < songURLs.count {
                    notesManager.addNote(for: songURLs[currentSongIndex].lastPathComponent, note: note)
                }
            }
        }
    }

    static func toolbarContent(isEditing: Binding<Bool>, selectedSongs: Binding<Set<URL>>, importSong: @escaping () -> Void, isSettingsPresented: Binding<Bool>, shareSelectedSongs: @escaping () -> Void) -> some ToolbarContent {
        ToolbarItemGroup(placement: .navigationBarTrailing) {
            if isEditing.wrappedValue && !selectedSongs.wrappedValue.isEmpty {
                Button(action: shareSelectedSongs) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 20))
                        .foregroundColor(.blue)
                }
            }

            if isEditing.wrappedValue {
                Button("Done") {
                    isEditing.wrappedValue = false
                    selectedSongs.wrappedValue.removeAll()
                }
            } else {
                HStack {
                    Button(action: importSong) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.blue)
                    }

                    Button(action: { isSettingsPresented.wrappedValue = true }) {
                        Image(systemName: "gear")
                            .font(.system(size: 24))
                    }
                }
            }
        }
    }

    static func duplicateSongsAlert(duplicateSongNames: Binding<[String]>) -> Alert {
        Alert(
            title: Text("Duplicate Songs"),
            message: Text("The following songs are already in your library:\n" + duplicateSongNames.wrappedValue.joined(separator: "\n")),
            dismissButton: .default(Text("OK")) {
                duplicateSongNames.wrappedValue.removeAll() // Correctly mutate duplicateSongNames
            }
        )
    }

    static func shareSelectedSongs(selectedSongURLs: Set<URL>) {
        guard !selectedSongURLs.isEmpty else { return }

        let items = Array(selectedSongURLs).map { $0 as Any }
        let activityViewController = UIActivityViewController(activityItems: items, applicationActivities: nil)

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(activityViewController, animated: true, completion: nil)
        }
    }

    static func selectAllSongs(songURLs: [URL], selectedSongURLs: Binding<Set<URL>>) {
        selectedSongURLs.wrappedValue = Set(songURLs)
    }

    static func filteredSongs(songURLs: [URL], selectedPlaylist: Playlist?) -> [URL] {
        if let selectedPlaylist = selectedPlaylist, selectedPlaylist.name != "All" {
            return selectedPlaylist.songs
        } else {
            return songURLs
        }
    }

    static func playSongAtIndex(index: Int, filteredSongs: [URL], currentSongIndex: Binding<Int>, playSong: @escaping (URL) -> Void) {
        guard index >= 0 && index < filteredSongs.count else {
            print("Index out of range")
            return
        }
        currentSongIndex.wrappedValue = index
        let song = filteredSongs[index]
        playSong(song)
    }

    static func playSong(url: URL, player: Binding<AVAudioPlayer?>, playerDelegate: AVAudioPlayerDelegate?, isPlaying: Binding<Bool>, startPlaybackTimer: @escaping () -> Void) {
        do {
            player.wrappedValue = try AVAudioPlayer(contentsOf: url)
            player.wrappedValue?.delegate = playerDelegate
            player.wrappedValue?.prepareToPlay()
            player.wrappedValue?.play()
            isPlaying.wrappedValue = true
            startPlaybackTimer()
        } catch {
            print("Error playing song: \(error.localizedDescription)")
        }
    }

    static func playPreviousSong(currentSongIndex: Binding<Int>, filteredSongs: [URL], playSongAtIndex: @escaping (Int) -> Void) {
        let previousIndex = currentSongIndex.wrappedValue - 1
        playSongAtIndex(previousIndex >= 0 ? previousIndex : filteredSongs.count - 1)
    }

    static func playNextSong(currentSongIndex: Binding<Int>, filteredSongs: [URL], playSongAtIndex: @escaping (Int) -> Void) {
        let nextIndex = currentSongIndex.wrappedValue + 1
        playSongAtIndex(nextIndex < filteredSongs.count ? nextIndex : 0)
    }

    static func togglePlayback(player: Binding<AVAudioPlayer?>, isPlaying: Binding<Bool>) {
        if isPlaying.wrappedValue {
            player.wrappedValue?.pause()
        } else {
            player.wrappedValue?.play()
        }
        isPlaying.wrappedValue.toggle()
    }

    static func skipTime(player: Binding<AVAudioPlayer?>, seconds: Double) {
        guard let player = player.wrappedValue else { return }
        let newTime = player.currentTime + seconds
        if newTime >= 0 && newTime <= player.duration {
            player.currentTime = newTime
        }
    }

    static func savePlaylists(playlists: [Playlist]) {
        if let data = try? JSONEncoder().encode(playlists) {
            UserDefaults.standard.set(data, forKey: "playlists")
        }
    }

    static func loadPlaylists() -> [Playlist] {
        if let data = UserDefaults.standard.data(forKey: "playlists"),
           let loadedPlaylists = try? JSONDecoder().decode([Playlist].self, from: data) {
            return loadedPlaylists
        }
        return [Playlist(name: "All")]
    }

    static func addToPlaylist(playlist: Playlist, selectedSongURLs: Set<URL>, playlists: Binding<[Playlist]>) {
        guard !selectedSongURLs.isEmpty else { return }
        if let index = playlists.wrappedValue.firstIndex(where: { $0.id == playlist.id }) {
            playlists.wrappedValue[index].songs.append(contentsOf: selectedSongURLs)
            savePlaylists(playlists: playlists.wrappedValue)
        }
    }
}
