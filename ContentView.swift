import SwiftUI
import AVKit

struct ContentView: View {
    @State var songURLs: [URL] = []
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
    @State var selectedSongURLs: Set<URL> = [] // For multi-selection
    @State var isEditing: Bool = false // For multi-deletion mode
    @State var playerDelegate: PlayerDelegate?
    @State var showDeleteConfirmation: Bool = false
    @State var playbackTimer: Timer?
    @State var searchText: String = "" // For search functionality
    @State var areControlsVisible: Bool = true
    @State var duplicateSongNames: [String] = [] // For duplicate song alert
    @FocusState var isSearchFocused: Bool

    // Note-taking states
    @State var isNotesViewPresented: Bool = false
    @ObservedObject var notesManager = NotesManager()

    // Playlist manager state
    @State var playlists: [Playlist] = [Playlist(name: "All")]
    @State var selectedPlaylist: Playlist?

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
                    DocumentPicker(songURLs: $songURLs, duplicateSongNames: $duplicateSongNames, playlists: $playlists)
                }
                .alert(isPresented: .constant(!duplicateSongNames.isEmpty)) {
                    duplicateSongsAlert
                }
                .onAppear {
                    setupAudioSession()
                    loadSongs()
                    loadPlaylists()
                    resumePlayback()
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
                    savePlaybackState()
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willTerminateNotification)) { _ in
                    savePlaybackState()
                    savePlaylists()
                }
                .onChange(of: songURLs) { _ in
                    saveSongs()
                }
                .onChange(of: selectedSongURLs) { _ in
                    isEditing = !selectedSongURLs.isEmpty
                }
                .preferredColorScheme(isDarkMode ? .dark : .light)
            }
        }
    }

    var searchBarSection: some View {
        SearchBar(
            searchText: $searchText,
            isSearchFocused: $isSearchFocused, // Correctly passing FocusState.Binding
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
            selectedSongs: $selectedSongURLs,
            playSong: playSongAtIndex,
            deleteSongs: deleteSongs(offsets:),
            searchText: $searchText,
            isSearchFocused: $isSearchFocused, // Correctly passing FocusState.Binding
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
            previousSong: playPreviousSong,
            togglePlayPause: togglePlayback,
            skip: skipTime,
            nextSong: playNextSong
        )
    }

    var editingControlsSection: some View {
        EditingControls(
            selectedSongURLs: $selectedSongURLs,
            playlists: $playlists,
            isEditing: $isEditing,
            showDeleteConfirmation: $showDeleteConfirmation,
            deleteSelectedSongs: deleteSelectedSongs,
            addToPlaylist: addToPlaylist // Correctly using the function parameter
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
                if currentSongIndex < songURLs.count {
                    notesManager.addNote(for: songURLs[currentSongIndex].lastPathComponent, note: note)
                }
            }
        }
    }

    var toolbarContent: some View { // Correctly define the return type
        ToolbarContent(
            isEditing: $isEditing,
            selectedSongs: $selectedSongURLs,
            importSong: importSong,
            isSettingsPresented: $isSettingsPresented,
            shareSelectedSongs: shareSelectedSongs
        )
    }

    var duplicateSongsAlert: Alert {
        Alert(
            title: Text("Duplicate Songs"),
            message: Text("The following songs are already in your library:\n" + duplicateSongNames.joined(separator: "\n")),
            dismissButton: .default(Text("OK")) {
                duplicateSongNames = [] // Correctly mutate duplicateSongNames
            }
        )
    }

    func shareSelectedSongs() {
        guard !selectedSongURLs.isEmpty else { return }

        let items = Array(selectedSongURLs).map { $0 as Any }
        let activityViewController = UIActivityViewController(activityItems: items, applicationActivities: nil)

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(activityViewController, animated: true, completion: nil)
        }
    }
    
    func selectAllSongs() {
        selectedSongURLs = Set(songURLs)
    }

    func filteredSongs() -> [URL] {
        if let selectedPlaylist = selectedPlaylist, selectedPlaylist.name != "All" {
            return selectedPlaylist.songs
        } else {
            return songURLs
        }
    }

    func playSongAtIndex(_ index: Int) {
        guard index >= 0 && index < filteredSongs().count else {
            print("Index out of range")
            return
        }
        currentSongIndex = index
        let song = filteredSongs()[index]
        playSong(url: song)
    }

    func playSong(url: URL) {
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

    func playPreviousSong() {
        let previousIndex = currentSongIndex - 1
        playSongAtIndex(previousIndex >= 0 ? previousIndex : filteredSongs().count - 1)
    }

    func playNextSong() {
        let nextIndex = currentSongIndex + 1
        playSongAtIndex(nextIndex < filteredSongs().count ? nextIndex : 0)
    }

    func togglePlayback() {
        if isPlaying {
            player?.pause()
        } else {
            player?.play()
        }
        isPlaying.toggle()
    }

    func skipTime(_ seconds: Double) {
        guard let player = player else { return }
        let newTime = player.currentTime + seconds
        if newTime >= 0 && newTime <= player.duration {
            player.currentTime = newTime
        }
    }

    func deleteSongs(offsets: IndexSet) {
        if offsets.contains(currentSongIndex) {
            player?.stop()
            player = nil
            isPlaying = false
            currentTime = 0
            totalTime = 0
        }
        
        songURLs.remove(atOffsets: offsets)
        
        if songURLs.isEmpty {
            currentSongIndex = 0
        } else if currentSongIndex >= songURLs.count {
            currentSongIndex = max(0, songURLs.count - 1)
        }
        
        saveSongs()
        checkControlVisibility()
    }

    func savePlaylists() {
        if let data = try? JSONEncoder().encode(playlists) {
            UserDefaults.standard.set(data, forKey: "playlists")
        }
    }

    func loadPlaylists() {
        if let data = UserDefaults.standard.data(forKey: "playlists"),
           let loadedPlaylists = try? JSONDecoder().decode([Playlist].self, from: data) {
            playlists = loadedPlaylists
        }
    }

    func addToPlaylist(_ playlist: Playlist) {
        guard !selectedSongURLs.isEmpty else { return }
        if let index = playlists.firstIndex(where: { $0.id == playlist.id }) {
            playlists[index].songs.append(contentsOf: selectedSongURLs)
            savePlaylists()
        }
    }
}
