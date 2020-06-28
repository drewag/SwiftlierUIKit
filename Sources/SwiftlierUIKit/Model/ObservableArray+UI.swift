//
//  UIImage+Editing.swift
//  Swiftlier
//
//  Created by Andrew J Wagner on 5/25/16.
//  Copyright © 2016 Drewag LLC. All rights reserved.
//

import UIKit
import Swiftlier

extension ObservableArray {
    public func add(observer: AnyObject, forSection section: Int, in tableView: UITableView, withIndexOffset indexOffset: Int = 0, withEmptyRowCount emptyRowCount: Int = 0) {
        self.add(
            observer: observer,
            onDidInsert: { [unowned self] _, index in
                let indexPath = IndexPath(item: index + indexOffset, section: section)
                if self.values.count == 1 && emptyRowCount != 0 {
                    // Was Empty
                    tableView.reloadRows(at: [indexPath], with: .automatic)
                    let indexPaths = (1 ..< emptyRowCount).map({IndexPath(item: $0 + indexOffset, section: section)})
                    if !indexPaths.isEmpty {
                        tableView.deleteRows(at: indexPaths, with: .automatic)
                    }
                }
                else {
                    tableView.insertRows(at: [indexPath], with: .automatic)
                }
            },
            onDidRemove: { [unowned self] _, index in
                let indexPath = IndexPath(item: index + indexOffset, section: section)
                if self.values.count == 0 && emptyRowCount != 0 {
                    // Now empty
                    tableView.reloadRows(at: [indexPath], with: .automatic)
                    let indexPaths = (1 ..< emptyRowCount).map({IndexPath(item: $0 + indexOffset, section: section)})
                    if !indexPaths.isEmpty {
                        tableView.insertRows(at: indexPaths, with: .automatic)
                    }
                }
                else {
                    tableView.deleteRows(at: [indexPath], with: .automatic)
                }
            },
            onDidRemoveAll: { _ in
                tableView.reloadSections(IndexSet(integer: section), with: .automatic)
            },
            onDidMove: { _, from, to in
                tableView.moveRow(
                    at: IndexPath(row: from + indexOffset, section: section),
                    to: IndexPath(row: to + indexOffset, section: section)
                )
            }
        )
    }

    public func add(observer: AnyObject, forSection section: Int, in collectionView: UICollectionView, withIndexOffset indexOffset: Int = 0) {
        self.add(
            observer: observer,
            onDidInsert: { _, index in
                let indexPath = IndexPath(item: index + indexOffset, section: section)
                collectionView.insertItems(at: [indexPath])
            },
            onDidRemove: { _, index in
                let indexPath = IndexPath(item: index + indexOffset, section: section)
                collectionView.deleteItems(at: [indexPath])
            },
            onDidRemoveAll: { _ in
                collectionView.reloadData()
            },
            onDidMove: { _, from, to in
                collectionView.moveItem(
                    at: IndexPath(item: from + indexOffset, section: section),
                    to: IndexPath(item: to + indexOffset, section: section)
                )
            }
        )
    }
}
