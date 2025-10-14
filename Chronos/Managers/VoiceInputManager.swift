import Foundation
import AVFoundation
import Speech
import Combine

class VoiceInputManager: NSObject, ObservableObject {
    @Published var isRecording = false

    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private let audioSession = AVAudioSession.sharedInstance()

    override init() {
        super.init()
        requestPermissions()
    }

    // Ask for permission when initialized
    private func requestPermissions() {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            switch authStatus {
            case .authorized:
                print("✅ Speech recognition authorized")
            default:
                print("❌ Speech recognition not authorized")
            }
        }

        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Audio session setup failed: \(error)")
        }
    }

    // MARK: - Start Recording and Transcribe
    func transcribeSpeechToText(completion: @escaping (String) -> Void) {
        // Ensure no old tasks running
        recognitionTask?.cancel()
        recognitionTask = nil

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            print("Unable to create recognition request")
            return
        }

        let inputNode = audioEngine.inputNode
        recognitionRequest.shouldReportPartialResults = true

        isRecording = true

        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { result, error in
            var isFinal = false

            if let result = result {
                completion(result.bestTranscription.formattedString)
                isFinal = result.isFinal
            }

            if error != nil || isFinal {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                self.recognitionRequest = nil
                self.recognitionTask = nil
                self.isRecording = false
            }
        }

        // Configure microphone input
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            self.recognitionRequest?.append(buffer)
        }

        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            print("Audio Engine start error: \(error)")
        }

        print("🎙️ Started recording...")
    }

    // MARK: - Stop Recording
    func stopRecording(completion: @escaping (String) -> Void) {
        guard isRecording else { return }
        audioEngine.stop()
        recognitionRequest?.endAudio()
        isRecording = false

        // Wait briefly for the recognizer to finalize
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            completion("Voice input completed.")
        }
        print("🛑 Stopped recording.")
    }
}
