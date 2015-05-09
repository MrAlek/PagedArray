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
/// mechanisms when providing data read from slow I/O to scrolling UI elements
/// such as `UICollectionView` and `UITableView`.
///
public struct PagedArray<T> {
    private typealias Element = T
    
    /// The datastorage
    public private(set) var pages = [Int: [Element]]()
    
    // MARK: Public properties
    
    /// The size of each page
    public let pageSize: Int
    
    /// The total count of supposed elements, including nil values
    public let count: Int
    
    /// The starting page index
    public let startPage: Int
    
    /// The last valid page index
    public var lastPage: Int {
        var result = (count/pageSize) + startPage
        if (count % pageSize) == 0 {
            result--
        }
        return result
    }
    
    /// All elements currently set, in order
    public var loadedElements: [Element] {
        return self.filter{ $0 != nil }.map{ $0! }
    }
    
    // MARK: Initializers
    
    /// Creates an empty `PagedArray`
    public init(count: Int, pageSize: Int, startPage: Int) {
        self.count = count
        self.pageSize = pageSize
        self.startPage = startPage
    }
    
    /// Creates an empty `PagedArray` with a default 0 `startPage` index
    public init(count: Int, pageSize: Int) {
        self.count = count
        self.pageSize = pageSize
        self.startPage = 0
    }
    
    // MARK: Public functions
    
    /// Returns the page index for an element index
    public func pageNumberForIndex(index: Index) -> Int {
        assert(index >= startIndex || index <= endIndex, "Index out of bounds")
        return index/pageSize+startPage
    }
    
    /// Returns a `Range` corresponding to the indexes for a page
    public func indexesForPage(page: Int) -> Range<Index> {
        assert(page >= startPage && page <= lastPage, "Page index out of bounds")
        
        let startIndex: Index = (page-startPage)*pageSize
        let endIndex: Index
        if page == lastPage {
            endIndex = count
        } else {
            endIndex = startIndex+pageSize
        }
        
        return (startIndex..<endIndex)
    }
    
    // MARK: Public mutating functions
    
    /// Sets a page of elements for a page index
    public mutating func setElements(elements: [Element], page: Int) {
        assert(page >= startPage && page <= lastPage, "Page index out of bounds")
        if page != lastPage {
            assert(elements.count == pageSize, "Invalid elements count for page")
        }
        
        pages[page] = elements
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

// MARK: Higher order functions

extension PagedArray {
    
    /// Returns a filtered `Array` of optional elements filtered by `includeElement` function
    public func filter(includeElement: (T?) -> Bool) -> [T?] {
        return Array(self).filter(includeElement)
    }
    
    /// Returns an `Array` where each optional element is transformed by provided `transform`
    public func map<U>(transform: (T?) -> U) -> [U] {
        return Array(self).map(transform)
    }
    
    // Returns a single value by iteratively combining each element
    public func reduce<U>(var initial: U, combine: (U, T?) -> U) -> U {
        return Swift.reduce(self, initial, combine)
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

extension PagedArray : Printable {
    public var description: String {
        return "PagedArray(\(Array(self)))"
    }
}

// MARK: DebugPrintable

extension PagedArray : DebugPrintable {
    public var debugDescription: String {
        return "PagedArray(Pages: \(pages), Array representation: \(Array(self)))"
    }
}

