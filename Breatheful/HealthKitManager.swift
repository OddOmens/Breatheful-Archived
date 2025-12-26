import Foundation
import HealthKit

class HealthKitManager: ObservableObject {
    static let shared = HealthKitManager()
    
    private let healthStore = HKHealthStore()
    @Published var isAuthorized = false
    
    private init() {
        checkAuthorizationStatus()
    }
    
    var isHealthKitAvailable: Bool {
        return HKHealthStore.isHealthDataAvailable()
    }
    
    func requestAuthorization() {
        guard isHealthKitAvailable else {
            print("HealthKit is not available on this device")
            return
        }
        
        guard let mindfulSessionType = HKObjectType.categoryType(forIdentifier: .mindfulSession) else {
            print("Failed to create mindful session type")
            return
        }
        
        let typesToWrite: Set<HKSampleType> = [mindfulSessionType]
        
        healthStore.requestAuthorization(toShare: typesToWrite, read: nil) { [weak self] success, error in
            DispatchQueue.main.async {
                if success {
                    self?.isAuthorized = true
                    print("HealthKit authorization granted")
                } else {
                    self?.isAuthorized = false
                    if let error = error {
                        print("HealthKit authorization failed: \(error.localizedDescription)")
                    } else {
                        print("HealthKit authorization failed: Unknown error")
                    }
                }
            }
        }
    }
    
    private func checkAuthorizationStatus() {
        guard isHealthKitAvailable else { return }
        
        guard let mindfulSessionType = HKObjectType.categoryType(forIdentifier: .mindfulSession) else {
            print("Failed to create mindful session type for status check")
            return
        }
        
        let status = healthStore.authorizationStatus(for: mindfulSessionType)
        
        DispatchQueue.main.async {
            self.isAuthorized = (status == .sharingAuthorized)
        }
    }
    
    func saveMindfulSession(startDate: Date, endDate: Date, completion: @escaping (Bool, Error?) -> Void) {
        guard isAuthorized else {
            completion(false, NSError(domain: "HealthKit", code: -1, userInfo: [NSLocalizedDescriptionKey: "HealthKit not authorized"]))
            return
        }
        
        guard let mindfulSessionType = HKObjectType.categoryType(forIdentifier: .mindfulSession) else {
            completion(false, NSError(domain: "HealthKit", code: -2, userInfo: [NSLocalizedDescriptionKey: "Failed to create mindful session type"]))
            return
        }
        
        let mindfulSession = HKCategorySample(
            type: mindfulSessionType,
            value: HKCategoryValue.notApplicable.rawValue,
            start: startDate,
            end: endDate
        )
        
        healthStore.save(mindfulSession) { success, error in
            DispatchQueue.main.async {
                completion(success, error)
                if success {
                    print("Mindful session saved to HealthKit: \(startDate) to \(endDate)")
                } else if let error = error {
                    print("Failed to save mindful session to HealthKit: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func saveMindfulSessionForDuration(duration: TimeInterval, endDate: Date = Date(), completion: @escaping (Bool, Error?) -> Void) {
        let startDate = endDate.addingTimeInterval(-duration)
        saveMindfulSession(startDate: startDate, endDate: endDate, completion: completion)
    }
    
    func saveHistoricalMindfulSessions(from dailyUsageMinutes: [Date: Int], completion: @escaping (Int, [Error]) -> Void) {
        guard isAuthorized else {
            completion(0, [NSError(domain: "HealthKit", code: -1, userInfo: [NSLocalizedDescriptionKey: "HealthKit not authorized"])])
            return
        }
        
        var savedCount = 0
        var errors: [Error] = []
        let group = DispatchGroup()
        
        for (date, minutes) in dailyUsageMinutes {
            guard minutes > 0 else { continue }
            
            group.enter()
            let startDate = date
            let endDate = date.addingTimeInterval(TimeInterval(minutes * 60))
            
            saveMindfulSession(startDate: startDate, endDate: endDate) { success, error in
                if success {
                    savedCount += 1
                } else if let error = error {
                    errors.append(error)
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            completion(savedCount, errors)
        }
    }
}