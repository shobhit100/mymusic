import SwiftUI

struct PlaylistTabsView: View {
    @Binding var playlists: [Playlist]
    @Binding var selectedPlaylist: Playlist?
    @State private var newPlaylistName: String = ""
    @State private var isShowingNewPlaylistAlert: Bool = false

    var body: some View {
        HStack {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(playlists) { playlist in
                        Button(action: {
                            selectedPlaylist = playlist
                        }) {
                            Text(playlist.name)
                                .padding(.vertical, 10)
                                .padding(.horizontal, 15)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(selectedPlaylist?.id == playlist.id ? Color.blue : Color.gray.opacity(0.3))
                                        .shadow(color: selectedPlaylist?.id == playlist.id ? Color.black.opacity(0.2) : Color.clear, radius: 4, x: 0, y: 2)
                                )
                                .foregroundColor(selectedPlaylist?.id == playlist.id ? .white : .black)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(selectedPlaylist?.id == playlist.id ? Color.blue : Color.clear, lineWidth: 1)
                                )
                        }
                    }
                }
                .padding(.horizontal)
            }
            Button(action: {
                isShowingNewPlaylistAlert = true
            }) {
                Image(systemName: "plus")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .clipShape(Circle())
            }
            .padding(.trailing)
            .alert(isPresented: $isShowingNewPlaylistAlert) {
                Alert(
                    title: Text("New Playlist"),
                    message: Text("Enter the name of the new playlist:"),
                    primaryButton: .default(Text("Add"), action: {
                        addNewPlaylist()
                    }),
                    secondaryButton: .cancel()
                )
            }
        }
    }
    
    private func addNewPlaylist() {
        if !newPlaylistName.isEmpty {
            let newPlaylist = Playlist(name: newPlaylistName)
            playlists.append(newPlaylist)
            selectedPlaylist = newPlaylist
            newPlaylistName = ""
        }
    }
}
