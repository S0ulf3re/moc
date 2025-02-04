//
//  MocApp.swift
//  Moc
//
//  Created by Егор Яковенко on 24.12.2021.
//

import Backend
import CryptoKit
import Generated
import Logging
import Resolver
import SwiftUI
import SystemUtils
import TDLibKit

final class TdLogger: TDLibKit.Logger {
    private let logger = Logging.Logger(label: "TDLib")
    let queue: DispatchQueue

    func log(_ message: String, type: LoggerMessageType?) {
        queue.async {
            guard type != nil else {
                self.logger.info("\(message)")
                return
            }

            var typeStr = ""
            switch type! {
            case .receive:
                typeStr = "receive:"
            case .send:
                typeStr = "send:"
            case .execute:
                typeStr = "execute:"
            case let .custom(data):
                typeStr = "\(data):"
            }

            #if DEBUG
                self.logger.info("\(typeStr) \(message)")
            #endif
        }
    }

    init() {
        queue = DispatchQueue(label: "TDLibKitLog", qos: .userInitiated)
    }
}

public extension Resolver {
    private static let logger = Logging.Logger(label: "TDLibUpdates")

    static func registerUI() {
        register { MainViewModel() }.scope(.shared)
        register { ChatViewModel() }.scope(.shared)
    }

    static func registerBackend() {
        register { TdChatService() as ChatService }
            .scope(.shared)
        register { TdLoginService() as LoginService }
            .scope(.shared)
        register { TdAccountsPrefService() as AccountsPrefService }
            .scope(.shared)
    }
}

// swiftlint:disable weak_delegate
@main
struct MocApp: App {
    @NSApplicationDelegateAdaptor var appDelegate: AppDelegate
    private let logger = Logging.Logger(label: "TDLibUpdates")

    init() {
        Resolver.registerUI()
        Resolver.registerBackend()
        TdApi.shared.append(TdApi(
            client: TdClientImpl(
                completionQueue: DispatchQueue(
                    label: tdCompletionQueueLabel,
                    qos: .userInteractive
                ),
                logger: TdLogger()
            )
        ))
        TdApi.shared[0].startTdLibUpdateHandler()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }

        Settings {
            PreferencesContent()
        }
    }
}
