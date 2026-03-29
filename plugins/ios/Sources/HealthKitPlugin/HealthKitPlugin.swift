import SwiftGodot
import HealthKit

@Godot
class HealthKitPlugin: Object {

    // MARK: - Signals

    #signal(authorizationChanged, arguments: ["authorized": Bool.self])
    #signal(stepsUpdated, arguments: ["steps": Int.self])
    #signal(distanceUpdated, arguments: ["distance_m": Double.self])
    #signal(errorOccurred, arguments: ["message": String.self])

    // MARK: - Properties

    @Export var isAvailable: Bool = false
    @Export var isAuthorized: Bool = false

    private let healthStore = HKHealthStore()

    private let stepCountType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
    private let distanceType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!

    // MARK: - Lifecycle

    required init() {
        super.init()
        isAvailable = HKHealthStore.isHealthDataAvailable()
    }

    required init(nativeHandle: UnsafeRawPointer) {
        super.init(nativeHandle: nativeHandle)
        isAvailable = HKHealthStore.isHealthDataAvailable()
    }

    // MARK: - Authorization

    @Callable
    func requestPermission() {
        guard isAvailable else {
            emit(signal: HealthKitPlugin.errorOccurred, "HealthKit is not available on this device")
            return
        }

        let readTypes: Set<HKObjectType> = [stepCountType, distanceType]

        healthStore.requestAuthorization(toShare: nil, read: readTypes) { [weak self] success, error in
            guard let self else { return }
            DispatchQueue.main.async {
                self.isAuthorized = success
                self.emit(signal: HealthKitPlugin.authorizationChanged, success)
                if let error {
                    self.emit(signal: HealthKitPlugin.errorOccurred, error.localizedDescription)
                }
            }
        }
    }

    // MARK: - Steps

    @Callable
    func getSteps() -> Int {
        // 同期的に返せないので、非同期で取得してシグナルで通知
        fetchTodaySteps()
        return 0
    }

    @Callable
    func fetchTodaySteps() {
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        fetchSteps(from: startOfDay, to: now)
    }

    @Callable
    func fetchStepsForDays(days: Int) {
        let now = Date()
        guard let startDate = Calendar.current.date(byAdding: .day, value: -days, to: now) else {
            return
        }
        fetchSteps(from: startDate, to: now)
    }

    private func fetchSteps(from startDate: Date, to endDate: Date) {
        let predicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: endDate,
            options: .strictStartDate
        )

        let query = HKStatisticsQuery(
            quantityType: stepCountType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum
        ) { [weak self] _, statistics, error in
            guard let self else { return }
            DispatchQueue.main.async {
                if let error {
                    self.emit(signal: HealthKitPlugin.errorOccurred, error.localizedDescription)
                    return
                }
                let steps = Int(statistics?.sumQuantity()?.doubleValue(for: .count()) ?? 0)
                self.emit(signal: HealthKitPlugin.stepsUpdated, steps)
            }
        }

        healthStore.execute(query)
    }

    // MARK: - Distance

    @Callable
    func getDistance() -> Double {
        fetchTodayDistance()
        return 0.0
    }

    @Callable
    func fetchTodayDistance() {
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        fetchDistance(from: startOfDay, to: now)
    }

    @Callable
    func fetchDistanceForDays(days: Int) {
        let now = Date()
        guard let startDate = Calendar.current.date(byAdding: .day, value: -days, to: now) else {
            return
        }
        fetchDistance(from: startDate, to: now)
    }

    private func fetchDistance(from startDate: Date, to endDate: Date) {
        let predicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: endDate,
            options: .strictStartDate
        )

        let query = HKStatisticsQuery(
            quantityType: distanceType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum
        ) { [weak self] _, statistics, error in
            guard let self else { return }
            DispatchQueue.main.async {
                if let error {
                    self.emit(signal: HealthKitPlugin.errorOccurred, error.localizedDescription)
                    return
                }
                let meters = statistics?.sumQuantity()?.doubleValue(for: .meter()) ?? 0.0
                self.emit(signal: HealthKitPlugin.distanceUpdated, meters)
            }
        }

        healthStore.execute(query)
    }

    // MARK: - Background Delivery

    @Callable
    func enableBackgroundDelivery() {
        healthStore.enableBackgroundDelivery(for: stepCountType, frequency: .hourly) { [weak self] success, error in
            if let error {
                self?.emit(signal: HealthKitPlugin.errorOccurred, "Background delivery failed: \(error.localizedDescription)")
            }
        }
    }
}
