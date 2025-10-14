import AppIntents

struct AddTaskInChronos: AppIntent {
    static var title: LocalizedStringResource = "Add Task in Chronos"
    static var description: IntentDescription = "Quickly add a task using Siri."
    
    @Parameter(title: "Title")
    var titleText: String
    
    @Parameter(title: "Notes", default: nil)
    var notes: String?
    
    @Parameter(title: "Due Date", default: nil)
    var due: Date?
    
    @Parameter(title: "Priority", default: nil)
    var priority: String?  // simple string for now
    
    static var openAppWhenRun: Bool { true }
    
    static var suggestedInvocationPhrase: String? = "Add task in Chronos"
    
    static var parameterSummary: some ParameterSummary {
        Summary("Add \(\.$titleText)")
    }
    
    func perform() async throws -> some IntentResult {
        // Integration with TaskManager to add the task should be implemented here,
        // e.g., via shared app group store, URL deep link, or other mechanisms.
        
        return .result(dialog: "I'll open Chronos to add ‘\(titleText)’." )
    }
    
    static var appShortcuts: [AppShortcut] {
        [
            AppShortcut(
                intent: AddTaskInChronos(),
                phrases: [
                    "Add task in Chronos",
                    "New task in Chronos"
                ]
            )
        ]
    }
}
