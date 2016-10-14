//
//  ViewController.swift
//  Softimage
//
//  Created by Desheng Xu on 10/10/16.
//  Copyright © 2016 Desheng Xu. All rights reserved.
//

import Cocoa


class ViewController: NSViewController {

    @IBOutlet weak var source: NSTextField! // it can be a folder or an image
    
    @IBOutlet weak var target: NSTextField! // it must be a folder
    
    @IBAction func selectTarget(_ sender: NSButton) {
        //it must be a folder!
        let myFileDialog: NSOpenPanel = NSOpenPanel()
        myFileDialog.allowsMultipleSelection=false
        myFileDialog.canChooseDirectories=true
        myFileDialog.canChooseFiles=false
        
        myFileDialog.runModal()
        
        // Get the path to the file chosen in the NSOpenPanel
        let path = myFileDialog.url?.path
        
        // Make sure that a path was chosen
        if (path != nil) {
            let fileManager = FileManager.default
            var isDir : ObjCBool = false
            if fileManager.fileExists(atPath: path!, isDirectory:&isDir) {
                if isDir.boolValue {
                    NSLog("it's a folder!\(path)")
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
        if (path != nil) {
            let fileManager = FileManager.default
            var isDir : ObjCBool = false
            if fileManager.fileExists(atPath: path!, isDirectory:&isDir) {
                if isDir.boolValue {
                    NSLog("it's a folder!\(path)")
                    source.stringValue="\(path!)"
                    if isFolderWithPictureSafe(path!){
                        startButton.isEnabled=true
                        exitButton.isEnabled=false
                    }else{
                        startButton.isEnabled=false
                        exitButton.isEnabled=false
                    }
                    
                } else {
                    NSLog("It's a file:\(path)")
                    source.stringValue="\(path!)"
                    if isPictureSafe(path!){
                        startButton.isEnabled=true
                        exitButton.isEnabled=false
                    }else{
                        startButton.isEnabled=false
                        exitButton.isEnabled=false
                    }
                }
            }else{
                startButton.isEnabled=false
                exitButton.isEnabled=false
            }
        }
    }
    @IBOutlet weak var startButton: NSButton!
    
    @IBOutlet weak var exitButton: NSButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        startButton.isEnabled=false
        exitButton.isEnabled=false
        // Do any additional setup after loading the view.
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    func isFolderWithPictureUnsafe(_ atPath:String)->Bool{
        //atPath may not exist or may be a file
        //so, it needs a safe check
        let fileManager = FileManager.default
            var isDir:ObjCBool = false
            if fileManager.fileExists(atPath: atPath, isDirectory: &isDir){
                if isDir.boolValue{
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
            for filename in filelist{
                if isPictureSafe(filename){
                    return true
                }
            }
        }catch{return false}
        return false
    }
    
    func isPictureSafe(_ atPath:String)->Bool{
        //atPath has been confirmed is a file.
        //so, it doesn't need to check exists or not again.
        if atPath.hasSuffix("jpg") || atPath.hasSuffix("JPG") || atPath.hasSuffix("JPEG")||atPath.hasSuffix("jpeg"){
            return true
        }
        return false
    }
    
    func isPictureUnsafe(_ atPath:String)->Bool{
        //atPath may be an unchecked path or file name. 
        //so, it needs a recheck
        let fileManager = FileManager.default
        var isDir:ObjCBool = false
        if fileManager.fileExists(atPath: atPath, isDirectory: &isDir){
            if isDir.boolValue{
                return false
            }else{
                return isPictureSafe(atPath)
            }
        }
        return false
    }

}

