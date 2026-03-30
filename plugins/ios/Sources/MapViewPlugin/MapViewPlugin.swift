import SwiftGodot
import WebKit
import UIKit

@Godot
class MapViewPlugin: Object {

    // MARK: - Signals

    #signal("mapReady")
    #signal("errorOccurred", arguments: ["message": String.self])

    // MARK: - Properties

    @Export var isVisible: Bool = false

    private var webView: WKWebView?

    // MARK: - Lifecycle

    required init(_ context: InitContext) {
        super.init(context)
    }

    // MARK: - WebView Management

    @Callable
    func initialize(x: Double, y: Double, width: Double, height: Double) {
        DispatchQueue.main.async { [weak self] in
            self?.createWebView(
                frame: CGRect(x: x, y: y, width: width, height: height)
            )
        }
    }

    @Callable
    func show() {
        DispatchQueue.main.async { [weak self] in
            self?.webView?.isHidden = false
            self?.isVisible = true
        }
    }

    @Callable
    func hide() {
        DispatchQueue.main.async { [weak self] in
            self?.webView?.isHidden = true
            self?.isVisible = false
        }
    }

    @Callable
    func destroy() {
        DispatchQueue.main.async { [weak self] in
            self?.webView?.removeFromSuperview()
            self?.webView = nil
            self?.isVisible = false
        }
    }

    // MARK: - Map Operations

    @Callable
    func showMap(latitude: Double, longitude: Double, zoom: Int) {
        let html = Self.generateMapHTML(latitude: latitude, longitude: longitude, zoom: zoom)
        DispatchQueue.main.async { [weak self] in
            self?.webView?.loadHTMLString(html, baseURL: nil)
        }
    }

    @Callable
    func updateMarker(latitude: Double, longitude: Double) {
        let js = "updateMarker(\(latitude), \(longitude));"
        DispatchQueue.main.async { [weak self] in
            self?.webView?.evaluateJavaScript(js, completionHandler: nil)
        }
    }

    @Callable
    func drawRoute(pointsJSON: String) {
        let js = "drawRoute(\(pointsJSON));"
        DispatchQueue.main.async { [weak self] in
            self?.webView?.evaluateJavaScript(js, completionHandler: nil)
        }
    }

    @Callable
    func clearRoute() {
        let js = "clearRoute();"
        DispatchQueue.main.async { [weak self] in
            self?.webView?.evaluateJavaScript(js, completionHandler: nil)
        }
    }

    @Callable
    func setCenter(latitude: Double, longitude: Double) {
        let js = "setCenter(\(latitude), \(longitude));"
        DispatchQueue.main.async { [weak self] in
            self?.webView?.evaluateJavaScript(js, completionHandler: nil)
        }
    }

    // MARK: - Private

    private func createWebView(frame: CGRect) {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true

        webView = WKWebView(frame: frame, configuration: config)
        webView?.isOpaque = false
        webView?.backgroundColor = .clear
        webView?.scrollView.isScrollEnabled = false

        guard let rootView = Self.getRootView() else {
            emit(signal: MapViewPlugin.errorOccurred, "Could not find root view")
            return
        }

        rootView.addSubview(webView!)
        isVisible = true
        emit(signal: MapViewPlugin.mapReady)
    }

    private static func getRootView() -> UIView? {
        return UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }?
            .rootViewController?.view
    }

    // MARK: - Map HTML Template (OpenStreetMap + Leaflet)

    private static func generateMapHTML(latitude: Double, longitude: Double, zoom: Int) -> String {
        return """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=no">
            <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" />
            <script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>
            <style>
                * { margin: 0; padding: 0; }
                #map { width: 100vw; height: 100vh; }
            </style>
        </head>
        <body>
            <div id="map"></div>
            <script>
                var map = L.map('map').setView([\(latitude), \(longitude)], \(zoom));

                L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
                    attribution: '&copy; OpenStreetMap contributors',
                    maxZoom: 19
                }).addTo(map);

                var marker = L.marker([\(latitude), \(longitude)]).addTo(map);
                var routeLine = null;

                function updateMarker(lat, lng) {
                    marker.setLatLng([lat, lng]);
                }

                function setCenter(lat, lng) {
                    map.setView([lat, lng]);
                }

                function drawRoute(points) {
                    clearRoute();
                    var latlngs = points.map(function(p) { return [p[0], p[1]]; });
                    routeLine = L.polyline(latlngs, {
                        color: '#3388ff',
                        weight: 4,
                        opacity: 0.8
                    }).addTo(map);
                    if (latlngs.length > 0) {
                        map.fitBounds(routeLine.getBounds(), { padding: [20, 20] });
                    }
                }

                function clearRoute() {
                    if (routeLine) {
                        map.removeLayer(routeLine);
                        routeLine = null;
                    }
                }
            </script>
        </body>
        </html>
        """
    }
}
