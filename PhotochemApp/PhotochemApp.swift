import PhotochemModule
import SwiftUI

@main
struct PhotochemApp: App {
    @State private var module = PhotochemModule()

    var body: some Scene {
        WindowGroup {
            module.rootView()
        }
    }
}
