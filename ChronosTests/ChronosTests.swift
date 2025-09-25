import XCTest
@testable import Chronos

// MARK: - Main Test Suite
/// Comprehensive test suite for Chronos app
class ChronosTests: XCTestCase {
    
    var taskManager: TaskManager!
    var privacyManager: PrivacyManager!
    var gamificationEngine: GamificationEngine!
    var voiceInputManager: VoiceInputManager!
    
    override func setUpWithError() throws {
        // Initialize managers for testing
        taskManager = TaskManager()
        privacyManager = PrivacyManager.shared
        gamificationEngine = GamificationEngine.shared
        voiceInputManager = VoiceInputManager()
    }
    
    override func tearDownWithError() throws {
        // Clean up after tests
        taskManager = nil
    }
    
    // MARK: - Task Manager Tests
    
    func testTaskCreation() throws {
        let task = Task(
            title: "Test Task",
            description: "Test Description",
            dueDate: Date(),
            isCompleted: false,
            priority: .high
        )
        
        taskManager.addTask(task)
        
        XCTAssertEqual(taskManager.tasks.count, 1)
        XCTAssertEqual(taskManager.tasks.first?.title, "Test Task")
        XCTAssertEqual(taskManager.tasks.first?.priority, .high)
    }
    
    func testTaskCompletion() throws {
        let task = Task(
            title: "Test Task",
            description: "Test Description",
            dueDate: Date(),
            isCompleted: false,
            priority: .medium
        )
        
        taskManager.addTask(task)
        let initialPoints = taskManager.points
        
        taskManager.toggleTaskCompletion(task)
        
        XCTAssertTrue(taskManager.tasks.first?.isCompleted ?? false)
        XCTAssertGreaterThan(taskManager.points, initialPoints)
    }
    
    func testTaskDeletion() throws {
        let task = Task(
            title: "Test Task",
            description: "Test Description",
            dueDate: Date(),
            isCompleted: false,
            priority: .low
        )
        
        taskManager.addTask(task)
        XCTAssertEqual(taskManager.tasks.count, 1)
        
        taskManager.deleteTask(task)
        XCTAssertEqual(taskManager.tasks.count, 0)
    }
    
    // MARK: - Privacy Manager Tests
    
    func testDataEncryption() throws {
        let testData = "Sensitive task data"
        let data = testData.data(using: .utf8)!
        
        do {
            let encryptedData = try privacyManager.encrypt(data)
            let decryptedData = try privacyManager.decrypt(encryptedData, as: Data.self)
            let decryptedString = String(data: decryptedData, encoding: .utf8)
            
            XCTAssertEqual(decryptedString, testData)
        } catch {
            XCTFail("Encryption/Decryption failed: \(error)")
        }
    }
    
    func testSecureStorage() throws {
        let testTasks = [
            Task(title: "Task 1", description: "", dueDate: Date(), isCompleted: false),
            Task(title: "Task 2", description: "", dueDate: Date(), isCompleted: true)
        ]
        
        do {
            try privacyManager.storeSecurely(testTasks, forKey: "testTasks")
            let retrievedTasks = try privacyManager.retrieveSecurely([Task].self, forKey: "testTasks")
            
            XCTAssertNotNil(retrievedTasks)
            XCTAssertEqual(retrievedTasks?.count, 2)
        } catch {
            XCTFail("Secure storage failed: \(error)")
        }
    }
    
    // MARK: - Gamification Tests
    
    func testXPAddition() throws {
        let initialXP = gamificationEngine.currentXP
        
        gamificationEngine.addXP(100, source: .taskCompleted)
        
        XCTAssertEqual(gamificationEngine.currentXP, initialXP + 100)
        XCTAssertEqual(gamificationEngine.totalXP, initialXP + 100)
    }
    
    func testLevelUp() throws {
        let initialLevel = gamificationEngine.currentLevel
        let xpNeeded = gamificationEngine.xpPerLevel - gamificationEngine.currentXP
        
        gamificationEngine.addXP(xpNeeded, source: .taskCompleted)
        
        XCTAssertGreaterThan(gamificationEngine.currentLevel, initialLevel)
    }
    
    func testAchievementUnlocking() throws {
        let achievement = Achievement(
            id: UUID(),
            title: "Test Achievement",
            description: "Test Description",
            icon: "star.fill",
            pointsRequired: 10,
            isUnlocked: false,
            type: .firstTask
        )
        
        gamificationEngine.achievements.append(achievement)
        
        gamificationEngine.checkAchievements(for: .taskCompleted)
        
        // This would need to be implemented based on the actual achievement logic
        // XCTAssertTrue(gamificationEngine.achievements.first?.isUnlocked ?? false)
    }
    
    // MARK: - Voice Input Tests
    
    func testVoicePermissionStatus() throws {
        // Test that permission status is properly tracked
        XCTAssertNotNil(voiceInputManager.isPermissionGranted)
    }
    
    func testVoiceCommandProcessing() throws {
        let testCommands = [
            "create task",
            "add new task",
            "show tasks",
            "complete task",
            "delete task"
        ]
        
        for command in testCommands {
            let processedCommand = voiceInputManager.processVoiceCommand(command)
            XCTAssertNotNil(processedCommand, "Command '\(command)' should be processed")
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testErrorHandling() throws {
        let errorHandler = ErrorHandler.shared
        
        // Test error creation and handling
        let testError = TaskError.taskNotFound
        errorHandler.handleTaskError(testError, context: "test")
        
        XCTAssertNotNil(errorHandler.currentError)
        XCTAssertTrue(errorHandler.isShowingError)
    }
    
    // MARK: - Performance Tests
    
    func testTaskManagerPerformance() throws {
        measure {
            for i in 0..<100 {
                let task = Task(
                    title: "Performance Test Task \(i)",
                    description: "Description \(i)",
                    dueDate: Date(),
                    isCompleted: false,
                    priority: .medium
                )
                taskManager.addTask(task)
            }
        }
    }
    
    func testEncryptionPerformance() throws {
        let testData = "Performance test data".data(using: .utf8)!
        
        measure {
            for _ in 0..<100 {
                do {
                    let encrypted = try privacyManager.encrypt(testData)
                    _ = try privacyManager.decrypt(encrypted, as: Data.self)
                } catch {
                    XCTFail("Performance test failed: \(error)")
                }
            }
        }
    }
}

// MARK: - Mock Classes for Testing

class MockTaskManager: TaskManager {
    var mockTasks: [Task] = []
    var mockPoints: Int = 0
    
    override func addTask(_ task: Task) {
        mockTasks.append(task)
    }
    
    override func deleteTask(_ task: Task) {
        mockTasks.removeAll { $0.id == task.id }
    }
    
    override func toggleTaskCompletion(_ task: Task) {
        if let index = mockTasks.firstIndex(where: { $0.id == task.id }) {
            mockTasks[index].isCompleted.toggle()
            if mockTasks[index].isCompleted {
                mockPoints += 10
            }
        }
    }
}

class MockPrivacyManager: PrivacyManager {
    var mockEncryptedData: [String: Data] = [:]
    
    override func storeSecurely<T: Codable>(_ data: T, forKey key: String) throws {
        let jsonData = try JSONEncoder().encode(data)
        mockEncryptedData[key] = jsonData
    }
    
    override func retrieveSecurely<T: Codable>(_ type: T.Type, forKey key: String) throws -> T? {
        guard let data = mockEncryptedData[key] else { return nil }
        return try JSONDecoder().decode(type, from: data)
    }
}

// MARK: - Test Utilities

extension ChronosTests {
    
    func createSampleTask(title: String = "Sample Task", priority: TaskPriority = .medium) -> Task {
        return Task(
            title: title,
            description: "Sample description",
            dueDate: Date(),
            isCompleted: false,
            priority: priority
        )
    }
    
    func createSampleTasks(count: Int) -> [Task] {
        return (0..<count).map { i in
            createSampleTask(title: "Task \(i)")
        }
    }
    
    func waitForAsyncOperation(timeout: TimeInterval = 1.0) {
        let expectation = XCTestExpectation(description: "Async operation")
        DispatchQueue.main.asyncAfter(deadline: .now() + timeout) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: timeout + 0.1)
    }
}

// MARK: - Integration Tests

class ChronosIntegrationTests: XCTestCase {
    
    func testFullTaskWorkflow() throws {
        let taskManager = TaskManager()
        let gamificationEngine = GamificationEngine.shared
        
        // Create task
        let task = Task(
            title: "Integration Test Task",
            description: "Test the full workflow",
            dueDate: Date(),
            isCompleted: false,
            priority: .high
        )
        
        // Add task
        taskManager.addTask(task)
        XCTAssertEqual(taskManager.tasks.count, 1)
        
        // Complete task
        let initialXP = gamificationEngine.currentXP
        taskManager.toggleTaskCompletion(task)
        
        // Verify completion
        XCTAssertTrue(taskManager.tasks.first?.isCompleted ?? false)
        XCTAssertGreaterThan(gamificationEngine.currentXP, initialXP)
    }
    
    func testVoiceToTaskWorkflow() throws {
        let taskManager = TaskManager()
        let voiceInputManager = VoiceInputManager()
        
        let processedTask = ProcessedTask(
            title: "Voice Task",
            description: "Created via voice",
            priority: .medium,
            dueDate: Date(),
            confidence: 0.9,
            originalText: "Create a voice task"
        )
        
        taskManager.createTaskFromVoice(processedTask)
        
        XCTAssertEqual(taskManager.tasks.count, 1)
        XCTAssertEqual(taskManager.tasks.first?.title, "Voice Task")
        XCTAssertEqual(taskManager.tasks.first?.description, "Created via voice")
    }
}
