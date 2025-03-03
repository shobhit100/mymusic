import SwiftUI

struct PlaylistTabsView: View {
    @Binding var playlists: [Playlist]
    @Binding var selectedPlaylist: Playlist?
    @State private var newPlaylistName: String = ""
    @State private var isShowingNewPlaylistSheet: Bool = false

    var body: some View {
        HStack {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 2) {
                    ForEach(playlists) { playlist in
                        Button(action: {
                            selectedPlaylist = playlist
                        }) {
                            Text(playlist.name)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .background(
                                    Capsule()
                                        .fill(selectedPlaylist?.id == playlist.id ? Color.blue : Color.gray.opacity(0.3))
                                        .shadow(color: selectedPlaylist?.id == playlist.id ? Color.black.opacity(0.2) : Color.clear, radius: 4, x: 0, y: 2)
                                )
                                .foregroundColor(selectedPlaylist?.id == playlist.id ? .white : .black)
                                .overlay(
                                    Capsule()
                                        .stroke(selectedPlaylist?.id == playlist.id ? Color.blue : Color.clear, lineWidth: 1)
                                )
                        }
                    }
                }
                .padding(.horizontal)
            }
            Button(action: {
                isShowingNewPlaylistSheet = true
            }) {
                Image(systemName: "plus")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .clipShape(Circle())
                    .shadow(radius: 4)
            }
            .padding(.trailing)
            .sheet(isPresented: $isShowingNewPlaylistSheet) {
                NewPlaylistSheet(isShowing: $isShowingNewPlaylistSheet, playlists: $playlists, selectedPlaylist: $selectedPlaylist)
            }
        }
    }
}
