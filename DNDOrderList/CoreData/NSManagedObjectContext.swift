//
//  NSManagedObjectContext.swift
//  DNDOrderList
//
//  Created by Cirno MainasuK on 2019-9-9.
//  Copyright © 2019 mainasuk. All rights reserved.
//

import Foundation
import CoreData

extension NSManagedObjectContext {

    public func saveOrRollback() -> Bool {
        do {
            try save()
            return true
        } catch {
            rollback()
            return false
        }
    }

    public func performChanges(block: @escaping () -> Void) {
        perform {
            block()
            _ = self.saveOrRollback()
        }
    }

}
