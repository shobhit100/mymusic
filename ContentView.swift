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
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                VStack {
                    searchBarSection
                    songListSection
                    if songs.isEmpty {
                        EmptyStateView()
                    }
                    Spacer()
                    if areControlsVisible {
                        musicPlayerControlsSection
                    }
                    if isEditing {
                        editingControlsSection
                    }
                    if !songs.isEmpty {
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
                    DocumentPicker(songs: $songs, duplicateSongs: $duplicateSongs)
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
    }

    var songListSection: some View {
        SongList(
            songs: $songs,
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
            songs: $songs,
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
}
