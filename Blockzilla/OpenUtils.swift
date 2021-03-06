/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Telemetry

class OpenUtils {
    private static let app = UIApplication.shared

    private static var canOpenInFirefox: Bool {
        return app.canOpenURL(URL(string: "firefox://")!)
    }

    private static var canOpenInChrome: Bool {
        return app.canOpenURL(URL(string: "googlechrome://")!)
    }

    static func openInFirefox(url: URL) {
        guard let escaped = url.absoluteString.addingPercentEncoding(withAllowedCharacters: .urlQueryParameterAllowed),
              let firefoxURL = URL(string: "firefox://open-url?url=\(escaped)&private=true"),
              app.canOpenURL(firefoxURL) else {
            return
        }

        Telemetry.default.recordEvent(category: TelemetryEventCategory.action, method: TelemetryEventMethod.open, object: TelemetryEventObject.menu, value: "firefox")
        app.openURL(firefoxURL)
    }

    static func openInChrome(url: URL) {
        // Code pulled from https://github.com/GoogleChrome/OpenInChrome
        // Replace the URL Scheme with the Chrome equivalent.
        var chromeScheme: String?
        if (url.scheme == "http") {
            chromeScheme = "googlechrome"
        } else if (url.scheme == "https") {
            chromeScheme = "googlechromes"
        }

        // Proceed only if a valid Google Chrome URI Scheme is available.
        guard let scheme = chromeScheme,
              let rangeForScheme = url.absoluteString.range(of: ":"),
              let chromeURL = URL(string: scheme + url.absoluteString.substring(from: rangeForScheme.lowerBound)) else { return }

        // Open the URL with Chrome.
        app.openURL(chromeURL)
    }

    static func openFirefoxInstall() {
        Telemetry.default.recordEvent(category: TelemetryEventCategory.action, method: TelemetryEventMethod.openAppStore, object: TelemetryEventObject.menu, value: "firefox")
        UIApplication.shared.openURL(AppInfo.config.firefoxAppStoreURL)
    }

    static func openInSafari(url: URL) {
        Telemetry.default.recordEvent(category: TelemetryEventCategory.action, method: TelemetryEventMethod.open, object: TelemetryEventObject.menu, value: "default")
        app.openURL(url)
    }

    static func buildShareViewController(url: URL, anchor: UIView) -> UIActivityViewController {
        var activities = [UIActivity]()

        if canOpenInFirefox {
            activities.append(OpenInFirefoxActivity(url: url))
        }

        if canOpenInChrome {
            activities.append(OpenInChromeActivity(url: url))
        }

        activities.append(OpenInSafariActivity(url: url))

        let shareController = UIActivityViewController(activityItems: [url], applicationActivities: activities)

        shareController.popoverPresentationController?.sourceView = anchor
        shareController.popoverPresentationController?.sourceRect = anchor.bounds
        shareController.popoverPresentationController?.permittedArrowDirections = .up
        
        return shareController
    }
}
