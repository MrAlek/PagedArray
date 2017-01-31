//
// PagedArray.swift
//
// Created by Alek Åström on 2015-02-14.
// Copyright (c) 2015 Alek Åström. (https://github.com/MrAlek)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

///
/// A paging collection type for arbitrary elements. Great for implementing paging
/// mechanisms to scrolling UI elements such as `UICollectionView` and `UITableView`.
///
public struct PagedArray<T> {
    public typealias Element = T
    public typealias PageIndex = Int
    
    /// The datastorage
    public fileprivate(set) var elements = [PageIndex: [Element]]()
    
    // MARK: Public properties
    
    /// The size of each page
    public let pageSize: Int
    
    /// The total count of supposed elements, including nil values
    public var count: Int
    
    /// The starting page index
    public let startPage: PageIndex
    
    /// When set to true, no size or upper index checking
    /// is done when setting pages, making the paged array
    /// adjust its size dynamically.
    ///
    /// Useful for infinite lists and when data count cannot
    /// be guaranteed not to change while loading new pages.
    public var updatesCountWhenSettingPages: Bool = false
    
    /// The last valid page index
    public var lastPage: PageIndex {
        if count == 0 {
            return 0
        } else if count%pageSize == 0 {
            return count/pageSize+startPage-1
        } else {
            return count/pageSize+startPage
        }
    }
    
    /// All elements currently set, in order
    public var loadedElements: [Element] {
        return self.filter{ $0 != nil }.map{ $0! }
    }
    
    // MARK: Initializers
    
    /// Creates an empty `PagedArray`
    public init(count: Int, pageSize: Int, startPage: PageIndex = 0) {
        self.count = count
        self.pageSize = pageSize
        self.startPage = startPage
    }
    
    // MARK: Public functions
    
    /// Returns the page index for an element index
    public func page(for index: Index) -> PageIndex {
        assert(index >= startIndex && index < endIndex, "Index out of bounds")
        return index/pageSize+startPage
    }
    
    /// Returns a `Range` corresponding to the indexes for a page
    public func indexes(for page: PageIndex) -> CountableRange<Index> {
        assert(page >= startPage && page <= lastPage, "Page index out of bounds")
        
        let start: Index = (page-startPage)*pageSize
        let end: Index
        if page == lastPage {
            end = count
        } else {
            end = start+pageSize
        }
        
        return (start..<end)
    }
    
    // MARK: Public mutating functions
    
    /// Sets a page of elements for a page index
    public mutating func set(_ elements: [Element], forPage page: PageIndex) {
        assert(page >= startPage, "Page index out of bounds")
        assert(count == 0 || elements.count > 0, "Can't set empty elements page on non-empty array")
        
        let pageIndexForExpectedSize = (page > lastPage) ? lastPage : page
        let expectedSize = size(for: pageIndexForExpectedSize)
        
        if !updatesCountWhenSettingPages {
            assert(page <= lastPage, "Page index out of bounds")
            assert(elements.count == expectedSize, "Incorrect page size")
        } else {
            // High Chaparall mode, array can change in size
            count += elements.count-expectedSize
            if page > lastPage {
                count += (page-lastPage)*pageSize
            }
        }
        
        self.elements[page] = elements
    }
    
    /// Removes the elements corresponding to the page, replacing them with `nil` values
    public mutating func remove(_ page: PageIndex) {
        elements[page] = nil
    }
    
    /// Removes all loaded elements, replacing them with `nil` values
    public mutating func removeAllPages() {
        elements.removeAll(keepingCapacity: true)
    }
    
}

// MARK: SequenceType

extension PagedArray : Sequence {
    public func makeIterator() -> IndexingIterator<PagedArray> {
        return IndexingIterator(_elements: self)
    }
}

// MARK: CollectionType

extension PagedArray : BidirectionalCollection {
    public typealias Index = Int
    public typealias _Element = Element?
    
    public var startIndex: Index { return 0 }
    public var endIndex: Index { return count }
    
    public func index(after i: Index) -> Index {
        return i+1
    }
    
    public func index(before i: Index) -> Index {
        return i-1
    }
    
    /// Accesses and sets elements for a given flat index position.
    /// Currently, setter can only be used to replace non-optional values.
    public subscript (position: Index) -> Element? {
        get {
            let pageIndex = page(for: position)
            
            if let page = elements[pageIndex] {
                return page[position%pageSize]
            } else {
                // Return nil for all pages that haven't been set yet
                return nil
            }
        }
        
        set(newValue) {
            guard let newValue = newValue else { return }
            
            let pageIndex = page(for: position)
            elements[pageIndex]?[position % pageSize] = newValue
        }
    }
}

// MARK: Printable

extension PagedArray : CustomStringConvertible {
    public var description: String {
        return "PagedArray(\(Array(self)))"
    }
}

// MARK: DebugPrintable

extension PagedArray : CustomDebugStringConvertible {
    public var debugDescription: String {
        return "PagedArray(Pages: \(elements), Array representation: \(Array(self)))"
    }
}

// MARK: Private functions

private extension PagedArray {
    func size(for page: PageIndex) -> Int {
        let indexes = self.indexes(for: page)
        return indexes.endIndex-indexes.startIndex
    }
}

