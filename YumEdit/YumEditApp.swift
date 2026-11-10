//
//  YumEditApp.swift
//  YumEdit
//
//  Created by Taj C on 8/20/26.
//

import SwiftUI
import UIKit
import Combine

@MainActor
final class QuickActionState: ObservableObject {
    static let shared = QuickActionState()
    @Published var respringRequested = false
}

final class YumEditSceneDelegate: NSObject, UIWindowSceneDelegate {
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        if connectionOptions.shortcutItem?.type == "com.hyumpix.yumedit.respring" {
            QuickActionState.shared.respringRequested = true
        }
    }

    func windowScene(_ windowScene: UIWindowScene, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        let handled = shortcutItem.type == "com.hyumpix.yumedit.respring"
        if handled { QuickActionState.shared.respringRequested = true }
        completionHandler(handled)
    }
}

final class YumEditAppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let configuration = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        if connectingSceneSession.role == .windowApplication { configuration.delegateClass = YumEditSceneDelegate.self }
        return configuration
    }
}

@main
struct YumEditApp: App {
    @UIApplicationDelegateAdaptor(YumEditAppDelegate.self) private var appDelegate
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
