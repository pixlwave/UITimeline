//
//  TimelineListView.swift
//  UITimeline
//
//  Created by Doug on 23/11/2022.
//

import SwiftUI

class TimelineItemSwiftUICell: UICollectionViewCell {
    var timelineItem: TextRoomTimelineItem?
}

struct TimelineCollectionView: UIViewRepresentable {
    @EnvironmentObject private var viewModelContext: RoomScreenContext
    
    func makeUIView(context: Context) -> UICollectionView {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: context.coordinator.makeLayout())
        context.coordinator.collectionView = collectionView
        return collectionView
    }
    
    func updateUIView(_ uiView: UICollectionView, context: Context) {
        context.coordinator.timelineItems = viewModelContext.viewState.items
        context.coordinator.isBackPaginating = viewModelContext.viewState.isBackPaginating
        context.coordinator.loadPreviousPage = { viewModelContext.send(viewAction: .loadPreviousPage) }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    // MARK: - Coordinator
    
    @MainActor
    class Coordinator: NSObject {
        var timelineItems: [TextRoomTimelineItem] = [] {
            didSet {
                applySnapshot()
            }
        }
        var isBackPaginating = false
        var loadPreviousPage: (() -> Void)?
        
        var dataSource: UICollectionViewDiffableDataSource<TimelineSection, TextRoomTimelineItem>?
        var collectionView: UICollectionView? {
            didSet {
                configureDataSource()
            }
        }
        
        func makeLayout() -> UICollectionViewCompositionalLayout {
            var configuration = UICollectionLayoutListConfiguration(appearance: .plain)
            configuration.showsSeparators = false
            return UICollectionViewCompositionalLayout.list(using: configuration)
        }
        
        private func configureDataSource() {
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
            snapshot.appendItems(timelineItems)
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
            guard let lastItem = timelineItems.last,
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
        guard !isBackPaginating, scrollView.contentOffset.y < 100 else { return }
        loadPreviousPage?()
        print("Loading page \(Date().formatted(.dateTime.second().secondFraction(.milliseconds(2))))")
    }
}
