//
// PagedArrayTests.swift
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

import XCTest
import PagedArray

class PagedArrayTests: XCTestCase {
    
    // These three parameters should be modifiable without any
    // test failing as long as the resulting array has at least three pages.
    let ArrayCount = 100
    let PageSize = 10
    let StartPageIndex = 10
    
    var pagedArray: PagedArray<Int>!
    
    var firstPage: [Int]!
    var secondPage: [Int]!
    
    override func setUp() {
        super.setUp()
        
        pagedArray = PagedArray(count: ArrayCount/2, pageSize: PageSize, startPage: StartPageIndex)

        // Fill up two pages
        firstPage = Array(1...PageSize)
        secondPage = Array(PageSize+1...PageSize*2)
        
        pagedArray.set(firstPage, forPage: StartPageIndex)
        pagedArray.set(secondPage, forPage: StartPageIndex+1)
        
        pagedArray.count = ArrayCount
    }

    
    // MARK: Tests
    
    func testSizeIsCorrect() {
        XCTAssertEqual(pagedArray.count, ArrayCount, "Paged array has wrong size")
        XCTAssertEqual(Array(pagedArray).count, ArrayCount, "Paged array elements has wrong size")
    }
    
    func testGeneratorWorks() {
        let generatedArray = Array(pagedArray.makeIterator())

        XCTAssertEqual(generatedArray.count, ArrayCount, "Generated array has wrong count")
        XCTAssertEqual(generatedArray[0], firstPage[0], "Generated array has wrong content")
    }
    
    func testSubscriptingWorksForAllValidIndexesWithoutHittingAssertions() {
        for i in pagedArray.startIndex..<pagedArray.endIndex {
            let _ = pagedArray[i]
        }
    }
    
    func testCanReplaceValuesUsingSubscript() {
        pagedArray[0] = 666
        XCTAssertEqual(pagedArray[0], 666)
    }
    
    func testCanSetLastPageWithUnevenSize() {
        let elements = Array(1...pagedArray.size(for: pagedArray.lastPage))
        pagedArray.set(elements, forPage: pagedArray.lastPage)
    }
    
    func testChangingCountChangesLastPageIndexesRange() {
        let originalIndexes = pagedArray.indexes(for: pagedArray.lastPage)
        pagedArray.count += 1
        let newIndexes = pagedArray.indexes(for: pagedArray.lastPage)
        
        XCTAssertNotEqual(originalIndexes, newIndexes, "Indexes for last page did not change even though total count changed")
    }
    
    func testChangingCountChangesLastPageIndex() {
        let originalLastPageIndex = pagedArray.lastPage
        pagedArray.count += PageSize
        
        XCTAssertEqual(pagedArray.lastPage, originalLastPageIndex+1, "Number of pages did not change after total count was increased with one page size")
    }
    
    func testReturnsNilForIndexCorrespondingToPageNotYetSet() {
        if pagedArray[PageSize*2] != nil {
            XCTAssert(false, "Paged array should return nil for index belonging to a page not yet set")
        }
    }
    
    func testLoadedElementsEqualToCombinedPages() {
        XCTAssertEqual(pagedArray.loadedElements, firstPage + secondPage, "Loaded pages doesn't match set pages")
    }
    
    func testContainsCorrectAmountOfRealValues() {
        let valuesCount = pagedArray.filter{ $0 != nil }.count
        XCTAssertEqual(valuesCount, PageSize*2, "Incorrect count of real values inside paged array")
    }
    
    func testIndexRangeWorksForFirstPage() {
        XCTAssertEqual(pagedArray.indexes(for: StartPageIndex), (0..<PageSize), "Incorrect range for page")
    }
    
    func testIndexRangeWorksForSecondPage() {
        XCTAssertEqual(pagedArray.indexes(for: StartPageIndex+1), (PageSize..<PageSize*2), "Incorrect range for page")
    }
    
    func testIndexRangeWorksForLastPage() {
        XCTAssertEqual(pagedArray.indexes(for: pagedArray.lastPage), (PageSize*(calculatedLastPageIndex()-StartPageIndex)..<ArrayCount), "Incorrect range for page")
    }
    
    func testRemovePageRemovesPage() {
        let page = StartPageIndex+2
        pagedArray.remove(page)
        for index in pagedArray.indexes(for: page) {
            if pagedArray[index] != nil {
                XCTAssert(false, "Paged array should return nil for index belonging to a removed page")
            }
        }
    }
    
    func testRemoveAllPagesRemovesAllLoadedElements() {
        pagedArray.removeAllPages()
        XCTAssertEqual(pagedArray.loadedElements.count, 0, "RemoveAllPages should remove all loaded elements")
    }
    
    func testLastPageIndexImplementation() {
        XCTAssertEqual(pagedArray.lastPage, calculatedLastPageIndex(), "Incorrect index for last page")
    }
    
    func testSettingEmptyElementsOnZeroCountArray() {
        var emptyArray: PagedArray<Int> = PagedArray(count: 0, pageSize: 10)
        emptyArray.set(Array(), forPage: 0)
    }
    
    
    // MARK: High Chaparall Mode tests
    
    func testAddingExtraElementInLastPageUpdatesCountInHighChaparallMode() {
        
        pagedArray.updatesCountWhenSettingPages = true // YEE-HAW
        
        let lastPageSize = pagedArray.size(for: pagedArray.lastPage)+1 // Simulate finding an extra element from the API
        let lastPage = Array(1...lastPageSize)
        
        pagedArray.set(lastPage, forPage: pagedArray.lastPage)
        
        XCTAssertEqual(pagedArray.count, ArrayCount+1, "Count did not increase when setting a bigger page than expected")
    }
    
    func testCountIsChangedByAddingExtraPageInHighChaparallMode() {
        
        pagedArray.updatesCountWhenSettingPages = true // YEE-HAW
        
        let extraPage = Array(1...PageSize)
        
        pagedArray.set(extraPage, forPage: pagedArray.lastPage+2)
        
        var expectedSize = ArrayCount+PageSize*2
        if ArrayCount%PageSize > 0 {
            expectedSize += PageSize-ArrayCount%PageSize
        }
        
        
        XCTAssertEqual(pagedArray.count, expectedSize, "Count did not update when adding extra pages")
    }
    
    func testSettingPageWithLowerSizeUpdatesCountInHighChaparallMode() {
        
        pagedArray.updatesCountWhenSettingPages = true // YEE-HAW
        
        pagedArray.set([0], forPage: StartPageIndex)
        XCTAssertEqual(pagedArray.count, ArrayCount-PageSize+1, "Count did not update when setting a page with lower length than expected")
    }
    
    // MARK: Utility
    fileprivate func calculatedLastPageIndex() -> Int {
        if ArrayCount%PageSize == 0 {
            return ArrayCount/PageSize+StartPageIndex-1
        } else {
            return ArrayCount/PageSize+StartPageIndex
        }
    }
    
}

private extension PagedArray {
    func size(for page: PageIndex) -> Int {
        let indexes = self.indexes(for: page)
        return indexes.endIndex-indexes.startIndex
    }
}

