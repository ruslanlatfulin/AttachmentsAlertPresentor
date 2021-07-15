import Foundation

extension Array {
    
    @discardableResult
    mutating func append(_ newArray: Array) -> CountableRange<Int> {
        let range = count..<(count + newArray.count)
        self += newArray
        return range
    }
    
    mutating func remove<T: AnyObject> (_ element: T) {
        let anotherSelf = self
        
        removeAll(keepingCapacity: true)
        
        anotherSelf.each { (index: Int, current: Element) in
            if (current as! T) !== element {
                self.append(current)
            }
        }
    }
    
    func each(_ exe: (Int, Element) -> ()) {
        for (index, item) in enumerated() {
            exe(index, item)
        }
    }
}

