import SwiftUI

struct SearchBar: View {
    @Binding var searchText: String
    @FocusState var isSearchFocused: Bool
    @Binding var areControlsVisible: Bool

    var body: some View {
        HStack {
            TextField("Search", text: $searchText)
                .padding(7)
                .padding(.horizontal, 25)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .overlay(
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                            .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                            .padding(.leading, 8)
                        
                        if !searchText.isEmpty {
                            Button(action: {
                                self.searchText = ""
                                self.isSearchFocused = false
                                self.areControlsVisible = true
                            }) {
                                Image(systemName: "multiply.circle.fill")
                                    .foregroundColor(.gray)
                                    .padding(.trailing, 8)
                            }
                        }
                    }
                )
                .padding(.horizontal, 10)
                .onTapGesture {
                    self.isSearchFocused = true
                }
                .focused($isSearchFocused)
                .onChange(of: searchText) { _ in
                    self.areControlsVisible = searchText.isEmpty
                }
        }
        .padding(.top, 10)  // Add padding to avoid overlap with playlist names
    }
}
