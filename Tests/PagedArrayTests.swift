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
    
    let ArrayCount = 100
    let PageSize = 15
    let StartPage = 1
    
    var pagedArray: PagedArray<Int>!
    
    var firstPage: [Int]!
    var secondPage: [Int]!
    
    override func setUp() {
        super.setUp()
        
        pagedArray = PagedArray(count: ArrayCount, pageSize: PageSize, startPage: StartPage)

        // Fill up two pages
        firstPage = Array(1...PageSize)
        secondPage = Array(PageSize+1...PageSize*2)
        
        pagedArray.setElements(firstPage, page: StartPage)
        pagedArray.setElements(secondPage, page: StartPage+1)
    }
    
    // MARK: Tests
    func testSizeIsCorrect() {
        XCTAssertEqual(pagedArray.count, ArrayCount, "Paged array has wrong size")
        XCTAssertEqual(Array(pagedArray).count, ArrayCount, "Paged array elements has wrong size")
    }
    
    func testGeneratorWorks() {
        let generatedArray = Array(pagedArray.generate())

        XCTAssertEqual(generatedArray.count, ArrayCount, "Generated array has wrong count")
        XCTAssertEqual(generatedArray[0]!, firstPage[0], "Generated array has wrong content")
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
        XCTAssertEqual(pagedArray.indexesForPage(StartPage), (0..<PageSize), "Incorrect range for page")
    }
    
    func testIndexRangeWorksForSecondPage() {
        XCTAssertEqual(pagedArray.indexesForPage(StartPage+1), (PageSize..<PageSize*2), "Incorrect range for page")
    }
    
    func testIndexRangeWorksForLastPage() {
        XCTAssertEqual(pagedArray.indexesForPage(pagedArray.lastPage), (PageSize*(ArrayCount/PageSize)..<ArrayCount), "Incorrect range for page")
    }
    
    func testRemovePageRemovesPage() {
        let page = 2
        pagedArray.removePage(page)
        for index in pagedArray.indexesForPage(page) {
            if pagedArray[index] != nil {
                XCTAssert(false, "Paged array should return nil for index belonging to a removed page")
            }
        }
    }
    
    func testRemoveAllPagesRemovesAllLoadedElements() {
        pagedArray.removeAllPages()
        XCTAssertEqual(pagedArray.loadedElements.count, 0, "RemoveAllPages should remove all loaded elements")
    }
    
    func testGetLastPageNumberExactCountPageSizeDivision() {
        var tinyArray: PagedArray<Int> = PagedArray(count: 30, pageSize: 10)
        XCTAssertEqual(tinyArray.lastPage, 2)
    }
    
    func testGetLastPageNumberExactCountPageSizeDivisionWithStartingPage1() {
        var tinyArray: PagedArray<Int> = PagedArray(count: 30, pageSize: 10, startPage: 1)
        XCTAssertEqual(tinyArray.lastPage, 3)
    }
    
    func testGetLastPageNumberExactCountPageSizeDivisionWithStartingPage10() {
        var tinyArray: PagedArray<Int> = PagedArray(count: 30, pageSize: 10, startPage: 10)
        XCTAssertEqual(tinyArray.lastPage, 12)
    }
    
    func testGetLastPageNumberNotExactCountPageSizeDivision() {
        var tinyArray: PagedArray<Int> = PagedArray(count: 100, pageSize: 15)
        XCTAssertEqual(tinyArray.lastPage, 6)
    }
    
    func testGetLastPageNumberNotExactCountPageSizeDivisionStartingPage1() {
        var tinyArray: PagedArray<Int> = PagedArray(count: 100, pageSize: 15, startPage: 1)
        XCTAssertEqual(tinyArray.lastPage, 7)
    }
    
    func testGetLastPageNumberNotExactCountPageSizeDivisionStartingPage10() {
        var tinyArray: PagedArray<Int> = PagedArray(count: 100, pageSize: 15, startPage: 10)
        XCTAssertEqual(tinyArray.lastPage, 16)
    }
}
