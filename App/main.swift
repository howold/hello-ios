import UIKit

// 极简 iOS App：不依赖 storyboard / xib / Xcode 工程，
// 由 swiftc 直接编译成 arm64 iOS 可执行文件，供 CI 打包成 .ipa。

final class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        let title = UILabel()
        title.text = "Hello，自建 iPhone App"
        title.font = .systemFont(ofSize: 28, weight: .bold)
        title.textColor = .label
        title.textAlignment = .center
        title.numberOfLines = 0
        title.translatesAutoresizingMaskIntoConstraints = false

        let device = UIDevice.current
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "-"
        let info = UILabel()
        info.text = """
        \(device.model) · \(device.systemName) \(device.systemVersion)
        Bundle: \(Bundle.main.bundleIdentifier ?? "-")
        Version: \(version)
        Build: \(Date())
        """
        info.font = .monospacedSystemFont(ofSize: 13, weight: .regular)
        info.textColor = .secondaryLabel
        info.textAlignment = .center
        info.numberOfLines = 0
        info.translatesAutoresizingMaskIntoConstraints = false

        let hint = UILabel()
        hint.text = "签名方式：zsign + 自有证书"
        hint.font = .systemFont(ofSize: 12)
        hint.textColor = .tertiaryLabel
        hint.textAlignment = .center
        hint.numberOfLines = 0
        hint.translatesAutoresizingMaskIntoConstraints = false

        [title, info, hint].forEach { view.addSubview($0) }

        NSLayoutConstraint.activate([
            title.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            title.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -30),
            title.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 24),
            title.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -24),

            info.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 18),
            info.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            info.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 24),
            info.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -24),

            hint.topAnchor.constraint(equalTo: info.bottomAnchor, constant: 18),
            hint.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            hint.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 24),
            hint.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -24),
        ])
    }
}

final class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = ViewController()
        window.makeKeyAndVisible()
        self.window = window
        return true
    }
}

// main.swift 允许顶层代码，直接拉起 RunLoop
UIApplicationMain(
    CommandLine.argc,
    CommandLine.unsafeArgv,
    nil,
    NSStringFromClass(AppDelegate.self)
)
