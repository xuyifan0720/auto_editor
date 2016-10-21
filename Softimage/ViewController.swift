//
//  ViewController.swift
//  Softimage
//
//  Created by Yifan Xu on 10/10/16.
//  Copyright © 2016 Yifan Xu. All rights reserved.
//

import Cocoa



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
        myFileDialog.canChooseFiles=true

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
                        picList = [String]()
                        startButton.isEnabled=true
                        exitButton.isEnabled=false
                        picList.append(path!)
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
    

    @IBAction func process(_ sender: NSButton)
    {
        exitButton.isEnabled = true
        startButton.isEnabled = false
            let queue = DispatchQueue.global()
            let main = DispatchQueue.main
            queue.async
            {
                while (self.picList.count != 0 && self.picList[0] != nil)
                {
                    let file = self.picList[0]!
                    NSLog(self.source.stringValue+"/"+file)
                    let image = NSImage(contentsOfFile:self.source.stringValue+"/"+file)
                    main.async
                        {
                            self.before.image = image
                    }
                    let brightvalue = Int(self.brightness.stringValue)!
                    let processed = OpenCV.adjust(image, brightness: Int32(brightvalue), blemish: self.blemish.state == 1)
                    main.async
                        {
                            self.after.image = processed
                    }
                    if let bits = processed?.representations.first as? NSBitmapImageRep
                    {
                        let data = bits.representation(using: .JPEG, properties: [:])
                        let updatedPath = self.target.stringValue + "/Updated_" + file
                        NSLog(updatedPath)
                        let url = NSURL(string: updatedPath)
                        NSLog("\(url)")
                        do
                        {
                            try data?.write(to: url as! URL)
                        }catch{print("error saving")}
                    }
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
                if !isPictureSafe(filename)
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

