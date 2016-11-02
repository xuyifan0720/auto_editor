//
//  ViewController.swift
//  Softimage
//
//  Created by Yifan Xu on 10/10/16.
//  Copyright © 2016 Yifan Xu. All rights reserved.
//

import Cocoa

extension NSImage {
    var imageJPGRepresentation: NSData {
        return NSBitmapImageRep(data: tiffRepresentation!)!.representation(using: NSBitmapImageFileType.JPEG, properties: [:])! as NSData
    }
    func saveJPG(path:String) -> Bool {
        return imageJPGRepresentation.write(toFile: path, atomically: true)
    }
}

class ViewController: NSViewController {

    @IBOutlet weak var source: NSTextField! // it can be a folder or an image
    
    @IBOutlet weak var target: NSTextField! // it must be a folder
    
    @IBOutlet weak var brightness: NSTextField!
    
    @IBOutlet weak var before: NSImageView!
    
    @IBOutlet weak var after: NSImageView!
    
    @IBOutlet weak var blemish: NSButton!
    
    var picList = [String!]()

    @IBAction func selectTarget(_ sender: NSButton)
    {
        //it must be a folder!
        let myFileDialog: NSOpenPanel = NSOpenPanel()
        myFileDialog.allowsMultipleSelection=false
        myFileDialog.canChooseDirectories=true
        myFileDialog.canChooseFiles=false
        
        myFileDialog.runModal()
        
        // Get the path to the file chosen in the NSOpenPanel
        let path = myFileDialog.url?.path
        
        // Make sure that a path was chosen
        if (path != nil)
        {
            let fileManager = FileManager.default
            var isDir : ObjCBool = false
            if fileManager.fileExists(atPath: path!, isDirectory:&isDir)
            {
                if isDir.boolValue
                {
                    target.stringValue="\(path!)"
                }
            }
        }

    }
    @IBAction func selectSource(_ sender: NSButton) {
        let myFileDialog: NSOpenPanel = NSOpenPanel()
        myFileDialog.allowsMultipleSelection=false
        myFileDialog.canChooseDirectories=true
        myFileDialog.canChooseFiles=false

        myFileDialog.runModal()
        
        // Get the path to the file chosen in the NSOpenPanel
        let path = myFileDialog.url?.path
        
        // Make sure that a path was chosen
        if (path != nil)
        {
            let fileManager = FileManager.default
            var isDir : ObjCBool = false
            if fileManager.fileExists(atPath: path!, isDirectory:&isDir)
            {
                if isDir.boolValue {
                    source.stringValue="\(path!)"
                    if isFolderWithPictureSafe(path!)
                    {
                        picList = [String]()
                        startButton.isEnabled=true
                        exitButton.isEnabled=false
                        do
                        {
                            picList = try fileManager.contentsOfDirectory(atPath: path!)
                            picList = picList.filter{isPictureSafe($0)}
                        }
                        catch{print("file error")}
                    }
                    else
                    {
                        startButton.isEnabled=false
                        exitButton.isEnabled=false
                    }
                }
                else
                {
                    source.stringValue="\(path!)"
                    if isPictureSafe(path!)
                    {
                        //picList = [String]()
                        startButton.isEnabled=true
                        exitButton.isEnabled=false
                        self.picList.append(path!)
                    }
                    else
                    {
                        startButton.isEnabled=false
                        exitButton.isEnabled=false
                    }
                }
            }
            else
            {
                startButton.isEnabled=false
                exitButton.isEnabled=false
            }
        }
    }
    @IBOutlet weak var startButton: NSButton!
    
    @IBOutlet weak var exitButton: NSButton!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        startButton.isEnabled=false
        exitButton.isEnabled=false
        // Do any additional setup after loading the view.
    }

    override var representedObject: Any?
    {
        didSet
        {
        // Update the view, if already loaded.
        }
    }
    
    func verifyBrightness()->Int{
        let brightString = self.brightness.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        if brightString != ""{
            if let brightvalue = Int(brightString){
                return brightvalue
            }else{
                return -1
            }
            
        }else{
            return -1
        }

    }
    
    func popUpWarning(message msgText:String, information informativeText:String){
        let myPopup: NSAlert = NSAlert()
        myPopup.messageText = msgText
        myPopup.informativeText = informativeText
        myPopup.alertStyle = NSAlertStyle.warning
        myPopup.addButton(withTitle: "OK")
        myPopup.runModal()
    }
    
    @IBAction func process(_ sender: NSButton)
    {
        exitButton.isEnabled = true
        startButton.isEnabled = false
        let destinationFolder = verifyDestinationFolder()
        
        if destinationFolder == nil{
            popUpWarning(message: "Destination Folder is wrong!", information: "Destination Folder can't be empty")
            return
        }
        
        let brightvalue = verifyBrightness()
        if brightvalue == -1{
            popUpWarning(message: "Brightness may have wrong value", information: "Brightness should be integer value!")
            return
        }
        
        
            let queue = DispatchQueue.global()
            let main = DispatchQueue.main
            queue.async
            {
                while (self.picList.count != 0 && self.picList[0] != nil)
                {
                    let file = self.picList[0]!
                    //NSLog(self.source.stringValue+"/"+file)
                    let image = NSImage(contentsOfFile:self.source.stringValue+"/"+file)
                    main.async
                        {
                            self.before.image = image
                    }
                    
                    let processed = OpenCV.adjust(image, brightness: Int32(brightvalue), blemish: self.blemish.state == 1)
                    main.async
                    {
                            self.after.image = processed
                    }
                    if let targetFileName = destinationFolder?.appendingPathComponent("Update-"+file, isDirectory: false) {
                        NSLog("file name: \(targetFileName)")
                        if !processed!.saveJPG(path: targetFileName.path)
                        {
                            NSLog("failed saving")
                        }
                        
                    }

                    
                    /*
                    if let bits = processed?.representations.first as? NSBitmapImageRep
                    {
                        let data = bits.representation(using: .JPEG, properties: [:])
                        let updatedPath = self.target.stringValue + "/Updated_" + file
                       // NSLog(updatedPath)
                        let url = URL(string: updatedPath)
                        NSLog("\(url!)")
                        do
                        {
                            //try data?.write(to: url as! URL)
                            try data!.write(to: url!)
                        }catch{print("error saving")}
                    }*/
                    self.picList.remove(at:0)
                }
            }
    }
    
    
    @IBAction func stop(_ sender: NSButton)
    {
        startButton.isEnabled = true
        exitButton.isEnabled = false
        var first : String!
        if picList.count != 0
        {
            first = picList[0]
            picList = [String]()
            picList.append(first)
        }
        else
        {
            picList = [String]()
        }
        before.image = nil
        after.image = nil
    }
    
    func verifyDestinationFolder()->NSURL?{
        var destinationFolder:NSURL? = nil
        let dstFolderText = target.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        if dstFolderText == ""{
            let myPopup: NSAlert = NSAlert()
            myPopup.messageText = "Target Folder"
            myPopup.informativeText = "target folder can't be empty!"
            myPopup.alertStyle = NSAlertStyle.warning
            myPopup.addButton(withTitle: "OK")
            myPopup.runModal()
            return nil
        }
        
        let fileManager = FileManager.default
        var isDir : ObjCBool = false
        
        if fileManager.fileExists(atPath: dstFolderText, isDirectory:&isDir) {
            if isDir.boolValue {
                destinationFolder = NSURL(fileURLWithPath: dstFolderText, isDirectory: true)
            }
        }else{
            do{
                try fileManager.createDirectory(atPath: dstFolderText, withIntermediateDirectories: true, attributes: nil)
                destinationFolder = NSURL(fileURLWithPath: dstFolderText, isDirectory: true)
            }catch let error as NSError {
                NSLog("Unable to create directory \(error.debugDescription)")
                destinationFolder = nil
            }
        }
        
        if destinationFolder == nil{
            let myPopup: NSAlert = NSAlert()
            myPopup.messageText = "Target Folder"
            myPopup.informativeText = "Target folder can't be found or created!"
            myPopup.alertStyle = NSAlertStyle.warning
            myPopup.addButton(withTitle: "OK")
            myPopup.runModal()
            
            return nil
        }
        
        return destinationFolder
    }

    
    func isFolderWithPictureUnsafe(_ atPath:String)->Bool
    {
        //atPath may not exist or may be a file
        //so, it needs a safe check
        let fileManager = FileManager.default
        var isDir:ObjCBool = false
        if fileManager.fileExists(atPath: atPath, isDirectory: &isDir)
        {
            if isDir.boolValue
            {
                return isFolderWithPictureSafe(atPath)
            }
        }
        return false
    }

    func isFolderWithPictureSafe(_ atPath:String)->Bool{
        //assume path exist and is a folder
        //doesn't need to check again.
        let fileManager=FileManager.default
        do{
            let filelist = try fileManager.contentsOfDirectory(atPath: atPath)
            for filename in filelist
            {
                if isPictureSafe(filename)
                {
                    return true
                }
            }
        }catch{return false}
        return false
    }
    
    func isPictureSafe(_ atPath:String)->Bool
    {
        //atPath has been confirmed is a file.
        //so, it doesn't need to check exists or not again.
        if atPath.hasSuffix("jpg") || atPath.hasSuffix("JPG") || atPath.hasSuffix("JPEG")||atPath.hasSuffix("jpeg")
        {
            return true
        }
        return false
    }
    
    func isPictureUnsafe(_ atPath:String)->Bool
    {
        //atPath may be an unchecked path or file name. 
        //so, it needs a recheck
        let fileManager = FileManager.default
        var isDir:ObjCBool = false
        if fileManager.fileExists(atPath: atPath, isDirectory: &isDir)
        {
            if isDir.boolValue{
                return false
            }
            else
            {
                return isPictureSafe(atPath)
            }
        }
        return false
    }
}

