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
    
    /// The datastorage
    public private(set) var pages = [Int: [Element]]()
    
    // MARK: Public properties
    
    /// The size of each page
    public let pageSize: Int
    
    /// The total count of supposed elements, including nil values
    public var count: Int
    
    /// The starting page index
    public let startPageIndex: Int
    
    /// When set to true, no size or upper index checking
    /// is done when setting pages, making the paged array
    /// adjust its size dynamically.
    ///
    /// Useful for infinite lists and when data count cannot
    /// be guaranteed not to change while loading new pages.
    public var updatesCountWhenSettingPages: Bool = false
    
    /// The last valid page index
    public var lastPageIndex: Int {
        if count == 0 {
            return 0
        } else if count%pageSize == 0 {
            return count/pageSize+startPageIndex-1
        } else {
            return count/pageSize+startPageIndex
        }
    }
    
    /// All elements currently set, in order
    public var loadedElements: [Element] {
        return self.filter{ $0 != nil }.map{ $0! }
    }
    
    // MARK: Initializers
    
    /// Creates an empty `PagedArray`
    public init(count: Int, pageSize: Int, startPageIndex: Int = 0) {
        self.count = count
        self.pageSize = pageSize
        self.startPageIndex = startPageIndex
    }
    
    // MARK: Public functions
    
    /// Returns the page index for an element index
    public func pageNumberForIndex(index: Index) -> Int {
        assert(index >= startIndex && index < endIndex, "Index out of bounds")
        return index/pageSize+startPageIndex
    }
    
    /// Returns a `Range` corresponding to the indexes for a page
    public func indexes(pageIndex: Int) -> Range<Index> {
        assert(pageIndex >= startPageIndex && pageIndex <= lastPageIndex, "Page index out of bounds")
        
        let startIndex: Index = (pageIndex-startPageIndex)*pageSize
        let endIndex: Index
        if pageIndex == lastPageIndex {
            endIndex = count
        } else {
            endIndex = startIndex+pageSize
        }
        
        return (startIndex..<endIndex)
    }
    
    // MARK: Public mutating functions
    
    /// Sets a page of elements for a page index
    public mutating func setElements(elements: [Element], pageIndex: Int) {
        assert(pageIndex >= startPageIndex, "Page index out of bounds")
        assert(count == 0 || elements.count > 0, "Can't set empty elements page on non-empty array")
        
        let pageIndexForExpectedSize = (pageIndex > lastPageIndex) ? lastPageIndex : pageIndex
        let expectedSize = sizeForPage(pageIndexForExpectedSize)
        
        if !updatesCountWhenSettingPages {
            assert(pageIndex <= lastPageIndex, "Page index out of bounds")
            assert(elements.count == expectedSize, "Incorrect page size")
        } else {
            // High Chaparall mode, array can change in size
            count += elements.count-expectedSize
            if pageIndex > lastPageIndex {
                count += (pageIndex-lastPageIndex)*pageSize
            }
        }
        
        pages[pageIndex] = elements
    }
    
    /// Removes the elements corresponding to the page, replacing them with `nil` values
    public mutating func removePage(pageNumber: Int) {
        pages[pageNumber] = nil
    }
    
    /// Removes all loaded elements, replacing them with `nil` values
    public mutating func removeAllPages() {
        pages.removeAll(keepCapacity: true)
    }
    
}

// MARK: SequenceType

extension PagedArray : SequenceType {
    public func generate() -> IndexingGenerator<PagedArray> {
        return IndexingGenerator(self)
    }
}

// MARK: CollectionType

extension PagedArray : CollectionType {
    public typealias Index = Int
    
    public var startIndex: Index { return 0 }
    public var endIndex: Index { return count }
    
    public subscript (index: Index) -> Element? {
        let pageNumber = pageNumberForIndex(index)
        
        if let page = pages[pageNumber] {
            return page[index%pageSize]
        } else {
            // Return nil for all pages that haven't been set yet
            return nil
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
        return "PagedArray(Pages: \(pages), Array representation: \(Array(self)))"
    }
}

// MARK: Private functions

private extension PagedArray {
    func sizeForPage(pageIndex: Int) -> Int {
        let indexes = self.indexes(pageIndex)
        return indexes.endIndex-indexes.startIndex
    }
}

