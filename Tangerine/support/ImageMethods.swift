//
//  ImageMethods.swift
//  
//
//  Created by Wyatt Weber on 1/6/17.
//  Copyright © 2017 Insightful Inc. All rights reserved.
//

import Foundation
import UIKit
import CoreImage


public var numFaces: Int = 0
private var context = { CIContext(options: nil) }()

extension UIImage {
    
    // from this webpage: https://stackoverflow.com/questions/43256005/swift-ios-reduce-image-size-before-upload
    // to use it, just call it like this:
    // myImage = myImage.resizeWithWidth(700)!
    // You can compress it using compression ratio of your choice like this:
    // let compressData = UIImageJPEGRepresentation(myImage, 0.5) //max value is 1.0 and minimum is 0.0
    // let compressedImage = UIImage(data: compressData!)
    
    /// Returns an image that is 'percentage'% of the size of the image's current size
    func resizeWithPercent(percentage: CGFloat) -> UIImage? {
        let imageView = UIImageView(frame: CGRect(origin: .zero, size: CGSize(width: size.width * percentage, height: size.height * percentage)))
        imageView.contentMode = .scaleAspectFit
        imageView.image = self
        UIGraphicsBeginImageContextWithOptions(imageView.bounds.size, false, scale)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        imageView.layer.render(in: context)
        guard let result = UIGraphicsGetImageFromCurrentImageContext() else { return nil }
        UIGraphicsEndImageContext()
        return result
    }
    
    /// Returns an image that has the same aspect ratio of the current image, but has been resized to have the passed in 'width' value
    func resizeWithWidth(width: CGFloat) -> UIImage? {
        let imageView = UIImageView(frame: CGRect(origin: .zero, size: CGSize(width: width, height: CGFloat(ceil(width/size.width * size.height)))))
        imageView.contentMode = .scaleAspectFit
        imageView.image = self
        UIGraphicsBeginImageContextWithOptions(imageView.bounds.size, false, scale)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        imageView.layer.render(in: context)
        guard let result = UIGraphicsGetImageFromCurrentImageContext() else { return nil }
        UIGraphicsEndImageContext()
        return result
    }
}

/// enables face blurring of photo before Question creation
public class BlurFace {
    private let ciDetector = CIDetector(ofType: CIDetectorTypeFace, context: nil ,options: [CIDetectorAccuracy : CIDetectorAccuracyHigh])
    private var ciImage: CIImage!
    private var orientation: UIImage.Orientation = .up
    private lazy var features : [AnyObject]! = { self.ciDetector!.features(in: self.ciImage) }()

    var maskImage: CIImage?
    let pixelateFilter = CIFilter(name: "CIPixellate")

    public init(image: UIImage!) {
        setImage(image: image)
    }
    public func setImage(image: UIImage!) {
        ciImage = CIImage(image: image)
        orientation = image.imageOrientation
        pixelateFilter?.setValue(ciImage, forKey: kCIInputImageKey)

        // Started out as 60

        pixelateFilter?.setValue(max(ciImage!.extent.width, ciImage.extent.height) / 30.0, forKey: kCIInputScaleKey)
    }
    /// creates a blurred /"pixellated" version of the image at a given X and Y location in a circle of a given radius
    public func setupBlurMask(centerX: CGFloat, centerY: CGFloat, radius: CGFloat) {
        let radialGradient = CIFilter(name: "CIRadialGradient")
        radialGradient?.setValue(radius, forKey: "inputRadius0")
        radialGradient?.setValue(radius + 1, forKey: "inputRadius1")
        radialGradient?.setValue(CIColor(red: 0, green: 1, blue: 0, alpha: 1), forKey: "inputColor0")
        radialGradient?.setValue(CIColor(red: 0, green: 0, blue: 0, alpha: 0), forKey: "inputColor1")
        radialGradient?.setValue(CIVector(x: centerX, y: centerY), forKey: kCIInputCenterKey)
        
        let croppedImage = radialGradient?.outputImage?.cropped(to: ciImage.extent)
        
        let circleImage = croppedImage
        if (maskImage == nil) {
            maskImage = circleImage
        } else {
            let filter =  CIFilter(name: "CISourceOverCompositing")
            filter?.setValue(circleImage, forKey: kCIInputImageKey)
            filter?.setValue(maskImage, forKey: kCIInputBackgroundImageKey)
            
            maskImage = filter?.outputImage
        }
    }
    public func addBlurMaskToImage() -> UIImage {
        let composite = CIFilter(name: "CIBlendWithMask")
        composite?.setValue(pixelateFilter?.outputImage, forKey: kCIInputImageKey)
        composite?.setValue(ciImage, forKey: kCIInputBackgroundImageKey)
        composite?.setValue(maskImage, forKey: kCIInputMaskImageKey)
        
        let cgImage = context.createCGImage(composite!.outputImage!, from: composite!.outputImage!.extent)
        
        return UIImage(cgImage: cgImage!, scale: 1, orientation: orientation)
    }
    
    
    /// This automatically detects faces in the image and blurs them
    public func autoBlurFaces() -> UIImage {
        numFaces = 0
        // This runs a loop to blur each individual face that the system has detected, one at a time
        for feature in featureFaces() {
            numFaces += 1
            print("\(numFaces) faces detected")
            
            let centerX = feature.bounds.origin.x + feature.bounds.size.width / 2.0
            let centerY = feature.bounds.origin.y + feature.bounds.size.height / 2.0
            let radius = min(feature.bounds.size.width, feature.bounds.size.height) / 1.5
            
            print("auto blurring face at x: \(centerX) y: \(centerY)")
            
            setupBlurMask(centerX: centerX, centerY: centerY, radius: radius)
            
        }
        if numFaces < 1 {
            print("numFaces = \(numFaces)")
        }
        
        return addBlurMaskToImage()
    }
    /// Manually blurs the pixels at the location that the user taps and holds. The longer the user holds the tap, the larger the blurred pixel radius is.
    public func manualBlurFace(at location: CGPoint, with radius: CGFloat) -> UIImage {

        // beacuse I don't have an autodetected face, I need to manually determine the size and location of the face box
        let centerX: CGFloat = location.x
        let centerY: CGFloat = location.y
        
        print("manual face blurring with radius of: \(radius)")
        setupBlurMask(centerX: centerX, centerY: centerY, radius: radius)

        return addBlurMaskToImage()
    }
    /// Locates the faces in the ciImage
    private func featureFaces() -> [CIFeature] {
        return features as! [CIFeature]
    }
}
// //////////////////////////////////////////////////////////
// The next set of public methods don't belong to a class  //
//                                                         //
// They are used to compute various properties relating    //
// the image as seen in the scrollView and the underlying  //
// image that is stored in the UIImageView.                //
// //////////////////////////////////////////////////////////


/// Determines whether the image is portrait, landscape, or square. Portraits with different h to w ratios would still be considered portraits.
/// We use this value later to avoid redundant logic statements.
public func computeImageAspectType(passedImage: UIImage) -> ImageAspectType {
    if passedImage.size.width < passedImage.size.height { //portrait
        return .isPortrait
    } else if passedImage.size.width > passedImage.size.height { //landscape
        return .isLandscape
    } else { //square image already
        return .isSquare
    }
}

/// This determines the "scale" as far as how many times bigger or smaller the longest side of the displayed image is to the actual size of the longest side of the stored image in memory:
public func computeUnderlyingToDisplayedRatio(passedImage: UIImage, screenWidth: CGFloat) -> CGFloat {
    
    let underlyingImageWidth = passedImage.size.width
    let underlyingImageHeight = passedImage.size.height
    
    if computeImageAspectType(passedImage: passedImage) == ImageAspectType.isPortrait {
        return underlyingImageHeight / screenWidth
    } else { //encompasses landscape and square images
        return underlyingImageWidth / screenWidth
    }
}

/// This computes the linear value of the white space either to the sides or above and below the non-square image.
/// The actual value returned is only one of the two rectangles, not the total added up space. Hence the "/ 2."
public func computeWhiteSpace(passedImage: UIImage) -> CGFloat {
    let imageAspectType = computeImageAspectType(passedImage: passedImage)
    
    let underlyingImageWidth = passedImage.size.width
    let underlyingImageHeight = passedImage.size.height
    
    if imageAspectType == ImageAspectType.isPortrait {
        return (underlyingImageHeight - underlyingImageWidth) / 2
    } else if imageAspectType == ImageAspectType.isLandscape {
        return (underlyingImageWidth - underlyingImageHeight) / 2
    } else { //it's a square, there is no white space
        return 0.0
    }
}

/// Returns the linear percent (90% =  .9, this returns .9) of the total imageView that is taken up by white space, divided by 2, since we will never care about all the white space, just the white space on one side or the other, or top or bottom as in the case of a "landscape" rectangle.
public func computeWhiteSpaceAsDecimalPercent(passedImage: UIImage) -> CGFloat {
    let imageAspectType = computeImageAspectType(passedImage: passedImage)
    
    let underlyingImageWidth = passedImage.size.width
    let underlyingImageHeight = passedImage.size.height
    
    if imageAspectType == ImageAspectType.isPortrait {
        // it is 2 * height in denominator in order to "divide the white space by 2" for ease of use
        return (underlyingImageHeight - underlyingImageWidth) / (2 * underlyingImageHeight)
    } else if imageAspectType == ImageAspectType.isLandscape {
        // it is 2 * width in denominator in order to "divide the white space by 2" for ease of use
        return (underlyingImageWidth - underlyingImageHeight) / (2 * underlyingImageWidth)
    } else { //it's a square, there is no white space
        return 0.0
    }
}



/// Returns a point with the scrollView's content offset converted to percentage. I.e. the center of a scroll would be 50% down and 50% left aka (0.5 ,0.5) Remember, the origin is in upper left in Core Graphics.
public func computeContentOffsetAsDecimalPercent(offsetPoint: CGPoint, zoomScale: CGFloat, imageViewSideLength: CGFloat) -> CGPoint {
    // The length of one entire side of the scrollView at this zoomScale (scrollView is a square shape) is the same as the length of a side of the imageView at this zoomScale
    
    // compute the x coordinate
    let returnedX = offsetPoint.x / imageViewSideLength
    // compute the y coordinate
    let returnedY = offsetPoint.y / imageViewSideLength
    
    return CGPoint(x: returnedX, y: returnedY)
}

/// Returns the distance from the edge of the image that the crop origin should be, for the "short side" aka the side that has white space next to it. To be clear, this percentage is OF THE IMAGE, not of the entire scrollView.
/// To calculate the actual image distance to pass into the crop origin, just multiply the result of this function by the total length of the short side.
/// Short side explanation: in a portrait the short side is the image's width.
///                  in a landscape, the short side is the image's height.
/// Factors in two scenarios:
/// 1. Content offet is IN the whitespace. This returns 0.0 since we are not cropping nothingness.
/// 2. Content offset is beyond the whitespace i.e. IN the image. This returns a positive number because there is part of the image we aren't including in our cropped portion.
public func computeShortSideOriginDistancePercent(whiteSpaceAsPercent: CGFloat, contentOffsetAsPercent: CGFloat, image: UIImage) -> CGFloat {
    
    let percentOfScrollViewDistanceOfImageToCropOut: CGFloat = contentOffsetAsPercent - whiteSpaceAsPercent
    let percentOfScrollViewThatImageTakesUp = computeShortSideLengthAsPercentOfScrollView(image: image)
    let computedDistancePercent = percentOfScrollViewDistanceOfImageToCropOut / percentOfScrollViewThatImageTakesUp
    
    // situation 1: content offset in whitespace, crop from the edge of the image
    if computedDistancePercent < 0 {
        return 0.0
        
    // situation 2: content offset in image, crop computedDistancePercent amount after whiteSpace
    } else {
        return computedDistancePercent
    }
}

/// Very similar to computeShortSideOriginDistancePercent(...). The different being that it gives us how much white space is still left showing on the left side of the screen (or top of the screen as with a landscape aspect image)
/// The percentage returned is in relation to the entire scrollView canvas size.
public func computeLeadingWhiteSpacePercentInView(whiteSpaceAsPercent: CGFloat, contentOffsetAsPercent: CGFloat) -> CGFloat {
    let computedDistancePercent: CGFloat = contentOffsetAsPercent - whiteSpaceAsPercent
    
    // situation 1: content offset in whitespace, crop from the edge of the image
    if computedDistancePercent < 0 {
        return abs(computedDistancePercent)
    // situation 2: content offset in image, crop computedDistancePercent amount after whiteSpace
    } else {
        return 0.0
    }
}

/// returns the percentage length of the scroll view that the short side of the underlying image takes up
public func computeShortSideLengthAsPercentOfScrollView(image: UIImage) -> CGFloat {
    let aspectType = computeImageAspectType(passedImage: image)
    
    // we compare the sides to each other because the long side (as opposed to the short side) represents 100% of the length of one side of the square scrollView
    // format is small/big so that it's a number < 1.0
    switch aspectType {
    case .isPortrait:
        return image.size.width / image.size.height
    case .isLandscape:
        return image.size.height / image.size.width
    case .isSquare:
        return 1.0
    }
}

/// just another way of conveying the zoomScale. Instead of zoomscale/1 this is 1/zoomscale to give us the percent of the whole that the imageView size is
public func computeImageViewWidthAsDecimalPercent(zoomScale: CGFloat) -> CGFloat {
    return 1/zoomScale
}

/// Determines the percent length of the image to crop for the "short side" i.e. when we have to worry about white space
public func computeShortSideLengthPercentToCrop(zoomScale: CGFloat, whiteSpaceAsPercent: CGFloat, contentOffsetAsPercent: CGFloat, imageToCrop: UIImage) -> CGFloat {
    
    // This is where the origin of the crop box should be (for the short side axis). We're only using this here to quickly determine whether the content offset is in the white space or not.
    let originDistancePercent = computeShortSideOriginDistancePercent(whiteSpaceAsPercent: whiteSpaceAsPercent, contentOffsetAsPercent: contentOffsetAsPercent, image: imageToCrop)
    
    /// aka the part of the image we are cropping out (in this axis)
    let percentOfImageBeforeLeadingSideOfImageView = originDistancePercent
//    print("percentOfImageBeforeLeadingSideOfImageView (of the scrollView) is calculated at: \(percentOfImageBeforeLeadingSideOfImageView)")
    
    /// imageViewSideLengthAsPercent (of the scrollView)
    let imageViewSideLengthAsPercentOfScrollView = computeImageViewWidthAsDecimalPercent(zoomScale: zoomScale)
//    print("imageViewSideLengthAsPercent (of the scrollView) is calculated at: \(imageViewSideLengthAsPercentOfScrollView)")
    
    let shortSideLengthAsPercent = computeShortSideLengthAsPercentOfScrollView(image: imageToCrop)
//    print("shortSideLengthAsPercent (of the scrollView) is calculated at: \(shortSideLengthAsPercent)")
    
    let leadingWhiteSpacePercentInView = computeLeadingWhiteSpacePercentInView(whiteSpaceAsPercent: whiteSpaceAsPercent, contentOffsetAsPercent: contentOffsetAsPercent)
//    print("leadingWhiteSpacePercentInView is calculated at: \(leadingWhiteSpacePercentInView)")
    
    /// This is the percent of the image that the member can either see in the imageView (in this axis), or has been covered up by the trailing side of the imageView (if we're zoomed in far enough that the leading and trailing points are both in the image and out of the whitespace.
    let percentOfImageBeyondLeadingSideOfImageView = 1 - percentOfImageBeforeLeadingSideOfImageView
    
    let imageViewSideLengthAsPercentOfUnderlyingImage = imageViewSideLengthAsPercentOfScrollView / shortSideLengthAsPercent

//    let percentOfImageShortSideVisibleInImageView = percentOfImageBeyondLeadingSideOfImageView - percentOfImageBeyondTrailingSideOfImageView

    /// This is a weird way to calculate this because white space is intrinsically not part of the image. In this case it's just being made in proportion to the image for an apples to apples comparison.
    let leadingWhiteSpaceAsPercentOfUnderlyingImage = leadingWhiteSpacePercentInView / shortSideLengthAsPercent
    
    // situation 1: content offset in whitespace, crop from the leading edge of the image to somewhere in the middle of the image (or all the way to the far edge if we're not zoomed in or panned over far enough to cover up all the trailing white space)
    if originDistancePercent == 0 {
        // This is the case where the imageView is displaying some white space as well as the whole image from one side to the other (in the short side axis)
        
        
        // trailing edge of imageView is in the trailing whitespace because it is larger in relation to the image than the percent of the image that falls after the leading edge of the imageView
        if imageViewSideLengthAsPercentOfUnderlyingImage > percentOfImageBeyondLeadingSideOfImageView {
            return 1.0 //aka crop 100% of the image in the short side axis because the imageView is showing all of it
        
        
            
        // if the percent of the image that we can see is less than the percent that's to the right of or below (depending on orientation) the leading side of the imageView, then we need to crop some of the trailing side off. Another way to think of this is the trailing side of the imageView being in the image and OUT of the white space. No white space showing on trailing side of imageView.
        // This is the case where there is some leading white space in the imageView but not all of the actual underlying image is being displayed in the imageView so we want to crop some of it off
        } else { // we return the percent of the underlying image visible in the scrollView because there is no trailing whitespace to worry about.
            return imageViewSideLengthAsPercentOfUnderlyingImage - leadingWhiteSpaceAsPercentOfUnderlyingImage
        }

        
    // situation 2: content offset is IN the image
    } else { //i.e. originDistancePercent > 0
        
        // there is trailing white space, so crop to the trailing edge of the image
        if imageViewSideLengthAsPercentOfUnderlyingImage > percentOfImageBeyondLeadingSideOfImageView {
            return percentOfImageBeyondLeadingSideOfImageView
        
        
        // there is no trailing white space, just crop from the origin that is inside of the image, to the trailing edge of the imageView which is also in the image
        } else {
            return imageViewSideLengthAsPercentOfUnderlyingImage
        }
    }
}



/// Returns a CGPoint on the image based on where the user tapped on the image as depicted in the scrollView. (If the user zoomed in and panned around, the coordinates will not be the same for the scrollView as they are on the actual image, so we convert them to ensure we know the actual point on the image itself that the user meant to tap on - presumably to blur something out).
public func computeOrig(passedImage: UIImage, pointToConvert: CGPoint, screenWidth: CGFloat, contentOffset: CGPoint, zoomScale: CGFloat) -> CGPoint {
    let unzoomedOffsetX = contentOffset.x / zoomScale
    let unzoomedOffsetY = contentOffset.y / zoomScale
    let unzoomedPointToConvertX = pointToConvert.x / zoomScale
    let unzoomedPointToConvertY = pointToConvert.y / zoomScale
    var returnedX: CGFloat
    var returnedY: CGFloat
    
    //We need to do something with the point to convert
    
    let underlyingToDisplayedRatio = computeUnderlyingToDisplayedRatio(passedImage: passedImage, screenWidth: screenWidth)
    let whiteSpace = computeWhiteSpace(passedImage: passedImage)
    //if it's not a square, we need to account for the white space on either sides of the rectanglar image in the ImageView.
    //Since we know the photo is centered between the white space, we know that half of the white space
    // is on either side of it. (already factored into the white space value)
    if computeImageAspectType(passedImage: passedImage) == ImageAspectType.isPortrait {
        //print("returning \((unzoomedOffsetX * underlyingToDisplayedRatio) - whiteSpace) for origX")
        print("underlying image width is \(passedImage.size.width) and height is \(passedImage.size.height)")
        returnedX = (unzoomedPointToConvertX * underlyingToDisplayedRatio) + (unzoomedOffsetX * underlyingToDisplayedRatio) - whiteSpace
        returnedY = (unzoomedPointToConvertY * underlyingToDisplayedRatio) + (unzoomedOffsetY * underlyingToDisplayedRatio)
    } else {
        returnedX = (unzoomedPointToConvertX * underlyingToDisplayedRatio) + (unzoomedOffsetX * underlyingToDisplayedRatio)
        returnedY = (unzoomedPointToConvertY * underlyingToDisplayedRatio) + (unzoomedOffsetY * underlyingToDisplayedRatio) - whiteSpace
    }

    return CGPoint(x: returnedX, y: returnedY)
}

/// Locates the upper left point of the frame to be cut out of the image and saved
public func computeCropOrigin (imageView: UIImageView, contentOffset: CGPoint, zoomScale: CGFloat) -> CGPoint {
    print("computing Crop Origin..")
    //    let unzoomedOffsetX = contentOffset.x / zoomScale
    //    let unzoomedOffsetY = contentOffset.y / zoomScale
    //    let unzoomedPointToConvertX = pointToConvert.x / zoomScale
    //    let unzoomedPointToConvertY = pointToConvert.y / zoomScale
    var returnedX: CGFloat
    var returnedY: CGFloat
    
    guard let passedImage = imageView.image else {
        print("imageView contained no image, or it couldn't be unwrapped. Returned (0,0) as the crop origin.")
        return CGPoint(x: 0.0, y: 0.0)
    }
    
    let imageWidth = passedImage.size.width
    let imageHeight = passedImage.size.height
    // compute x coordinate
    
    // content offset % minus whitespace %
    
    //We need to do something with the point to convert
    //
    //    let underlyingToDisplayedRatio = computeUnderlyingToDisplayedRatio(passedImage: passedImage, screenWidth: screenWidth)
    //    print("computed underlyingToDisplayedRatio is: \(underlyingToDisplayedRatio)")
    
    //if it's not a square, we need to account for the white space on either or both sides (or top and/or bottom) of the rectanglar image in the ImageView.
    //Since we know the photo is centered between the white space, we know that half of the white space
    // is on either side of it. (already factored into the white space value)
    let whiteSpacePercent = computeWhiteSpaceAsDecimalPercent(passedImage: passedImage)
    
    let contentOffsetPercent: CGPoint = computeContentOffsetAsDecimalPercent(offsetPoint: contentOffset, zoomScale: zoomScale, imageViewSideLength: imageView.frame.width)
//    print("using imageView.frame.width to calculate the content offset percent. \nTo ensure that the imaegView is actually a square, imageView.frame.width: \(imageView.frame.width). Height:")
    let height = imageView.frame.height
    print(height)
//    print("computed content offset percent (of entire scrollview) is \nx: \(contentOffsetPercent.x), y:\(contentOffsetPercent.y) ")
    
    let imageAspectType = computeImageAspectType(passedImage: passedImage)
    
    switch imageAspectType {
    case .isPortrait:
//        print("image is portrait")
        // in a portrait, X is the short side
        let xPercent = computeShortSideOriginDistancePercent(whiteSpaceAsPercent: whiteSpacePercent, contentOffsetAsPercent: contentOffsetPercent.x, image: passedImage)
//        print("Computed percent of underlying image to crop out is: \(xPercent)")
        
        returnedX = imageWidth * xPercent
        returnedY = imageHeight * contentOffsetPercent.y
    case .isLandscape:
//        print("image is landscape or square")
        // in a landscape, Y is the short side. In a square, there is no short side, or you could say, they are both short sides
        let yPercent = computeShortSideOriginDistancePercent(whiteSpaceAsPercent: whiteSpacePercent, contentOffsetAsPercent: contentOffsetPercent.y, image: passedImage)
        
        returnedX = imageWidth * contentOffsetPercent.x
        returnedY = imageHeight * yPercent
    case .isSquare:
        returnedX = imageWidth * contentOffsetPercent.x
        returnedY = imageHeight * contentOffsetPercent.y
    }
    
//    if computeImageAspectType(passedImage: passedImage) == ImageAspectType.isPortrait {
//        print("image is portrait")
//        // in a portrait, X is the short side
//        let xPercent = computeShortSideOriginDistancePercent(whiteSpaceAsPercent: whiteSpacePercent, contentOffsetAsPercent: contentOffsetPercent.x, image: passedImage)
//        print("Computed percent of underlying image to crop out is: \(xPercent)")
//
//        returnedX = imageWidth * xPercent
//        returnedY = imageHeight * contentOffsetPercent.y
//
//        // The only other cases are landscape and square. This will compute either since whitespace for a square is just zero in either axis.
//    } else if computeImageAspectType(passedImage: passedImage) == ImageAspectType.isLandscape {
//
//    } else {
//        print("image is landscape or square")
//        // in a landscape, Y is the short side. In a square, there is no short side, or you could say, they are both short sides
//        let yPercent = computeShortSideOriginDistancePercent(whiteSpaceAsPercent: whiteSpacePercent, contentOffsetAsPercent: contentOffsetPercent.y, image: passedImage)
//
//        returnedX = imageWidth * yPercent
//        returnedY = imageHeight * contentOffsetPercent.x
//    }
    return CGPoint(x: returnedX, y: returnedY)
}



// ADDED BY MM

public func saveImageToDiskWith(imageName: String, image: UIImage, isThumb: Bool = false) {

    if isThumb {
        print("Saving a thumb")
    }
    
 guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }

    let fileName = imageName
    let fileURL = documentsDirectory.appendingPathComponent(fileName)
    let thumbURL = documentsDirectory.appendingPathComponent("thumb_\(fileName)")
    
    if isThumb{
        
        if FileManager.default.fileExists(atPath: thumbURL.path) {
            return
        }
        
        guard let thumbData = image.jpegData(compressionQuality: 0.01) else {return}
        
        do {
            try thumbData.write(to: thumbURL)
            print("Thumb has been saved with name thumb_\(fileName)")
        } catch let error {
            print("error saving thumb file with error", error)
        }
    }
    
    if FileManager.default.fileExists(atPath: fileURL.path) {
        return
    }

    guard let data = image.jpegData(compressionQuality: 1) else { return }
    
    //Checks if file exists, removes it if so.
//    if FileManager.default.fileExists(atPath: fileURL.path) {
//        do {
//            try FileManager.default.removeItem(atPath: fileURL.path)
//            print("Removed old image")
//        } catch let removeError {
//            print("couldn't remove file at path", removeError)
//        }
//
//    }

    do {
        try data.write(to: fileURL)
        print("Image has been saved with name \(imageName)")
    } catch let error {
        print("error saving file with error", error)
    }
} // end of save Image to disk


public func removeImageFromDevice(ofName filename: String){
    
    guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
    
    let fileURL = documentsDirectory.appendingPathComponent(filename)
    
    //Checks if file exists, removes it if so.
    if FileManager.default.fileExists(atPath: fileURL.path) {
        do {
            try FileManager.default.removeItem(atPath: fileURL.path)
            print("Removed image for \(filename)")
        } catch let removeError {
            print("couldn't remove image of \(filename)", removeError)
        }
        
    }
    
    
}



public func loadImageFromDiskWith(fileName: String) -> UIImage? {

  let documentDirectory = FileManager.SearchPathDirectory.documentDirectory

    let userDomainMask = FileManager.SearchPathDomainMask.userDomainMask
    let paths = NSSearchPathForDirectoriesInDomains(documentDirectory, userDomainMask, true)

    if let dirPath = paths.first {
        let imageUrl = URL(fileURLWithPath: dirPath).appendingPathComponent(fileName)
        let image = UIImage(contentsOfFile: imageUrl.path)
        return image

    }

    return nil
}








