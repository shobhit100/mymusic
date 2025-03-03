import SwiftUI

struct SearchBar: View {
    @Binding var searchText: String
    @FocusState var isSearchFocused: Bool
    @Binding var areControlsVisible: Bool

    var body: some View {
        HStack {
            TextField("Search songs", text: $searchText)
                .padding(10)
                .background(Color(.systemGray6))
                .cornerRadius(isSearchFocused ? 16 : 8)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .focused($isSearchFocused)
                .onChange(of: isSearchFocused) { focused in
                    areControlsVisible = !focused
                }
            
            if isSearchFocused {
                Button(action: {
                    searchText = ""
                    isSearchFocused = false
                    areControlsVisible = true
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }) {
                    Text("Cancel")
                        .foregroundColor(.blue)
                }
                .padding(.trailing, 10)
                .transition(.move(edge: .trailing))
                .animation(.default, value: isSearchFocused)
            }
        }
        .padding(.horizontal)
        .animation(.easeInOut(duration: 0.3), value: isSearchFocused)
    }
}
