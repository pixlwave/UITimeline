//
//  TimelineList.swift
//  UITimeline
//
//  Created by Doug on 23/11/2022.
//

import SwiftUI

struct TimelineListView: View {
    @EnvironmentObject private var context: RoomScreenContext
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(context.viewState.items) { item in
                    TextRoomTimelineView(timelineItem: item)
                }
            }
        }
    }
}
