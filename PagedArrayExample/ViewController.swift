//
// ViewController.swift
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

import UIKit
import PagedArray

// Tweak these values and see how the user experience is affected
let PreloadMargin = 10 /// How many rows "in front" should be loaded
let PageSize = 25 /// Paging size
let DataLoadingOperationDuration = 0.5 /// Simulated network operation duration
let TotalCount = 200 /// Number of rows in table view


class ViewController: UITableViewController {

    let cellIdentifier = "Cell"
    let operationQueue = NSOperationQueue()
    
    var pagedArray = PagedArray<String>(count: TotalCount, pageSize: PageSize)
    var dataLoadingOperations = [Int: NSOperation]()
    var shouldPreload = true
    
    // MARK: User actions
    
    @IBAction func clearDataPressed() {
        dataLoadingOperations.removeAll(keepCapacity: true)
        operationQueue.cancelAllOperations()
        pagedArray.removeAllPages()
        tableView.reloadData()
    }
    
    @IBAction func preLoadingSwitchChanged(sender: UISwitch) {
        shouldPreload = sender.on
    }
    
    // MARK: Private functions
    
    private func configureCell(cell: UITableViewCell, data: String?) {
        if let data = data {
            cell.textLabel?.text = data
        } else {
            cell.textLabel?.text = " "
        }
    }
    
    private func loadDataIfNeededForRow(row: Int) {
        
        let currentPage = pagedArray.pageNumberForIndex(row)
        if needsLoadDataForPage(currentPage) {
            loadDataForPage(currentPage)
        }
        
        let preloadIndex = row+PreloadMargin
        if preloadIndex < pagedArray.endIndex && shouldPreload {
            let preloadPage = pagedArray.pageNumberForIndex(preloadIndex)
            if preloadPage > currentPage && needsLoadDataForPage(preloadPage) {
                loadDataForPage(preloadPage)
            }
        }
    }
    
    private func needsLoadDataForPage(page: Int) -> Bool {
        return pagedArray.pages[page] == nil && dataLoadingOperations[page] == nil
    }
    
    private func loadDataForPage(page: Int) {
        let indexes = pagedArray.indexesForPage(page)

        // Create loading operation
        let operation = DataLoadingOperation(indexesToLoad: indexes) { [unowned self] indexes, data in
            
            // Set elements on paged array
            self.pagedArray.setElements(data, page: page)
            
            // Loop through and update visible rows that got new data
            for row in self.visibleRowsForIndexes(indexes) {
                self.configureCell(self.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: row, inSection: 0))!, data: self.pagedArray[row])
            }
            
            self.dataLoadingOperations[page] = nil
        }

        // Add operation to queue and save it
        operationQueue.addOperation(operation)
        dataLoadingOperations[page] = operation
    }
    
    private func visibleRowsForIndexes(indexes: Range<Int>) -> [Int] {
        let visiblePaths = self.tableView.indexPathsForVisibleRows() as! [NSIndexPath]
        let visibleRows = visiblePaths.map { $0.row }
        return visibleRows.filter { find(indexes, $0) != nil }
    }
    
}

// MARK: Table view datasource
extension ViewController {
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return pagedArray.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        loadDataIfNeededForRow(indexPath.row)

        let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier) as! UITableViewCell
        configureCell(cell, data: pagedArray[indexPath.row])
        return cell
    }
    
}


/// Test operation that produces nonsense numbers as data
class DataLoadingOperation: NSBlockOperation {
    
    init(indexesToLoad: Range<Int>, completion: (indexes: Range<Int>, data: [String]) -> Void) {
        super.init()
        
        println("Loading indexes: \(indexesToLoad)")
        
        addExecutionBlock {
            // Simulate loading
            NSThread.sleepForTimeInterval(DataLoadingOperationDuration)
        }
        
        completionBlock = {
            let data = indexesToLoad.map { "Content data \($0)" }
            
            NSOperationQueue.mainQueue().addOperationWithBlock {
                completion(indexes: indexesToLoad, data: data)
            }
        }
    }
    
}
