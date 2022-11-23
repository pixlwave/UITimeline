//
//  UITimelineApp.swift
//  UITimeline
//
//  Created by Doug on 23/11/2022.
//

import SwiftUI

@main
struct UITimelineApp: App {
    @StateObject private var roomScreenContext = RoomScreenContext()
    
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                TimelineView()
                    .environmentObject(roomScreenContext)
            }
        }
    }
}
