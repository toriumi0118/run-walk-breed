import SwiftGodot
import CoreLocation

@Godot
class LocationPlugin: Object, CLLocationManagerDelegate {

    // MARK: - Signals

    #signal(locationUpdated, arguments: ["latitude": Double.self, "longitude": Double.self, "accuracy": Double.self])
    #signal(authorizationChanged, arguments: ["status": String.self])
    #signal(errorOccurred, arguments: ["message": String.self])

    // MARK: - Properties

    @Export var isAuthorized: Bool = false
    @Export var isTracking: Bool = false
    @Export var latitude: Double = 0.0
    @Export var longitude: Double = 0.0
    @Export var accuracy: Double = 0.0

    private let locationManager = CLLocationManager()

    // MARK: - Lifecycle

    required init() {
        super.init()
        setupLocationManager()
    }

    required init(nativeHandle: UnsafeRawPointer) {
        super.init(nativeHandle: nativeHandle)
        setupLocationManager()
    }

    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 5.0  // 5m ごとに更新
        locationManager.allowsBackgroundLocationUpdates = false
        locationManager.pausesLocationUpdatesAutomatically = true
    }

    // MARK: - Permission

    @Callable
    func requestPermission() {
        locationManager.requestWhenInUseAuthorization()
    }

    @Callable
    func requestAlwaysPermission() {
        locationManager.requestAlwaysAuthorization()
    }

    // MARK: - Tracking

    @Callable
    func startTracking() {
        guard isAuthorized else {
            emit(signal: LocationPlugin.errorOccurred, "Location permission not granted")
            return
        }
        locationManager.startUpdatingLocation()
        isTracking = true
    }

    @Callable
    func stopTracking() {
        locationManager.stopUpdatingLocation()
        isTracking = false
    }

    @Callable
    func enableBackgroundTracking() {
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.showsBackgroundLocationIndicator = true
    }

    @Callable
    func setDistanceFilter(meters: Double) {
        locationManager.distanceFilter = meters
    }

    // MARK: - CLLocationManagerDelegate

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        latitude = location.coordinate.latitude
        longitude = location.coordinate.longitude
        accuracy = location.horizontalAccuracy
        emit(signal: LocationPlugin.locationUpdated, latitude, longitude, accuracy)
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status: String
        switch manager.authorizationStatus {
        case .authorizedWhenInUse:
            isAuthorized = true
            status = "authorized_when_in_use"
        case .authorizedAlways:
            isAuthorized = true
            status = "authorized_always"
        case .denied:
            isAuthorized = false
            status = "denied"
        case .restricted:
            isAuthorized = false
            status = "restricted"
        case .notDetermined:
            isAuthorized = false
            status = "not_determined"
        @unknown default:
            isAuthorized = false
            status = "unknown"
        }
        emit(signal: LocationPlugin.authorizationChanged, status)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        emit(signal: LocationPlugin.errorOccurred, error.localizedDescription)
    }
}
