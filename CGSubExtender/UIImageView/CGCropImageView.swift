//
//  CGCropImageView.swift
//  CGSubExtender
//
//  Created by Charles Gorectke on 11/18/14.
//  Copyright (c) 2014 Revision Works, LLC. All rights reserved.
//

import UIKit

public class CGCropImageView: UIImageView {
    public var cropView: CGCropView!
    public var cropViewHidden: Bool {
        get {
            return cropView.hidden
        }
        set(isHidden) {
            cropView.hidden = isHidden
        }
    }
    
    var _image: UIImage?
    public override var image: UIImage? {
        get {
            return super.image
        }
        set(newImage) {
            super.image = newImage
            cropViewHidden = false
            cropView.setupCropView()
            cropView.setNeedsDisplay()
        }
    }
    
    public var gallery = false
    
    var cornersDetected: Bool = false
    
    var maxX: CGFloat = 0.0
    var maxY: CGFloat = 0.0
    
    public required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setTranslatesAutoresizingMaskIntoConstraints(false)
        self.userInteractionEnabled = true
    }
    
    public override func layoutSubviews() {
//        super.layoutSubviews()
        
        if cropView == nil {
            cropView = CGCropView()
            cropView.setTranslatesAutoresizingMaskIntoConstraints(false)
            cropView.userInteractionEnabled = true
            cropView.backgroundColor = UIColor.clearColor()
            cropView.hidden = true
            
            self.addSubview(cropView)
            self.bringSubviewToFront(cropView)
            self.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|[cropView]|", options: NSLayoutFormatOptions(0), metrics: nil, views: [ "cropView" : self.cropView ]))
            self.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|[cropView]|", options: NSLayoutFormatOptions(0), metrics: nil, views: [ "cropView" : self.cropView ]))
        }
        
        // Get the min/max X/Y coords
        maxX = self.frame.size.width - cropView.handleSize
        maxY = self.frame.size.height - cropView.handleSize
        
        println("Crop View layed out... \(self.frame.size)")
        
        cropView.setupCropView()
    }
    
    public func cropImage() {
        if !cropView.doneCropping {
            cropView.doneCropping = true
            
            if let img = self.image {
                self.image = img.imageWithFixedOrientation(gallery)
            }
            
            self.image = CGOpenCVMatrixTranslator.cropImageView(self)
            cropViewHidden = true
            self.setNeedsDisplay()
        }
    }
    
    public override func touchesBegan(touches: NSSet, withEvent event: UIEvent) {
        // Get touch info
        let touch: UITouch = touches.anyObject() as UITouch
        let touchPoint = touch.locationInView(cropView)
        
        // Check for touch in all handles
        for (index, currentHandle) in enumerate(cropView.cropHandles) {
            if CGRectContainsPoint(currentHandle.frame, touchPoint) && !currentHandle.hidden {
                // Change alpha for grabbed handle
                currentHandle.alpha = cropView.handleAlphaTouch
                
                // Save this as the currently grabbed handle
                cropView.grabbedHandle = currentHandle
                cropView.grabbedHandleIndex = index
                break
            }
        }
        
        // If we didn't grab a handle, check if we grabbed the region
        if (cropView.selectionContainsPoint(touchPoint) && cropView.grabbedHandle == nil) {
            // Set to centroid to signify grabbing region body
            cropView.grabbedHandle = cropView.centroid
        }
    }
    
    public override func touchesMoved(touches: NSSet, withEvent event: UIEvent) {
        if let grabHandle = cropView.grabbedHandle {
            // Get touch info
            let touch: UITouch = touches.anyObject() as UITouch
            let touchPoint: CGPoint = touch.locationInView(cropView)
            let lastPoint: CGPoint  = touch.previousLocationInView(cropView)
            
            // Caclulate delta for smooth movement of handle
            let dX: CGFloat = touchPoint.x - lastPoint.x
            let dY: CGFloat = touchPoint.y - lastPoint.y
            
            // Determine what is being moved
            if grabHandle == cropView.centroid {
                self.moveBodyWithDX(dX, andDY: dY)
            } else {
                // Determine if we've grabbed a side handle
                if let grabIndex = cropView.grabbedHandleIndex {
                    if grabIndex == CGCropHandleIndex.TopCenter.rawValue ||
                        grabIndex == CGCropHandleIndex.RightCenter.rawValue ||
                        grabIndex == CGCropHandleIndex.BottomCenter.rawValue ||
                        grabIndex == CGCropHandleIndex.LeftCenter.rawValue {
                            self.moveSideWithDX(dX, andDY: dY, withGrabIndex: grabIndex)
                    } else {
                        self.moveCornerWithDX(dX, andDY: dY)
                    }
                }
            }
            
            // Tell the view to redraw
            cropView.setNeedsDisplay()
        }
        
    }
    
    public override func touchesEnded(touches: NSSet, withEvent event: UIEvent) {
        // Reset the grabbed handle
        if let grabHandle = cropView.grabbedHandle {
            grabHandle.alpha = cropView.handleAlphaBase
            cropView.grabbedHandle = nil
        }
    }
    
    func moveBodyWithDX(dX: CGFloat, andDY dY: CGFloat) {
        // Keep track of which axis to preserve the held handle location on
        var updateX = true
        var updateY = true
        // Handle to hold in place on a certain axis
        var hold: UIView?
        var tempDX: CGFloat = dX
        var tempDY: CGFloat = dY
        
        for handle in cropView.cropHandles {
            // Calculate the new points after move
            let newX: CGFloat = handle.frame.origin.x + tempDX
            let newY: CGFloat = handle.frame.origin.y + tempDY
            
            // Get the rects to modify
            var handleRect = handle.frame
            
            // Check if this handle will move out of the view on the x-axis
            if newX < 0.0 || newX > maxX {
                // Recalculate delta to adjust other points appropriately
                if newX < 0.0 {
                    tempDX = 0.0 - handleRect.origin.x
                    handleRect.origin.x = 0.0
                } else if newX > maxX {
                    tempDX = maxX - handleRect.origin.x
                    handleRect.origin.x = maxX
                }
                
                // Hold this handle position on the x-axis
                updateX = false
                hold = handle
            }
            
            // Check if this handle will move out of the view on the y-axis
            if newY < 0.0 || newY > maxY {
                // Recalculate delta to adjust other points appropriatly
                if newY < 0.0 {
                    tempDY = 0.0 - handleRect.origin.y
                    handleRect.origin.y = 0.0
                } else if newY > maxY {
                    tempDY = maxY - handleRect.origin.y
                    handleRect.origin.y = maxY
                }
                
                // Hold this handle position on the y-axis
                updateY = false
                hold = handle
            }
            
            // Reset the view frames to our modified rects
            handle.frame = handleRect
        }
        
        // Update the handles accordingly
        for handle in cropView.cropHandles {
            // Calculate the new points after move
            let newX = handle.frame.origin.x + tempDX
            let newY = handle.frame.origin.y + tempDY
            
            // Get the rects to modify
            var handleRect = handle.frame
            
            // Check if this handle is the held handle
            let isHeldHandle = handle == hold
            
            // Update X if this is not held for the x-axis
            if !isHeldHandle || (isHeldHandle && updateX) {
                handleRect.origin.x = newX
            }
            
            // Update Y if this is not held for the y-axis
            if !isHeldHandle || (isHeldHandle && updateY) {
                handleRect.origin.y = newY
            }
            
            // Reset the view frames to our modified rects
            handle.frame = handleRect
        }
        
        // Adjust the centroid
        if let cent = cropView.centroid {
            var cenRec = cent.frame
            cenRec.origin.x += tempDX
            cenRec.origin.y += tempDY
            cent.frame = cenRec
        }
    }
    
    func moveSideWithDX(dX: CGFloat, andDY dY: CGFloat, withGrabIndex grabIndex: Int) {
        // Get next/last indices
        let lastIndex = grabIndex - 1
        var nextIndex = grabIndex + 1
        
        // If this is the last handle, then the next is the first handle
        if grabIndex == cropView.cropHandles.count - 1 {
            nextIndex = 0
        }
        
        // Get the corresponding handles
        let lastHandle = cropView.cropHandles[lastIndex]
        let nextHandle = cropView.cropHandles[nextIndex]
        
        // Get the rects
        if let grabHandle = cropView.grabbedHandle {
            
            var grabRect = grabHandle.frame
            var lastRect = lastHandle.frame
            var nextRect = nextHandle.frame
            
            // Ensure we won't move out of view
            let curMaxX = max(lastRect.origin.x + dX, nextRect.origin.x + dX)
            let curMinX = min(lastRect.origin.x + dX, nextRect.origin.x + dX)
            let curMaxY = max(lastRect.origin.y + dY, nextRect.origin.y + dY)
            let curMinY = min(lastRect.origin.y + dY, nextRect.origin.y + dY)
            
            // Adjust all affected handles accordingly
            if (grabIndex == CGCropHandleIndex.TopCenter.rawValue || grabIndex == CGCropHandleIndex.BottomCenter.rawValue) && (curMaxY < maxY && curMinY > 0.0) {
                self.adjustAffectedHandles(&grabRect, lastRect: &lastRect, nextRect: &nextRect, withDX: dX, withDY: dY, withGrabIndex: grabIndex, acrossX: false)
            } else if (grabIndex == CGCropHandleIndex.LeftCenter.rawValue || grabIndex == CGCropHandleIndex.RightCenter.rawValue) && (curMinX > 0.0 && curMaxX < maxX) {
                self.adjustAffectedHandles(&grabRect, lastRect: &lastRect, nextRect: &nextRect, withDX: dX, withDY: dY, withGrabIndex: grabIndex, acrossX: true)
            }
            
            // Readjust the centroid
            if let cent = cropView.centroid {
                var cenRec = cent.frame
                cenRec.origin.x = cenRec.origin.x * 4 - lastHandle.frame.origin.x - nextHandle.frame.origin.x
                cenRec.origin.y = cenRec.origin.y * 4 - lastHandle.frame.origin.y - nextHandle.frame.origin.y
                cenRec.origin.x += lastRect.origin.x + nextRect.origin.x
                cenRec.origin.y += lastRect.origin.y + nextRect.origin.y
                cenRec.origin.x *= 0.25
                cenRec.origin.y *= 0.25
                
                // Set all handle changes
                grabHandle.frame = grabRect
                lastHandle.frame = lastRect
                nextHandle.frame = nextRect
                cent.frame = cenRec
            }
        }
    }
    
    func adjustAffectedHandles(inout grabRect: CGRect, inout lastRect: CGRect, inout nextRect: CGRect, withDX dX: CGFloat, withDY dY: CGFloat, withGrabIndex grabIndex: Int, acrossX: Bool) {
        
        var releventHandleOne: Int = -1
        var releventHandleTwo: Int = -1
        var handleCornerOne: Int = -1
        var handleCornerTwo: Int = -1
        
        var tempMidRectOne: CGRect = CGRectZero
        var tempMidRectTwo: CGRect = CGRectZero
        
        // Get relevent side handles
        if acrossX {
            grabRect.origin.x += dX
            lastRect.origin.x += dX
            nextRect.origin.x += dX
            
            releventHandleOne = CGCropHandleIndex.TopCenter.rawValue
            releventHandleTwo = CGCropHandleIndex.BottomCenter.rawValue
            if grabIndex == CGCropHandleIndex.LeftCenter.rawValue {
                handleCornerOne = CGCropHandleIndex.TopRight.rawValue
                handleCornerTwo = CGCropHandleIndex.BottomRight.rawValue
                tempMidRectOne = nextRect; tempMidRectTwo = lastRect
            } else if grabIndex == CGCropHandleIndex.RightCenter.rawValue {
                handleCornerOne = CGCropHandleIndex.TopLeft.rawValue
                handleCornerTwo = CGCropHandleIndex.BottomLeft.rawValue
                tempMidRectOne = lastRect; tempMidRectTwo = nextRect
            }
        } else {
            grabRect.origin.y += dY
            lastRect.origin.y += dY
            nextRect.origin.y += dY
            
            releventHandleOne = CGCropHandleIndex.LeftCenter.rawValue
            releventHandleTwo = CGCropHandleIndex.RightCenter.rawValue
            if grabIndex == CGCropHandleIndex.TopCenter.rawValue {
                handleCornerOne = CGCropHandleIndex.BottomLeft.rawValue
                handleCornerTwo = CGCropHandleIndex.BottomRight.rawValue
                tempMidRectOne = lastRect; tempMidRectTwo = nextRect
            } else if grabIndex == CGCropHandleIndex.BottomCenter.rawValue {
                handleCornerOne = CGCropHandleIndex.TopLeft.rawValue
                handleCornerTwo = CGCropHandleIndex.TopRight.rawValue
                tempMidRectOne = nextRect; tempMidRectTwo = lastRect
            }
        }
        
        /* Across Both */
        
        // Formally topSide or leftSide
        let sideOne = cropView.cropHandles[releventHandleOne]
        
        // Formally bottomSide or rightSide
        let sideTwo = cropView.cropHandles[releventHandleTwo]
        
        var rectOne = sideOne.frame
        var rectTwo = sideTwo.frame
        
        var sideCornerOne: UIView = cropView.cropHandles[handleCornerOne]
        var sideCornerTwo: UIView = cropView.cropHandles[handleCornerTwo]
        
        // Adjust the other side handles when moving the corner handles next to this side handle
        rectOne.origin = CGPointMake((tempMidRectOne.origin.x + sideCornerOne.frame.origin.x) / 2, (tempMidRectOne.origin.y + sideCornerOne.frame.origin.y) / 2)
        rectTwo.origin = CGPointMake((tempMidRectTwo.origin.x + sideCornerTwo.frame.origin.x) / 2, (tempMidRectTwo.origin.y + sideCornerTwo.frame.origin.y) / 2)
        
        sideOne.frame = rectOne
        sideTwo.frame = rectTwo
        
    }
    
    func moveCornerWithDX(dX: CGFloat, andDY dY: CGFloat) {
        // Calculate the new points after move
        if let grabHandle = cropView.grabbedHandle {
            if let grabIndex = cropView.grabbedHandleIndex {
                if let cent = cropView.centroid {
                    let newX = grabHandle.frame.origin.x + dX
                    let newY = grabHandle.frame.origin.y + dY
                    
                    // Get the rects to modify
                    var handleRect = grabHandle.frame
                    var cenRec = cent.frame
                    
                    // Update X if we are still in the view
                    if newX > 0.0 && newX < maxX {
                        cenRec.origin.x = cenRec.origin.x * 4 - grabHandle.frame.origin.x
                        cenRec.origin.x += grabHandle.frame.origin.x + dX
                        cenRec.origin.x *= 0.25
                        
                        handleRect.origin.x = handleRect.origin.x + dX
                    }
                    
                    // Update Y if we are still in the view
                    if newY > 0.0 && newY < maxY {
                        cenRec.origin.y = cenRec.origin.y * 4 - grabHandle.frame.origin.y
                        cenRec.origin.y += grabHandle.frame.origin.y + dY
                        cenRec.origin.y *= 0.25
                        
                        handleRect.origin.y = handleRect.origin.y + dY
                    }
                    
                    // Temp variable for readjusting the side handles
                    var outerPoint1: CGPoint = CGPointZero
                    var outerPoint2: CGPoint = CGPointZero
                    var side1: UIView!
                    var side2: UIView!
                    
                    // Get the appropriate side handles and corner points in relation to the current grab handle
                    switch grabIndex {
                        
                    case CGCropHandleIndex.TopLeft.rawValue:
                        side1 = cropView.cropHandles[CGCropHandleIndex.TopCenter.rawValue]
                        side2 = cropView.cropHandles[CGCropHandleIndex.LeftCenter.rawValue]
                        outerPoint1 = cropView.cropHandles[CGCropHandleIndex.TopRight.rawValue].frame.origin
                        outerPoint2 = cropView.cropHandles[CGCropHandleIndex.BottomLeft.rawValue].frame.origin
                        
                    case CGCropHandleIndex.TopRight.rawValue:
                        side1 = cropView.cropHandles[CGCropHandleIndex.TopCenter.rawValue]
                        side2 = cropView.cropHandles[CGCropHandleIndex.RightCenter.rawValue]
                        outerPoint1 = cropView.cropHandles[CGCropHandleIndex.TopLeft.rawValue].frame.origin
                        outerPoint2 = cropView.cropHandles[CGCropHandleIndex.BottomRight.rawValue].frame.origin
                        
                    case CGCropHandleIndex.BottomRight.rawValue:
                        side1 = cropView.cropHandles[CGCropHandleIndex.RightCenter.rawValue]
                        side2 = cropView.cropHandles[CGCropHandleIndex.BottomCenter.rawValue]
                        outerPoint1 = cropView.cropHandles[CGCropHandleIndex.TopRight.rawValue].frame.origin
                        outerPoint2 = cropView.cropHandles[CGCropHandleIndex.BottomLeft.rawValue].frame.origin
                        
                    case CGCropHandleIndex.BottomLeft.rawValue:
                        side1 = cropView.cropHandles[CGCropHandleIndex.LeftCenter.rawValue]
                        side2 = cropView.cropHandles[CGCropHandleIndex.BottomCenter.rawValue]
                        outerPoint1 = cropView.cropHandles[CGCropHandleIndex.TopLeft.rawValue].frame.origin
                        outerPoint2 = cropView.cropHandles[CGCropHandleIndex.BottomRight.rawValue].frame.origin
                        
                    default:
                        break
                    }
                    
                    // Calculate midpoints for side handles next to this corner handle
                    let mid1 = CGPointMake((grabHandle.frame.origin.x + outerPoint1.x) / 2, (grabHandle.frame.origin.y + outerPoint1.y) / 2)
                    let mid2 = CGPointMake((grabHandle.frame.origin.x + outerPoint2.x) / 2, (grabHandle.frame.origin.y + outerPoint2.y) / 2)
                    // Set the current two side handles to their new locations
                    var sideRect1 = side1.frame
                    var sideRect2 = side2.frame
                    sideRect1.origin = mid1
                    sideRect2.origin = mid2
                    side1.frame = sideRect1
                    side2.frame = sideRect2
                    
                    // Reset the view frames to our modified rects
                    grabHandle.frame = handleRect
                    cent.frame = cenRec
                }
            }
        }
    }
}
