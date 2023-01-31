//
//  UIImage.swift
//  SocialApp
//
//  Created by Mahmudul Hasan on 2021-06-27.
//

import UIKit
import ImageIO

//https://github.com/kiritmodi2702/GIF-Swift/blob/master/GIF-Swift/iOSDevCenters%2BGIF.swift



// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}


extension UIImage {

    // FROM SO
    func alpha(_ value:CGFloat) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        draw(at: CGPoint.zero, blendMode: .normal, alpha: value)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage!
    }
    // SO
    
    public class func gifImageWithData(_ data: Data) -> UIImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            print("image doesn't exist")
            return nil
        }
        
        return UIImage.animatedImageWithSource(source)
    }

    public class func gifImageWithName(_ name: String) -> UIImage? {
        guard let bundleURL = Bundle.main
            .url(forResource: name, withExtension: "gif") else {
                print("SwiftGif: This image named \"\(name)\" does not exist")
                return nil
        }
        guard let imageData = try? Data(contentsOf: bundleURL) else {
            print("SwiftGif: Cannot turn image named \"\(name)\" into NSData")
            return nil
        }
        
        return gifImageWithData(imageData)
    }

    
    class func delayForImageAtIndex(_ index: Int, source: CGImageSource!) -> Double {
        var delay = 0.1
        
        let cfProperties = CGImageSourceCopyPropertiesAtIndex(source, index, nil)
        let gifProperties: CFDictionary = unsafeBitCast(
            CFDictionaryGetValue(cfProperties,
                Unmanaged.passUnretained(kCGImagePropertyGIFDictionary).toOpaque()),
            to: CFDictionary.self)
        
        var delayObject: AnyObject = unsafeBitCast(
            CFDictionaryGetValue(gifProperties,
                Unmanaged.passUnretained(kCGImagePropertyGIFUnclampedDelayTime).toOpaque()),
            to: AnyObject.self)
        if delayObject.doubleValue == 0 {
            delayObject = unsafeBitCast(CFDictionaryGetValue(gifProperties,
                Unmanaged.passUnretained(kCGImagePropertyGIFDelayTime).toOpaque()), to: AnyObject.self)
        }
        
        delay = delayObject as! Double
        
        if delay < 0.1 {
            delay = 0.1
        }
        
        return delay
    }
    
    class func gcdForPair(_ a: Int?, _ b: Int?) -> Int {
        var a = a
        var b = b
        if b == nil || a == nil {
            if b != nil {
                return b!
            } else if a != nil {
                return a!
            } else {
                return 0
            }
        }
        
        if a < b {
            let c = a
            a = b
            b = c
        }
        
        var rest: Int
        while true {
            rest = a! % b!
            
            if rest == 0 {
                return b!
            } else {
                a = b
                b = rest
            }
        }
    }
    
    class func gcdForArray(_ array: Array<Int>) -> Int {
        if array.isEmpty {
            return 1
        }
        
        var gcd = array[0]
        
        for val in array {
            gcd = UIImage.gcdForPair(val, gcd)
        }
        
        return gcd
    }
    
    class func animatedImageWithSource(_ source: CGImageSource) -> UIImage? {
            let count = CGImageSourceGetCount(source)
            var images = [CGImage]()
            var delays = [Int]()
            
            for i in 0..<count {
                if let image = CGImageSourceCreateImageAtIndex(source, i, nil) {
                    images.append(image)
                }
                
                let delaySeconds = UIImage.delayForImageAtIndex(Int(i),
                    source: source)
                delays.append(Int(delaySeconds * 1000.0)) // Seconds to ms
            }
            
            let duration: Int = {
                var sum = 0
                
                for val: Int in delays {
                    sum += val
                }
                
                return sum
            }()
            
            let gcd = gcdForArray(delays)
            var frames = [UIImage]()
            
            var frame: UIImage
            var frameCount: Int
            for i in 0..<count {
                frame = UIImage(cgImage: images[Int(i)])
                frameCount = Int(delays[Int(i)] / gcd)
                
                for _ in 0..<frameCount {
                    frames.append(frame)
                }
            }
            
            let animation = UIImage.animatedImage(with: frames,
                duration: Double(duration) / 1000.0)
            
            return animation
        }
    
    
    /*
       http://stackoverflow.com/questions/9061800/how-do-i-autocrop-a-uiimage/40780523#40780523
    */
    
    
    func trim() -> UIImage {
            let newRect = self.cropRect
            if let imageRef = self.cgImage!.cropping(to: newRect) {
                return UIImage(cgImage: imageRef)
            }
            return self
        }

        var cropRect: CGRect {
            let cgImage = self.cgImage
            let context = createARGBBitmapContextFromImage(inImage: cgImage!)
            if context == nil {
                return CGRect.zero
            }

            let height = CGFloat(cgImage!.height)
            let width = CGFloat(cgImage!.width)

            let rect = CGRect(x: 0, y: 0, width: width, height: height)
            context?.draw(cgImage!, in: rect)

            //let data = UnsafePointer<CUnsignedChar>(CGBitmapContextGetData(context))
            guard let data = context?.data?.assumingMemoryBound(to: UInt8.self) else {
                return CGRect.zero
            }

            var lowX = width
            var lowY = height
            var highX: CGFloat = 0
            var highY: CGFloat = 0

            let heightInt = Int(height)
            let widthInt = Int(width)
            //Filter through data and look for non-transparent pixels.
            for y in (0 ..< heightInt) {
                let y = CGFloat(y)
                for x in (0 ..< widthInt) {
                    let x = CGFloat(x)
                    let pixelIndex = (width * y + x) * 4 /* 4 for A, R, G, B */

                    if data[Int(pixelIndex)] == 0  { continue } // crop transparent

                    if data[Int(pixelIndex+1)] > 0xE0 && data[Int(pixelIndex+2)] > 0xE0 && data[Int(pixelIndex+3)] > 0xE0 { continue } // crop white

                    if (x < lowX) {
                        lowX = x
                    }
                    if (x > highX) {
                        highX = x
                    }
                    if (y < lowY) {
                        lowY = y
                    }
                    if (y > highY) {
                        highY = y
                    }

                }
            }

            return CGRect(x: lowX, y: lowY, width: highX - lowX, height: highY - lowY)
        }

        func createARGBBitmapContextFromImage(inImage: CGImage) -> CGContext? {

            let width = inImage.width
            let height = inImage.height

            let bitmapBytesPerRow = width * 4
            let bitmapByteCount = bitmapBytesPerRow * height

            let colorSpace = CGColorSpaceCreateDeviceRGB()

            let bitmapData = malloc(bitmapByteCount)
            if bitmapData == nil {
                return nil
            }

            let context = CGContext (data: bitmapData,
                                     width: width,
                                     height: height,
                                     bitsPerComponent: 8,      // bits per component
                bytesPerRow: bitmapBytesPerRow,
                space: colorSpace,
                bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue)

            return context
        }
    
    //from: https://stackoverflow.com/questions/47468367/how-to-add-gif-images-to-assets-folder-and-load-them-in-uiimageview-programmatic
    // Couldn't get this to work because I couldn't get the gif to show up in the asset libary, even after dragging it in. -WW 27Oct21
    /// Enables animated gifs to display correctly
    /// This line displays the image: /*nameOfImageViewOutlet*/.image = UIImage.gifImageWithName("/*name of image*/")
    func gif(asset: String) -> UIImage? {
        if let asset = NSDataAsset(name: asset) {
            return UIImage.gifImageWithData(asset.data)
        }
        return nil
    }


  // For NSFW Detection
  func buffer() -> CVPixelBuffer? {
    var pixelBuffer: CVPixelBuffer? = nil

    let width = 224
    let height = 224

    let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue, kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
    CVPixelBufferCreate(kCFAllocatorDefault, width, height, kCVPixelFormatType_32ARGB, attrs, &pixelBuffer)
    CVPixelBufferLockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue:0))

    let colorspace = CGColorSpaceCreateDeviceRGB()
    let bitmapContext = CGContext(data: CVPixelBufferGetBaseAddress(pixelBuffer!), width: width, height: height, bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer!), space: colorspace, bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)!

    bitmapContext.draw(self.cgImage!, in: CGRect(x: 0, y: 0, width: width, height: height))

    return pixelBuffer
  }
    
    

//    func resizeWithPercent(percentage: CGFloat) -> UIImage? {
//        let imageView = UIImageView(frame: CGRect(origin: .zero, size: CGSize(width: size.width * percentage, height: size.height * percentage)))
//        imageView.contentMode = .ScaleAspectFit
//        imageView.image = self
//        UIGraphicsBeginImageContextWithOptions(imageView.bounds.size, false, scale)
//        guard let context = UIGraphicsGetCurrentContext() else { return nil }
//        imageView.layer.renderInContext(context)
//        guard let result = UIGraphicsGetImageFromCurrentImageContext() else { return nil }
//        UIGraphicsEndImageContext()
//        return result
//    }
//    func resizeWithWidth(width: CGFloat) -> UIImage? {
//        let imageView = UIImageView(frame: CGRect(origin: .zero, size: CGSize(width: width, height: CGFloat(ceil(width/size.width * size.height)))))
//        imageView.contentMode = .ScaleAspectFit
//        imageView.image = self
//        UIGraphicsBeginImageContextWithOptions(imageView.bounds.size, false, scale)
//        guard let context = UIGraphicsGetCurrentContext() else { return nil }
//        imageView.layer.renderInContext(context)
//        guard let result = UIGraphicsGetImageFromCurrentImageContext() else { return nil }
//        UIGraphicsEndImageContext()
//        return result
//    }

    
    
    
    

}


