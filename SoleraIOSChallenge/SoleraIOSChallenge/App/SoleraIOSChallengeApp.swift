//
//  SoleraIOSChallengeApp.swift
//  SoleraIOSChallenge
//
//  Created by Alexei on 24/09/2026.
//

import SwiftUI

@main
@MainActor
struct SoleraIOSChallengeApp: App {
    @State private var model: CatalogViewModel?
    private let setupError: String?
    private let isUnitTest: Bool

    init() {
        isUnitTest = ProcessInfo.processInfo.environment["XCTestBundlePath"] != nil
        if isUnitTest {
            _model = State(initialValue: nil)
            setupError = nil
            return
        }
        do {
            let container = try AppDIContainer(configuration: AppConfiguration.load())
            _model = State(initialValue: container.makeCatalogViewModel())
            setupError = nil
        } catch {
            _model = State(initialValue: nil)
            setupError = error.localizedDescription
        }
    }

    var body: some Scene {
        WindowGroup {
            if isUnitTest {
                Color.clear
            } else if let model {
                CatalogView(model: model)
            } else {
                ContentUnavailableView(
                    "Catalog unavailable",
                    systemImage: "exclamationmark.triangle",
                    description: Text(setupError ?? "Please check the app configuration.")
                )
            }
        }
    }
}
