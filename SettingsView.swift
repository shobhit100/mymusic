import SwiftUI

extension ContentView {
    struct SettingsView: View {
        @Binding var isDarkMode: Bool
        @Binding var isShuffleOn: Bool
        
        var body: some View {
            NavigationView {
                Form {
                    Section(header: Text("Appearance")) {
                        Toggle(isOn: $isDarkMode) {
                            HStack {
                                Image(systemName: "moon.fill")
                                    .foregroundColor(.blue)
                                Text("Dark Mode")
                            }
                        }
                    }
                    
                    Section(header: Text("Playback Settings")) {
                        Toggle(isOn: $isShuffleOn) {
                            HStack {
                                Image(systemName: "shuffle")
                                    .foregroundColor(.blue)
                                Text("Shuffle")
                            }
                        }
                    }
                }
                .navigationTitle("Settings")
            }
        }
    }
}
