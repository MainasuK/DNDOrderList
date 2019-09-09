//
//  Item.swift
//  DNDOrderList
//
//  Created by Cirno MainasuK on 2019-9-9.
//  Copyright © 2019 mainasuk. All rights reserved.
//

import Foundation
import CoreData

@objc(Item)
public class Item: NSManagedObject {
    @NSManaged fileprivate(set) var name: String
    @NSManaged fileprivate(set) var order: Int64
}

extension Item {

    public static var entityName: String {
        return "Item"
    }

    public static var defaultSortDescriptors: [NSSortDescriptor] {
        return [NSSortDescriptor(keyPath: \Item.order, ascending: true)]
    }

    static var sortedFetchRequest: NSFetchRequest<Item> {
        let request = NSFetchRequest<Item>(entityName: entityName)
        request.sortDescriptors = defaultSortDescriptors
        request.returnsObjectsAsFaults = true
        request.fetchBatchSize = 20
        return request
    }

}

extension Item {

    static func insertNewObject(in context: NSManagedObjectContext, content: ItemContent) -> Item {
        let item = Item(context: context)
        item.name = content.name
        item.order = content.order
        return item
    }

}

struct ItemContent {
    let name: String
    let order: Int64
}
