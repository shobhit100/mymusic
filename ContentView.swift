import SwiftUI
import AVKit

struct ContentView: View {
    @State var songs: [URL] = []
    @State var currentSongIndex: Int = 0
    @State var isPlaying: Bool = false
    @State var player: AVAudioPlayer?
    @State var currentTime: TimeInterval = 0
    @State var totalTime: TimeInterval = 0
    @State var isEditingProgress: Bool = false
    @State var isSettingsPresented: Bool = false
    @State var isShuffleOn: Bool = false
    @AppStorage("isDarkMode") var isDarkMode: Bool = false
    @State var isDocumentPickerPresented = false
    @State var selectedSongs: Set<URL> = [] // For multi-selection
    @State var isEditing: Bool = false // For multi-deletion mode
    @State var playerDelegate: PlayerDelegate?
    @State var showDeleteConfirmation: Bool = false
    @State var playbackTimer: Timer?
    @State var searchText: String = "" // For search functionality
    @State var areControlsVisible: Bool = true
    @State var duplicateSongs: [String] = [] // For duplicate song alert
    @FocusState var isSearchFocused: Bool
    
    // Note-taking states
    @State var isNotesViewPresented: Bool = false
    @ObservedObject var notesManager = NotesManager()

    // Playlist manager state
    @State private var playlists: [Playlist] = [Playlist(name: "All")]
    @State private var selectedPlaylist: Playlist?

    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                VStack {
                    searchBarSection
                    playlistTabsSection
                    if filteredSongs().isEmpty {
                        EmptyStateView()
                    } else {
                        songListSection
                    }
                    Spacer()
                    if areControlsVisible {
                        musicPlayerControlsSection
                    }
                    if isEditing {
                        editingControlsSection
                    }
                    if !filteredSongs().isEmpty && !isEditing {
                        addNoteButton
                    }
                }
                .navigationTitle("Music App")
                .toolbar {
                    ToolbarItemGroup(placement: .navigationBarTrailing) {
                        toolbarContent
                    }
                }
                .sheet(isPresented: $isSettingsPresented) {
                    SettingsView(isDarkMode: $isDarkMode, isShuffleOn: $isShuffleOn)
                        .preferredColorScheme(isDarkMode ? .dark : .light)
                }
                .sheet(isPresented: $isDocumentPickerPresented) {
                    DocumentPicker(songs: $songs, duplicateSongs: $duplicateSongs, playlists: $playlists)
                }
                .alert(isPresented: .constant(!duplicateSongs.isEmpty)) {
                    duplicateSongsAlert
                }
                .onAppear {
                    setupAudioSession()
                    loadSongs()
                    resumePlayback()
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
                    savePlaybackState()
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willTerminateNotification)) { _ in
                    savePlaybackState()
                }
                .onChange(of: songs) { _ in
                    saveSongs()
                }
                .onChange(of: selectedSongs) { _ in
                    isEditing = !selectedSongs.isEmpty
                }
                .preferredColorScheme(isDarkMode ? .dark : .light)
            }
        }
    }

    // Breaking down complex expressions into smaller parts
    var searchBarSection: some View {
        SearchBar(
            searchText: $searchText,
            isSearchFocused: _isSearchFocused,
            areControlsVisible: $areControlsVisible
        )
        .padding(.horizontal)
    }

    var playlistTabsSection: some View {
        PlaylistTabsView(playlists: $playlists, selectedPlaylist: $selectedPlaylist)
    }

    var songListSection: some View {
        SongList(
            songs: Binding(get: {
                filteredSongs()
            }, set: { newSongs in
                if let index = playlists.firstIndex(where: { $0.id == selectedPlaylist?.id }) {
                    playlists[index].songs = newSongs
                }
            }),
            playlists: $playlists,
            currentSongIndex: $currentSongIndex,
            isEditing: $isEditing,
            selectedSongs: $selectedSongs,
            playSong: playSong,
            deleteSongs: deleteSongs,
            searchText: $searchText,
            isSearchFocused: _isSearchFocused,
            areControlsVisible: $areControlsVisible,
            showDeleteConfirmation: $showDeleteConfirmation,
            notesManager: notesManager
        )
    }

    var musicPlayerControlsSection: some View {
        MusicPlayerControls(
            player: $player,
            isPlaying: $isPlaying,
            currentTime: $currentTime,
            totalTime: $totalTime,
            currentSongIndex: $currentSongIndex,
            songs: Binding(get: {
                filteredSongs()
            }, set: { _ in }),
            previousSong: previousSong,
            togglePlayPause: togglePlayPause,
            skip: skip,
            nextSong: nextSong
        )
    }

    var editingControlsSection: some View {
        EditingControls(
            selectedSongs: $selectedSongs,
            songs: $songs,
            isEditing: $isEditing,
            showDeleteConfirmation: $showDeleteConfirmation,
            deleteSelectedSongs: deleteSelectedSongs
        )
    }

    var addNoteButton: some View {
        Button("Add Note") {
            isNotesViewPresented = true
        }
        .padding()
        .sheet(isPresented: $isNotesViewPresented) {
            NotesView(isPresented: $isNotesViewPresented) { noteText in
                let currentTime = player?.currentTime ?? 0.0
                let note = Note(text: noteText, timestamp: currentTime)
                notesManager.addNote(for: songs[currentSongIndex].lastPathComponent, note: note)
            }
        }
    }

    var toolbarContent: some View {
        ToolbarContent(
            isEditing: $isEditing,
            selectedSongs: $selectedSongs,
            importSong: importSong,
            isSettingsPresented: $isSettingsPresented,
            shareSelectedSongs: shareSelectedSongs
        )
    }

    var duplicateSongsAlert: Alert {
        Alert(
            title: Text("Duplicate Songs"),
            message: Text("The following songs are already in your library:\n" + duplicateSongs.joined(separator: "\n")),
            dismissButton: .default(Text("OK")) {
                duplicateSongs.removeAll()
            }
        )
    }

    func shareSelectedSongs() {
        guard !selectedSongs.isEmpty else { return }

        let items = Array(selectedSongs).map { $0 as Any }
        let activityViewController = UIActivityViewController(activityItems: items, applicationActivities: nil)

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(activityViewController, animated: true, completion: nil)
        }
    }
    
    func selectAllSongs() {
        selectedSongs = Set(songs)
    }

    private func filteredSongs() -> [URL] {
        if let selectedPlaylist = selectedPlaylist, selectedPlaylist.name != "All" {
            return selectedPlaylist.songs
        } else {
            return songs
        }
    }

    private func playSong(at index: Int) {
        guard index >= 0 && index < filteredSongs().count else {
            print("Index out of range")
            return
        }
        currentSongIndex = index
        let song = filteredSongs()[index]
        playSong(url: song)
    }

    private func playSong(url: URL) {
        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.delegate = playerDelegate
            player?.prepareToPlay()
            player?.play()
            isPlaying = true
            startPlaybackTimer()
        } catch {
            print("Error playing song: \(error.localizedDescription)")
        }
    }

    private func previousSong() {
        let previousIndex = currentSongIndex - 1
        playSong(at: previousIndex >= 0 ? previousIndex : filteredSongs().count - 1)
    }

    private func nextSong() {
        let nextIndex = currentSongIndex + 1
        playSong(at: nextIndex < filteredSongs().count ? nextIndex : 0)
    }

    private func togglePlayPause() {
        if isPlaying {
            player?.pause()
        } else {
            player?.play()
        }
        isPlaying.toggle()
    }

    private func skip(seconds: Double) {
        guard let player = player else { return }
        let newTime = player.currentTime + seconds
        if newTime >= 0 && newTime <= player.duration {
            player.currentTime = newTime
        }
    }
}
