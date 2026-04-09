import SwiftUI

struct UpdatesView: View {
    var body: some View {
        ContentUnavailableView(
            "No updates yet",
            systemImage: "bell",
            description: Text("When Home Mart launches, notifications will appear here.")
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Updates")
        .navigationBarTitleDisplayMode(.inline)
    }
}

