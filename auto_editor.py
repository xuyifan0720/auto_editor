#!/usr/bin/python
import numpy as np
import cv2
import os
from PIL import Image, ImageStat
import math
import argparse

class PhotoEditor:
    def __init__(self, directory_name, destination, brightness,blur):
        self.img = None
        self.imageFile = None
        self.directory = directory_name
        self.destination = destination
        self.brightness = int(brightness)
        self.index = 1
        self.blur = blur
        self.contrastConstant = 0

    def maskCreation(self, img):
        # converting to gray scale
        gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
        hsv = cv2.cvtColor(img, cv2.COLOR_BGR2HSV)
        ycrcb = cv2.cvtColor(img, cv2.COLOR_BGR2YCR_CB)
        lower = np.array([130, 130, 70], dtype = "uint8")
        upper = np.array([255, 175, 135], dtype = "uint8")
        #masks ppl's face skin
        mask = cv2.inRange(ycrcb, lower, upper)
        lowerhsv = np.array([7, 90, 100], dtype="uint8")
        upperhsv = np.array([14, 255, 255], dtype="uint8")
        #masks ppl's face skin
        hsv = cv2.GaussianBlur(hsv,(3,3),0)
        mask2 = cv2.inRange(hsv, lowerhsv, upperhsv)
        mask += mask2
        # remove noise
        img2 = cv2.GaussianBlur(gray,(3,3),0)
        #laplacian detects the edges
        laplacian = cv2.Laplacian(img2,cv2.CV_64F,ksize=1,scale=0.02,delta=0)
        #adds laplacian and mask you get edges on people's face
        finalMask = cv2.bitwise_and(laplacian,laplacian,mask=mask)
        #makes a new mask according to finalMask
        for i in range(0,len(finalMask)):
            for j in range(0,len(finalMask[0])):
                if finalMask[i,j]<0.05:
                    mask[i,j]=0
                else:
                    mask[i,j]=255
                #if img[i,j,0]+img[i,j,1]+img[i,j,2]>300 and img[i,j,0]+img[i,j,1]+img[i,j,2]<350:
                    #mask[i,j]=0
        mask = cv2.GaussianBlur(mask,(5,5),0)
        return mask

    def saveImg(self,img):
        rand = self.index
        self.index = self.index + 1
        fileName = self.destination+"/Updated-"+os.path.basename(self.imageFile)+".jpg"
        cv2.imwrite(fileName, img)

    def pimpleRemoval(self,mask,img):
        # blurs out the image
        image = cv2.medianBlur(img, 17)
        img1 = cv2.bitwise_and(image,image,mask=mask)
        img2 = cv2.bitwise_and(img,img,mask=mask)
        img2 = img-img2
        final = img1+img2
        return final

    def adjust_gamma(self, image, gamma):
        # build a lookup table mapping the pixel values [0, 255] to
        # their adjusted gamma values
        invGamma = 1.0 / gamma
        table = np.array([((i / 255.0) ** invGamma) * 255
            for i in np.arange(0, 256)]).astype("uint8")
        # apply gamma correction using the lookup table
        return cv2.LUT(image, table)

    def contrast_adjustment(self,image,constant):
        # similar to adjust_gamma
        table1 = np.array([0.5**(1-constant)*(i/255.0)**constant*255 for i in np.arange(0,128)]).astype("uint8")
        table2 = np.array([-0.5**(1-constant)*(1-i/255.0)**constant*255+255 for i in np.arange(128,256)]).astype("uint8")
        table = np.append(table1,table2)
        return cv2.LUT(image,table)

    def adjust(self):
        result = self.img
        for i in range(0,5):
            currentBright = self.calcBrightness(result)
            print("currentBright")
            print(currentBright)
            targetDiff = self.brightness-currentBright
            adjust_constant = (targetDiff)*0.01+1
            print("adjust_constant")
            print(adjust_constant)
            result = self.adjust_gamma(result,adjust_constant)
        print("first round of process done")
        oldBright = self.calcBrightness(self.img)
        newBright = self.calcBrightness(result)
        constant = (newBright/oldBright)
        #result = self.saturation_adjust(result,constant)
        print("saturation done")
        if self.blur == "yes":
            mask = self.maskCreation(self.img)
            print("mask creation done")
            result = self.pimpleRemoval(mask,result)
        result = self.contrast_adjustment(result,constant**1.1)
        self.saveImg(result)

    def testLimit(self,n):
        if n > 255:
            return 255
        else:
            return n
    def saturation_adjust(self,img,constant):
        hsv = cv2.cvtColor(img,cv2.COLOR_BGR2HSV)
        hsv[:,:,1] = [self.testLimit(x*constant) for x in hsv[:,:,1]]
        return cv2.cvtColor(hsv,cv2.COLOR_HSV2BGR)

    def calcBrightness(self,img):
        cv2_im = cv2.cvtColor(img,cv2.COLOR_BGR2RGB)
        pil_im = Image.fromarray(cv2_im)
        stat = ImageStat.Stat(pil_im)
        r,g,b = stat.rms
        print("r is %f g is %f b is %f")%(r,g,b)
        currentBright = math.sqrt(0.241*(r**2) + 0.691*(g**2) + 0.068*(b**2))
        return currentBright

    def blemishFix(self):
        mask = self.maskCreation
        removed = self.pimpleRemoval(mask)
        self.saveImg(removed)

    def loop(self):
        for files in os.walk(self.directory):
            for pic in files:
                for pics in pic:
                    if pics.endswith(".jpg") or pics.endswith(".JPG"):
                        print("start processing")
                        print(pics)
                        pics = self.directory+"/"+pics
                        self.imageFile = pics
                        self.img = cv2.imread(pics)
                        self.adjust()

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Arguments for auto editor')
    parser.add_argument('-s', action="store", dest="storage", required=True,
                        help="path where you store your source pictures.")
    parser.add_argument('-d', action="store", dest="destination", required=True,
                        help="destination path where you store your updated pictures.")
    parser.add_argument('-f', action="store", dest="brightness", required=True,
                        help="desired brightness.")
    parser.add_argument('-g', action="store", dest="blur", required=False, default = "yes",
                        help="yes or no whether you want to do blemish adjust.")
    args = parser.parse_args()

    if not os.path.exists(args.storage):
        print("Source storage folder doesn't exist!")
        exit()

    if not os.path.exists(args.destination):
        os.mkdir(args.destination)

    editor = PhotoEditor(args.storage, args.destination,args.brightness,args.blur)
    editor.loop()
