//
//  TimelineListView.swift
//  UITimeline
//
//  Created by Doug on 23/11/2022.
//

import SwiftUI
import Combine

class TimelineItemSwiftUICell: UICollectionViewCell {
    var timelineItem: TextRoomTimelineItem?
}

struct TimelineCollectionView: UIViewRepresentable {
    @EnvironmentObject private var context: RoomScreenContext
    
    func makeUIView(context: Context) -> UICollectionView {
        var configuration = UICollectionLayoutListConfiguration(appearance: .plain)
        configuration.showsSeparators = false
        let layout = UICollectionViewCompositionalLayout.list(using: configuration)
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        context.coordinator.collectionView = collectionView
        return collectionView
    }
    
    func updateUIView(_ uiView: UICollectionView, context: Context) {
        // nothing to update yet
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(context: context)
    }
    
    // MARK: - Coordinator
    
    @MainActor
    class Coordinator: NSObject {
        let context: RoomScreenContext
        var contextCancellable: AnyCancellable?
        
        var dataSource: UICollectionViewDiffableDataSource<TimelineSection, TextRoomTimelineItem>?
        var collectionView: UICollectionView? {
            didSet {
                configureDataSource()
            }
        }
        
        init(context: RoomScreenContext) {
            self.context = context
            super.init()
            
            contextCancellable = context.objectWillChange.sink {
                // Dispatched because of the *will* change
                DispatchQueue.main.async { [weak self] in
                    self?.applySnapshot()
                }
            }
        }
        
        func configureDataSource() {
            guard let collectionView else { return }
            let cellRegistration = UICollectionView.CellRegistration<TimelineItemSwiftUICell, TextRoomTimelineItem> { cell, indexPath, timelineItem in
                cell.timelineItem = timelineItem
            }
            
            dataSource = .init(collectionView: collectionView) { collectionView, indexPath, timelineItem in
                let cell = collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: timelineItem)
                cell.contentConfiguration = UIHostingConfiguration {
                    TextRoomTimelineView(timelineItem: timelineItem)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                return cell
            }
            
            collectionView.delegate = self
        }
        
        func applySnapshot() {
            let previousLayout = layout()
            
            var snapshot = NSDiffableDataSourceSnapshot<TimelineSection, TextRoomTimelineItem>()
            snapshot.appendSections([.main])
            snapshot.appendItems(context.viewState.items)
            dataSource?.apply(snapshot, animatingDifferences: false)
            
            if previousLayout.isBottomVisible || previousLayout.isEmpty {
                let animated = !previousLayout.isEmpty
                scrollToBottom(animated: animated)
            } else if previousLayout.isTopVisible, let collectionView {
                #warning("This assumes that the changes have resulted in a larger height...")
                collectionView.contentOffset.y += collectionView.contentSize.height - previousLayout.contentSize.height
            }
        }
        
        func layout() -> LayoutDescriptor {
            guard let collectionView, let dataSource else { return LayoutDescriptor() }
            
            var layout = LayoutDescriptor(contentSize: collectionView.contentSize)
            let snapshot = dataSource.snapshot()
            
            guard !snapshot.itemIdentifiers.isEmpty else {
                layout.isEmpty = true
                return layout
            }
            
            if let firstItem = snapshot.itemIdentifiers.first,
               let firstIndexPath = dataSource.indexPath(for: firstItem) {
                layout.isTopVisible = collectionView.indexPathsForVisibleItems.contains(firstIndexPath)
            }
            
            if let lastItem = snapshot.itemIdentifiers.last,
               let lastIndexPath = dataSource.indexPath(for: lastItem) {
                layout.isBottomVisible = collectionView.indexPathsForVisibleItems.contains(lastIndexPath)
            }
            
            return layout
        }
        
        func scrollToBottom(animated: Bool) {
            guard let lastItem = context.viewState.items.last,
                  let lastIndexPath = dataSource?.indexPath(for: lastItem)
            else { return }
            
            collectionView?.scrollToItem(at: lastIndexPath, at: .bottom, animated: animated)
        }
    }
    
    enum TimelineSection { case main }
    
    struct LayoutDescriptor {
        var isTopVisible = false
        var isBottomVisible = false
        var isEmpty = false
        var contentSize: CGSize = .zero
    }
}

// MARK: - UICollectionViewDelegate

extension TimelineCollectionView.Coordinator: UICollectionViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard !context.viewState.isBackPaginating, scrollView.contentOffset.y < 100 else { return }
        context.send(viewAction: .loadPreviousPage)
        print("Loading page \(Date().formatted(.dateTime.second().secondFraction(.milliseconds(2))))")
    }
}
