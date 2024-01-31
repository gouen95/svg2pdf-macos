//
//  ViewController.swift
//  svg2pdf
//
//  Created by Brandon on 27/01/2024.
//

import Cocoa
import SVGKit

class UserDefaultHelper {
    static let shared: UserDefaultHelper = UserDefaultHelper()
    static let kWidth: String = "svg2pdfWidth"
    static let kHeight: String = "svg2pdfHeight"
    static let kPath: String = "svg2pdfPath"
    
    let userDefaults = UserDefaults.standard
    
    subscript(key: String) -> Any? {
        get {
            return userDefaults.value(forKey: key)
        }
        set {
            userDefaults.set(newValue, forKey: key)
        }
    }
}

class ViewController: NSViewController {

    @IBOutlet weak var txtWidth: NSTextField!
    @IBOutlet weak var txtHeight: NSTextField!
    @IBOutlet weak var myDragDropView: MyDragDropView!
    @IBOutlet weak var btnPath: NSButton!
    @IBOutlet weak var txtPath: NSTextField!
    
    private let helper = UserDefaultHelper.shared
    private var didChoosePath: Bool = false
    
    // MARK: - Lifecycles
    override func viewDidLoad() {
        super.viewDidLoad()

        myDragDropView.delegate = self
        
        txtWidth.delegate = self
        txtHeight.delegate = self
        
        txtWidth.stringValue = "\((helper[UserDefaultHelper.kWidth] as? CGFloat) ?? 0)"
        txtHeight.stringValue = "\((helper[UserDefaultHelper.kHeight] as? CGFloat) ?? 0)"
        if let path = helper[UserDefaultHelper.kPath] as? String {
            txtPath.stringValue = path
            btnPath.title = "Change"
        } else {
            btnPath.title = "Select"
        }
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        self.choosePath()
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    // MARK: - IBActions
    @IBAction func actPath(_ sender: Any) {
        self.choosePath()
    }
    
    func choosePath() {
        let openPanel = NSOpenPanel()
        openPanel.title = "Choose Folder"
        openPanel.canChooseFiles = false
        openPanel.canChooseDirectories = true
        openPanel.canCreateDirectories = true
        openPanel.allowsMultipleSelection = false
        
        openPanel.begin { [weak self] (result) in
            guard let self = self else { return }
            if result == .OK {
                if let directoryURL = openPanel.url {
                    helper[UserDefaultHelper.kPath] = directoryURL.absoluteString
                    txtPath.stringValue = directoryURL.absoluteString
                    btnPath.title = "Change"
                    didChoosePath = true
                }
            }
        }
    }
    
    func convertSVGToPDF(svgURL: URL) {
        let desiredWidth = CGFloat((txtWidth.stringValue as NSString).floatValue)
        let desiredHeight = CGFloat((txtHeight.stringValue as NSString).floatValue)
        
        guard let svgSource = SVGKSourceURL.source(from: svgURL) else {
            print("Error: Unable to create SVG source from URL.")
            return
        }

        guard let svgImage = SVGKImage(contentsOf: svgURL) else {
            print("Error: Unable to create SVG image from source.")
            return
        }

        let svgLayer = svgImage.caLayerTree
        var svgSize = svgLayer?.frame.size ?? .zero
        
        if desiredWidth > 0 && desiredHeight > 0 {
            svgSize = CGSizeMake(desiredWidth, desiredHeight)
        }

        let pdfData = NSMutableData()
        let pdfConsumer = CGDataConsumer(data: pdfData)!
        var mediaBox = CGRect(x: 0, y: 0, width: svgSize.width, height: svgSize.height)
        let pdfContext = CGContext(consumer: pdfConsumer, mediaBox: &mediaBox, nil)!

        pdfContext.beginPage(mediaBox: nil)

        // Scale the SVG image to fit the custom size
        let scale = min(svgSize.width / svgImage.size.width, svgSize.height / svgImage.size.height)
        pdfContext.scaleBy(x: scale, y: scale)
        
        svgLayer?.frame = mediaBox
        svgLayer?.render(in: pdfContext)

        pdfContext.endPage()
        pdfContext.closePDF()
        
        saveFile(pdfData: [pdfData])
    }
    
    func saveFile(pdfData: [NSMutableData]) {
        guard let pathUrl = URL(string: helper[UserDefaultHelper.kPath] as? String ?? "") else { return }
        
        do {
            for eachData in pdfData {
                let fileURL = pathUrl.appendingPathComponent("\(UUID().uuidString).pdf")
                try eachData.write(to: fileURL)
                print("File saved successfully at: \(fileURL)")
            }
        } catch let err {
            print(err)
        }

    }
}

extension ViewController: MyDragDropViewDelegate {
    func myDragDrop(view: MyDragDropView, didReceive urls: [URL]) {
        convertSVGToPDF(svgURL: urls.first!)
    }
}

extension ViewController: NSTextFieldDelegate {
    func controlTextDidChange(_ obj: Notification) {
        if let textField = obj.object as? NSTextField {
            if textField == self.txtWidth {
                let width = CGFloat((self.txtWidth.stringValue as NSString).floatValue)
                helper[UserDefaultHelper.kWidth] = width
            } else if textField == self.txtHeight {
                let height = CGFloat((self.txtHeight.stringValue as NSString).floatValue)
                helper[UserDefaultHelper.kHeight] = height
            }
        }
    }
}
