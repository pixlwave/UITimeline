//
//  RoomScreenContext.swift
//  UITimeline
//
//  Created by Doug on 23/11/2022.
//

import Foundation
import Combine

@MainActor
class RoomScreenContext: ObservableObject {
    @Published var viewState = RoomScreenViewState(roomId: "testroom")
    
    let loadPreviousPagePublisher = PassthroughSubject<Void, Never>()
    var cancellables: Set<AnyCancellable> = []
    
    private let mySenderID = "@me:home.org"
    
    init() {
        loadPreviousPagePublisher
            .collect(.byTime(DispatchQueue.main, 0.1))
            .sink { [weak self] _ in
                self?.send(viewAction: .loadPreviousPage)
            }
            .store(in: &cancellables)
    }
    
    func send(viewAction: RoomScreenViewAction) {
        switch viewAction {
        case .loadPreviousPage:
            Task { await loadPreviousPage() }
        case .itemAppeared(let id):
            break
        case .itemDisappeared(let id):
            break
        case .sendMessage:
            Task { await sendMessage() }
        case .itemTapped, .linkClicked, .sendReaction, .cancelReply, .cancelEdit:
            break
        case .editAll:
            editAll()
        }
    }
    
    func loadPreviousPage() async {
        guard !viewState.isBackPaginating else { return }
        
        viewState.isBackPaginating = true
        try! await Task.sleep(for: .milliseconds(.random(in: 250...750)))
        await viewState.items.insert(contentsOf: paginateBackwards(), at: 0)
        viewState.isBackPaginating = false
    }
    
    func sendMessage() async {
        let item = nextMessageItem()
        viewState.items.append(item)
    }
    
    // MARK: - Timeline Provider
    
    private var oldestMessage = 50_000
    private var newestMessage = 50_000
    
    func paginateBackwards(_ limit: Int = 20) async -> [TextRoomTimelineItem] {
        var items = [TextRoomTimelineItem]()
        
        for _ in 0..<limit {
            oldestMessage -= 1
            let message = messageString(for: oldestMessage)
            let item = TextRoomTimelineItem(id: "\(oldestMessage)",
                                            text: message,
                                            timestamp: "\(oldestMessage)",
                                            inGroupState: .single,
                                            isOutgoing: .random(),
                                            isEditable: false,
                                            senderId: "Doug")
            items.insert(item, at: 0)
        }
        
        return items
    }
    
    func nextMessageItem() -> TextRoomTimelineItem {
        newestMessage += 1
        let message = messageString(for: newestMessage)
        let item = TextRoomTimelineItem(id: "\(newestMessage)",
                                        text: message,
                                        timestamp: "\(newestMessage)",
                                        inGroupState: .single,
                                        isOutgoing: true,
                                        isEditable: false,
                                        senderId: mySenderID)
        return item
    }
    
    private var formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .spellOut
        return formatter
    }()
    
    func messageString(for index: Int) -> String {
        formatter.string(from: index as NSNumber) ?? "Unknown"
    }
    
    func editAll() {
        viewState.items = viewState.items.map { item in
            TextRoomTimelineItem(id: item.id,
                                 text: String(item.text.dropLast(15)),
                                 timestamp: item.timestamp,
                                 inGroupState: item.inGroupState,
                                 isOutgoing: item.isOutgoing,
                                 isEditable: item.isEditable,
                                 senderId: item.senderId)
        }
    }
}
