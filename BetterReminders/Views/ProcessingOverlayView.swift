import SwiftUI
import SwiftData

struct ProcessingOverlayView: View {
    let status: JobStatus?
    let error: String?

    var body: some View {
        VStack(spacing: 12) {
            if let status {
                ProgressView()
                Text(statusMessage(for: status))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            if let error {
                Label(error, systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }

    private func statusMessage(for status: JobStatus) -> String {
        switch status {
        case .pending: return "Preparing…"
        case .transcribing: return "Transcribing voice memo…"
        case .parsing: return "Creating reminders…"
        case .done: return "Done!"
        case .failed: return "Processing failed"
        }
    }
}

#Preview {
    ProcessingOverlayView(status: .transcribing, error: nil)
}
