import SwiftUI
import AVKit

extension ContentView {
    func playSong(at index: Int) {
        playbackTimer?.invalidate()
        
        guard !songURLs.isEmpty else {
            cleanupPlayer()
            return
        }
        
        guard index >= 0 && index < songURLs.count else { return }
        
        cleanupPlayer()
        
        currentSongIndex = index
        let url = songURLs[index]
        
        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.prepareToPlay()
            player?.play()
            
            playerDelegate = PlayerDelegate(onSongEnd: nextSong)
            player?.delegate = playerDelegate
            
            isPlaying = true
            totalTime = player?.duration ?? 0
            
            startPlaybackTimer()
            savePlaybackState()
        } catch {
            print("Error playing song: \(error.localizedDescription)")
        }
    }
    
    func togglePlayPause() {
        if songURLs.isEmpty {
            return
        }
        
        if player == nil {
            playSong(at: 0)
        } else if let player = player {
            if player.isPlaying {
                player.pause()
                isPlaying = false
                playbackTimer?.invalidate()
            } else {
                player.play()
                isPlaying = true
                startPlaybackTimer()
            }
        }
        savePlaybackState()
    }
    
    func nextSong() {
        guard !songURLs.isEmpty else { return }
        if isShuffleOn {
            currentSongIndex = Int.random(in: 0..<songURLs.count)
        } else {
            currentSongIndex = (currentSongIndex + 1) % songURLs.count
        }
        playSong(at: currentSongIndex)
    }

    func previousSong() {
        guard !songURLs.isEmpty else { return }
        if isShuffleOn {
            currentSongIndex = Int.random(in: 0..<songURLs.count)
        } else {
            currentSongIndex = (currentSongIndex - 1 + songURLs.count) % songURLs.count
        }
        playSong(at: currentSongIndex)
    }
    
    func skip(by seconds: Double) {
        guard let player = player else { return }
        player.currentTime += seconds
        currentTime = player.currentTime
        savePlaybackState()
    }

    func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Error setting up audio session: \(error.localizedDescription)")
        }
    }
    
    func importSong() {
        isDocumentPickerPresented = true
    }
    
    func deleteSelectedSongs() {
        if selectedSongURLs.contains(songURLs[currentSongIndex]) {
            cleanupPlayer()
        }
        
        songURLs.removeAll { selectedSongURLs.contains($0) }
        selectedSongURLs.removeAll()
        isEditing = false
        
        if songURLs.isEmpty {
            currentSongIndex = 0
            cleanupPlayer()
        } else if currentSongIndex >= songURLs.count {
            currentSongIndex = max(0, songURLs.count - 1)
        }
        
        saveSongs()
    }
    
    func deleteSongs(at offsets: IndexSet) {
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
    
    func saveSongs() {
        let songPaths = songURLs.map { $0.path }
        UserDefaults.standard.set(songPaths, forKey: "savedSongs")
    }
    
    func loadSongs() {
        if let songPaths = UserDefaults.standard.array(forKey: "savedSongs") as? [String] {
            songURLs = songPaths.map { URL(fileURLWithPath: $0) }
        }
    }
    
    func savePlaybackState() {
        UserDefaults.standard.set(currentSongIndex, forKey: "currentSongIndex")
        UserDefaults.standard.set(currentTime, forKey: "currentTime")
        UserDefaults.standard.set(isPlaying, forKey: "isPlaying")
    }

    func resumePlayback() {
        let savedSongIndex = UserDefaults.standard.integer(forKey: "currentSongIndex")
        let savedTime = UserDefaults.standard.double(forKey: "currentTime")
        
        if savedSongIndex >= 0 && savedSongIndex < songURLs.count {
            currentSongIndex = savedSongIndex
            currentTime = savedTime
            
            let url = songURLs[savedSongIndex]
            do {
                player = try AVAudioPlayer(contentsOf: url)
                player?.prepareToPlay()
                player?.currentTime = savedTime
                totalTime = player?.duration ?? 0
                
                playerDelegate = PlayerDelegate(onSongEnd: nextSong)
                player?.delegate = playerDelegate
                
                if player != nil {
                    startPlaybackTimer()
                }
                
                player?.pause()
                isPlaying = false
            } catch {
                print("Error loading saved song: \(error.localizedDescription)")
            }
        } else {
            cleanupPlayer()
        }
    }
    
    func startPlaybackTimer() {
        playbackTimer?.invalidate()
        
        playbackTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            guard let player = self.player, !self.isEditingProgress else { return }
            self.currentTime = player.currentTime
            if !player.isPlaying {
                self.isPlaying = false
                timer.invalidate()
            }
        }
    }
    
    func cleanupPlayer() {
        playbackTimer?.invalidate()
        playbackTimer = nil
        player?.stop()
        player = nil
        isPlaying = false
        currentTime = 0
        totalTime = 0
    }
    
    func addSongs(_ newSongs: [URL]) {
        var duplicateFound = false
        for song in newSongs {
            if songURLs.contains(song) {
                duplicateFound = true
                duplicateSongNames.append(song.lastPathComponent)
            } else {
                songURLs.append(song)
            }
        }
        if duplicateFound {
            duplicateSongNames = Array(Set(duplicateSongNames)) // Remove duplicates in alert
        }
        saveSongs()
    }
    
    func checkControlVisibility() {
        if searchText.isEmpty && !isSearchFocused {
            areControlsVisible = true
        }
    }
    
    class PlayerDelegate: NSObject, AVAudioPlayerDelegate {
        var onSongEnd: () -> Void
        
        init(onSongEnd: @escaping () -> Void) {
            self.onSongEnd = onSongEnd
        }
        
        func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
            onSongEnd()
        }
    }
}
