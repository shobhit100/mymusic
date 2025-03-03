import SwiftUI

struct NewPlaylistSheet: View {
    @Binding var isShowing: Bool
    @Binding var playlists: [Playlist]
    @Binding var selectedPlaylist: Playlist?
    @State private var newPlaylistName: String = ""

    var body: some View {
        VStack {
            Text("New Playlist")
                .font(.headline)
                .padding()
            TextField("Playlist Name", text: $newPlaylistName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            HStack {
                Button("Cancel") {
                    isShowing = false
                }
                .padding()
                Spacer()
                Button("Add") {
                    addNewPlaylist()
                    isShowing = false
                }
                .padding()
            }
        }
        .padding()
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
