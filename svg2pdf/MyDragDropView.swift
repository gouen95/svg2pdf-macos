//
//  MyDragDropView.swift
//  svg2pdf
//
//  Created by Brandon on 27/01/2024.
//

import Cocoa

protocol MyDragDropViewDelegate: AnyObject {
    func myDragDrop(view: MyDragDropView, didReceive urls: [URL])
}

class MyDragDropView: NSView {
    
    weak var delegate: MyDragDropViewDelegate?
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        // Enable dragging
        registerForDraggedTypes([.fileURL])
    }
    
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        // Highlight the view when dragging starts
        self.layer?.borderWidth = 2
        self.layer?.borderColor = NSColor.secondaryLabelColor.cgColor
        return .copy
    }
    
    override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        // Update drag operation (copy, move, etc.)
        return .copy
    }
    
    override func draggingExited(_ sender: NSDraggingInfo?) {
        // Remove highlight when dragging exits
        self.layer?.borderWidth = 0
    }
    
    override func draggingEnded(_ sender: NSDraggingInfo) {
        self.layer?.borderWidth = 0
    }
    
    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        // Handle the dropped files
        if let urls = sender.draggingPasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL],
           !urls.isEmpty {
            self.delegate?.myDragDrop(view: self, didReceive: urls)
            return true
        }
        return false
    }
}
