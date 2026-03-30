import SwiftGodot
import CoreLocation

@Godot
class LocationPlugin: Object {

    // MARK: - Signals

    #signal("locationUpdated", arguments: ["latitude": Double.self, "longitude": Double.self, "accuracy": Double.self])
    #signal("authorizationChanged", arguments: ["status": String.self])
    #signal("errorOccurred", arguments: ["message": String.self])

    // MARK: - Properties

    @Export var isAuthorized: Bool = false
    @Export var isTracking: Bool = false
    @Export var latitude: Double = 0.0
    @Export var longitude: Double = 0.0
    @Export var accuracy: Double = 0.0

    private let locationManager = CLLocationManager()
    private var locationDelegate: LocationDelegate?

    // MARK: - Lifecycle

    required init(_ context: InitContext) {
        super.init(context)
        setupLocationManager()
    }

    private func setupLocationManager() {
        locationDelegate = LocationDelegate(plugin: self)
        locationManager.delegate = locationDelegate
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
}

// MARK: - CLLocationManagerDelegate (NSObject ベースのヘルパー)
// SwiftGodot の Object は NSObject ではないため、delegate を別クラスに分離

private class LocationDelegate: NSObject, CLLocationManagerDelegate {
    weak var plugin: LocationPlugin?

    init(plugin: LocationPlugin) {
        self.plugin = plugin
        super.init()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let plugin, let location = locations.last else { return }
        plugin.latitude = location.coordinate.latitude
        plugin.longitude = location.coordinate.longitude
        plugin.accuracy = location.horizontalAccuracy
        plugin.emit(signal: LocationPlugin.locationUpdated, plugin.latitude, plugin.longitude, plugin.accuracy)
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        guard let plugin else { return }
        let status: String
        switch manager.authorizationStatus {
        case .authorizedWhenInUse:
            plugin.isAuthorized = true
            status = "authorized_when_in_use"
        case .authorizedAlways:
            plugin.isAuthorized = true
            status = "authorized_always"
        case .denied:
            plugin.isAuthorized = false
            status = "denied"
        case .restricted:
            plugin.isAuthorized = false
            status = "restricted"
        case .notDetermined:
            plugin.isAuthorized = false
            status = "not_determined"
        @unknown default:
            plugin.isAuthorized = false
            status = "unknown"
        }
        plugin.emit(signal: LocationPlugin.authorizationChanged, status)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        plugin?.emit(signal: LocationPlugin.errorOccurred, error.localizedDescription)
    }
}
