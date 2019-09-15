//
//  ViewController.swift
//  DNDOrderList
//
//  Created by Cirno MainasuK on 2019-9-9.
//  Copyright © 2019 mainasuk. All rights reserved.
//

import UIKit
import CoreData

class ViewController: UIViewController {

    private let context: NSManagedObjectContext = {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        return appDelegate.persistentContainer.viewContext
    }()

    private let tableView: UITableView = {
        let tableView = UITableView()
        tableView.register(ItemTableViewCell.self, forCellReuseIdentifier: String(describing: ItemTableViewCell.self))
        tableView.alwaysBounceVertical = true
        tableView.tableFooterView = UIView()
        return tableView
    }()

    lazy var fetchedResultsController: NSFetchedResultsController<Item> = {
        let fetchRequest = Item.sortedFetchRequest
        let controller = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
        return controller
    }()

    lazy var diffableDataSource = configureDataSource()

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Order List"
        view.backgroundColor = .systemBackground
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(ViewController.addBarButtonPressed(_:)))

        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        fetchedResultsController.delegate = self
        try! fetchedResultsController.performFetch()

        tableView.dragInteractionEnabled = true
        tableView.dragDelegate = self
        tableView.dropDelegate = self
        
        tableView.delegate = self
        tableView.dataSource = diffableDataSource
        updateDataSource()

    }

}

extension ViewController {

    @objc private func addBarButtonPressed(_ sender: UIBarButtonItem) {
        let newOrder = fetchedResultsController.fetchedObjects?.last.flatMap { $0.order + 1 } ?? 0
        let itemContent = ItemContent(name: "\(newOrder)", order: newOrder)
        context.performChanges {
            _ = Item.insertNewObject(in: self.context, content: itemContent)
        }
    }

}

final class ItemTableViewDiffableDataSource<SectionIdentifierType, ItemIdentifierType> : UITableViewDiffableDataSource<SectionIdentifierType, ItemIdentifierType> where SectionIdentifierType : Hashable, ItemIdentifierType : Hashable {

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    /*
    override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        var snapshot = self.snapshot()
        let items = snapshot.itemIdentifiers
        let sourceItem = items[sourceIndexPath.row]
        let destinationItem: ItemIdentifierType = {
            return items.first!
        }()

        snapshot.moveItem(sourceItem, beforeItem: destinationItem)
        self.apply(snapshot)
    }
    */

}

extension ViewController {

    enum Section: CaseIterable {
        case main
    }

    private func configureDataSource() -> UITableViewDiffableDataSource<Section, Item> {
        return ItemTableViewDiffableDataSource(tableView: tableView) { tableView, indexPath, item -> UITableViewCell? in
            let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: ItemTableViewCell.self), for: indexPath) as! ItemTableViewCell
            ViewController.configure(cell, with: item)
            return cell
        }
    }

    private static func configure(_ cell: ItemTableViewCell, with item: Item) {
        cell.textLabel?.text = item.name
        cell.detailTextLabel?.text = "\(item.order)"
    }

}

// MARK: - NSFetchedResultsControllerDelegate
extension ViewController: NSFetchedResultsControllerDelegate {

    fileprivate func updateDataSource() {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections([.main])
        snapshot.appendItems(fetchedResultsController.fetchedObjects ?? [])
        diffableDataSource.apply(snapshot)
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        updateDataSource()
    }

}

// MARK: - UITableViewDelegate
extension ViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }

    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        return nil
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let delete = UIContextualAction(style: .destructive, title: "Delete") { action, view, handler in
            guard let item = self.diffableDataSource.itemIdentifier(for: indexPath) else {
                return
            }
            self.context.performChanges {
                self.context.delete(item)
            }
            handler(true)
        }

        let configuration = UISwipeActionsConfiguration(actions: [delete])
        configuration.performsFirstActionWithFullSwipe = true

        return configuration
    }

}


// MARK: - UITableViewDragDelegate
extension ViewController: UITableViewDragDelegate {

    func tableView(_ tableView: UITableView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        return [UIDragItem(itemProvider: NSItemProvider())]
    }

    func tableView(_ tableView: UITableView, dragPreviewParametersForRowAt indexPath: IndexPath) -> UIDragPreviewParameters? {
        let parameters = UIDragPreviewParameters()
        parameters.backgroundColor = .clear
        return parameters
    }

}

// MARK: - UITableViewDropDelegate
extension ViewController: UITableViewDropDelegate {

    func tableView(_ tableView: UITableView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UITableViewDropProposal {
        guard let dragSession = session.localDragSession else {
            return UITableViewDropProposal(operation: .cancel, intent: .unspecified)
        }

        // drag in same app
        return UITableViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
    }

    func tableView(_ tableView: UITableView, performDropWith coordinator: UITableViewDropCoordinator) {
        
    }

}
