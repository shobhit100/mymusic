import SwiftUI
import AVFoundation

extension ContentView {
    struct EmptyStateView: View {
        var body: some View {
            VStack {
                Image(systemName: "music.note.list")
                    .font(.system(size: 64))
                    .foregroundColor(.gray)
                    .padding()
                Text("No songs added yet")
                    .font(.title2)
                    .foregroundColor(.gray)
                Text("Tap the '+' button to add songs")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            .padding()
        }
    }
    
    struct MusicPlayerControls: View {
        @Binding var player: AVAudioPlayer?
        @Binding var isPlaying: Bool
        @Binding var currentTime: TimeInterval
        @Binding var totalTime: TimeInterval
        @Binding var currentSongIndex: Int
        @Binding var songs: [URL]
        let previousSong: () -> Void
        let togglePlayPause: () -> Void
        let skip: (Double) -> Void
        let nextSong: () -> Void

        var body: some View {
            VStack {
                if player != nil {
                    VStack {
                        Slider(value: $currentTime, in: 0...totalTime, onEditingChanged: { editing in
                            if !editing {
                                player?.currentTime = currentTime
                            }
                        })
                        .accentColor(.blue)
                        .padding(.horizontal)

                        HStack {
                            Text(timeString(time: currentTime))
                                .font(.caption)
                                .foregroundColor(.gray)
                            Spacer()
                            Text(timeString(time: totalTime))
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .padding(.horizontal)

                        Text(songs[currentSongIndex].lastPathComponent)
                            .font(.headline)
                            .lineLimit(1)
                            .padding(.top, 4)
                    }
                }
                HStack(spacing: 20) {
                    Button(action: previousSong) {
                        Image(systemName: "backward.fill")
                            .font(.system(size: 24))
                            .foregroundColor(songs.isEmpty ? .gray : .blue)
                    }
                    .disabled(songs.isEmpty)

                    Button(action: { skip(-10) }) {
                        Image(systemName: "gobackward.10")
                            .font(.system(size: 20))
                            .foregroundColor(.blue)
                    }

                    Button(action: togglePlayPause) {
                        Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.blue)
                            .scaleEffect(isPlaying ? 1.1 : 1.0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.5, blendDuration: 0), value: isPlaying)
                    }

                    Button(action: { skip(10) }) {
                        Image(systemName: "goforward.10")
                            .font(.system(size: 20))
                            .foregroundColor(.blue)
                    }

                    Button(action: nextSong) {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 24))
                            .foregroundColor(songs.isEmpty ? .gray : .blue)
                    }
                    .disabled(songs.isEmpty)
                }
                .padding(.vertical)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .ignoresSafeArea(.keyboard)
        }

        private func timeString(time: TimeInterval) -> String {
            let minutes = Int(time) / 60
            let seconds = Int(time) % 60
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
    
    struct EditingControls: View {
        @Binding var selectedSongs: Set<URL>
        @Binding var songs: [URL]
        @Binding var isEditing: Bool
        @Binding var showDeleteConfirmation: Bool
        let deleteSelectedSongs: () -> Void

        var body: some View {
            HStack {
                Button(action: {
                    if selectedSongs.count == songs.count {
                        selectedSongs.removeAll()
                    } else {
                        selectedSongs = Set(songs)
                    }
                }) {
                    HStack {
                        Image(systemName: selectedSongs.count == songs.count ? "xmark.circle.fill" : "checkmark.circle.fill")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.blue)
                        Text(selectedSongs.count == songs.count ? "Deselect All" : "Select All")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                        Text("(\(selectedSongs.count))")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                }

                Spacer()

                if !selectedSongs.isEmpty {
                    Button(action: {
                        showDeleteConfirmation = true
                    }) {
                        Image(systemName: "trash")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.blue)
                    }
                    .padding(.trailing, -8)
                    .confirmationDialog("Delete Songs", isPresented: $showDeleteConfirmation) {
                        Button("Delete", role: .destructive) {
                            deleteSelectedSongs()
                        }
                        Button("Cancel", role: .cancel) {}
                    } message: {
                        Text("Are you sure you want to delete \(selectedSongs.count) song(s)?")
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
        }
    }
    
    struct ToolbarContent: View {
        @Binding var isEditing: Bool
        @Binding var selectedSongs: Set<URL>
        let importSong: () -> Void
        @Binding var isSettingsPresented: Bool
        let shareSelectedSongs: () -> Void

        var body: some View {
            Group {
                if isEditing && !selectedSongs.isEmpty {
                    Button(action: shareSelectedSongs) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 20))
                            .foregroundColor(.blue)
                    }
                }

                if isEditing {
                    Button("Done") {
                        isEditing = false
                        selectedSongs.removeAll()
                    }
                } else {
                    HStack {
                        Button(action: importSong) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.blue)
                        }

                        Button(action: { isSettingsPresented = true }) {
                            Image(systemName: "gear")
                                .font(.system(size: 24))
                        }
                    }
                }
            }
        }
    }
}
