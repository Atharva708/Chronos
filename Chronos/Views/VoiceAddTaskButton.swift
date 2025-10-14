import SwiftUI

public struct VoiceAddTaskButton: View {
    @ObservedObject private var voiceInputManager = VoiceInputManager()
    let gradientColors: [Color]
    let onTranscription: (String) -> Void
    let isFullWidth: Bool
    
    public init(
        gradientColors: [Color],
        isFullWidth: Bool = true,
        onTranscription: @escaping (String) -> Void
    ) {
        self.gradientColors = gradientColors
        self.isFullWidth = isFullWidth
        self.onTranscription = onTranscription
    }
    
    public var body: some View {
        Button {
            if voiceInputManager.isRecording {
                voiceInputManager.stopRecording { transcription in
                    onTranscription(transcription)
                }
            } else {
                voiceInputManager.transcribeSpeechToText { transcription in
                    onTranscription(transcription)
                }
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: voiceInputManager.isRecording ? "stop.circle.fill" : "mic.fill")
                    .font(.title2)
                Text(voiceInputManager.isRecording ? "Stop & Use" : "Add Task by Voice")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: isFullWidth ? .infinity : nil)
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(
                LinearGradient(
                    colors: gradientColors,
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(12)
            .foregroundStyle(.white)
        }
        .animation(.easeInOut, value: voiceInputManager.isRecording)
    }
}

struct VoiceAddTaskButton_Previews: PreviewProvider {
    static var previews: some View {
        VoiceAddTaskButton(gradientColors: [.blue, .purple]) { transcription in
            print("Transcription: \(transcription)")
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
