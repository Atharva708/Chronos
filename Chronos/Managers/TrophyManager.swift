import SwiftUI

class TrophyManager: ObservableObject {
    static let shared = TrophyManager()
    
    @Published var trophies: Int {
        didSet {
            UserDefaults.standard.set(trophies, forKey: "userTrophies")
        }
    }
    
    private init() {
        self.trophies = UserDefaults.standard.integer(forKey: "userTrophies")
    }
    
    func addTrophies(_ amount: Int) {
        trophies += amount
    }
    
    func deductTrophies(_ amount: Int) {
        trophies = max(0, trophies - amount)
    }
} 