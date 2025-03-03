import SwiftUI
import MobileCoreServices
import UniformTypeIdentifiers

struct DocumentPicker: UIViewControllerRepresentable {
    @Binding var songs: [URL]
    @Binding var duplicateSongs: [String] // Alert binding for duplicate songs
    @Binding var playlists: [Playlist] // Binding for playlists

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.audio], asCopy: true)
        documentPicker.allowsMultipleSelection = true // Allow multiple selections
        documentPicker.delegate = context.coordinator
        return documentPicker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        var parent: DocumentPicker

        init(_ parent: DocumentPicker) {
            self.parent = parent
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            var duplicateFound = false
            for url in urls {
                if parent.songs.contains(url) {
                    duplicateFound = true
                    parent.duplicateSongs.append(url.lastPathComponent)
                } else {
                    parent.songs.append(url)
                    if let index = parent.playlists.firstIndex(where: { $0.name == "All" }) {
                        parent.playlists[index].songs.append(url)
                    }
                }
            }
            if duplicateFound {
                parent.duplicateSongs = Array(Set(parent.duplicateSongs)) // Remove duplicates in alert
            }
        }
    }
}
