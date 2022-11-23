//
//  ContentView.swift
//  UITimeline
//
//  Created by Doug on 23/11/2022.
//

import SwiftUI

struct TimelineView: View {
    @EnvironmentObject private var context: RoomScreenContext
    
    var body: some View {
        TimelineCollectionView()
            .ignoresSafeArea()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Send") {
                        context.send(viewAction: .sendMessage)
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Edits") {
                        context.send(viewAction: .editAll)
                    }
                }
            }
            .onAppear { context.send(viewAction: .loadPreviousPage) }
    }
}

struct TimelineView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            TimelineView()
                .environmentObject(RoomScreenContext())
        }
    }
}
