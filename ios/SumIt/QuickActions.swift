import UIKit

/// Home Screen long-press shortcuts: Scan with camera / Paste text.
enum QuickAction {
    static let scan = "com.stellargalaxylabs.sumit.scan"
    static let paste = "com.stellargalaxylabs.sumit.paste"
    static let file = "com.stellargalaxylabs.sumit.file"
    static let history = "com.stellargalaxylabs.sumit.history"
    static let didFire = Notification.Name("SumItQuickAction")
    static var pending: String?

    static func install() {
        UIApplication.shared.shortcutItems = [
            UIApplicationShortcutItem(type: scan, localizedTitle: "Scan with camera",
                                      localizedSubtitle: "Sum up printed text",
                                      icon: UIApplicationShortcutIcon(systemImageName: "camera.viewfinder")),
            UIApplicationShortcutItem(type: file, localizedTitle: "Add file",
                                      localizedSubtitle: "PDF, text or image",
                                      icon: UIApplicationShortcutIcon(systemImageName: "doc.badge.plus")),
            UIApplicationShortcutItem(type: history, localizedTitle: "History & progress",
                                      localizedSubtitle: "Past summaries and streak",
                                      icon: UIApplicationShortcutIcon(systemImageName: "chart.bar.fill")),
            UIApplicationShortcutItem(type: paste, localizedTitle: "Sum clipboard",
                                      localizedSubtitle: "Paste & summarize",
                                      icon: UIApplicationShortcutIcon(systemImageName: "doc.on.clipboard")),
        ]
    }
}

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions o: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        QuickAction.install()
        return true
    }

    func application(_ application: UIApplication, configurationForConnecting session: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        if let item = options.shortcutItem { QuickAction.pending = item.type }
        let config = UISceneConfiguration(name: nil, sessionRole: session.role)
        config.delegateClass = SceneDelegate.self
        return config
    }
}

final class SceneDelegate: NSObject, UIWindowSceneDelegate {
    func windowScene(_ windowScene: UIWindowScene, performActionFor item: UIApplicationShortcutItem,
                     completionHandler: @escaping (Bool) -> Void) {
        NotificationCenter.default.post(name: QuickAction.didFire, object: item.type)
        completionHandler(true)
    }
}
