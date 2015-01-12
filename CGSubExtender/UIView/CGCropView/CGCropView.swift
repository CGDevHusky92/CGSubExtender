//
//  CGCropView.swift
//  CGCrop
//
//  Created by Charles Gorectke on 11/20/14.
//  Copyright (c) 2014 Revision Works, LLC. All rights reserved.
//

import UIKit

public enum CGCropHandleIndex: Int {
    case TopLeft = 0
    case TopCenter, TopRight, RightCenter, BottomRight, BottomCenter, BottomLeft, LeftCenter
}

public class CGCropView: UIView {
    
    var hideCorners: Bool = false
    var doneCropping: Bool = false
    var setupComplete: Bool = false
    
    var cropPoints = [CGPoint]()
    public var cropHandles: [UIView] = [UIView]()
    
    var centroid: UIView?
    var grabbedHandle: UIView?
    var grabbedHandleIndex: Int?
    
    var handleAlphaBase: CGFloat = 0.6
    var handleAlphaTouch: CGFloat = 0.9
    var handleSize: CGFloat {
        get {
//            if let imageView = parentImageView { }
            return 35.0
        }
    }
    
    var lineColor: UIColor {
        get {
//            if let imageView = parentImageView { }
            return UIColor.redColor()
        }
    }
    
    var lineWidth: CGFloat {
        get {
//            if let imageView = parentImageView { }
            return 2.0
        }
    }
    
    private var currentPath: CGPathRef!
    
    public func setupCropView() {
        if !doneCropping {
            if cropHandles.count > 0 {
                for view in cropHandles { view.removeFromSuperview() }
                if let cent = centroid { cent.removeFromSuperview() }
                cropHandles.removeAll(keepCapacity: false)
            }
            
            let topLeft     = CGPointMake(center.x - self.frame.size.width / 4,
                center.y - self.frame.size.height / 4)
            let topRight    = CGPointMake(center.x + self.frame.size.width / 4,
                center.y - self.frame.size.height / 4)
            let bottomRight = CGPointMake(center.x + self.frame.size.width / 4,
                center.y + self.frame.size.height / 4)
            let bottomLeft  = CGPointMake(center.x - self.frame.size.width / 4,
                center.y + self.frame.size.height / 4)
            
            cropPoints = [ topLeft, topRight, bottomRight, bottomLeft ]
            
            // Sums to keep track of total x/y vals for calculating the centroid of the region
            var xSum: CGFloat = 0.0
            var ySum: CGFloat = 0.0
            
            // Create handle subviews
            for (index, pointValue) in enumerate(self.cropPoints) {
                let currentPoint: CGPoint = pointValue
                
                // Update the sums
                xSum += currentPoint.x
                ySum += currentPoint.y
                
                // Frame based on current point
                let handleFrame = CGRectMake(currentPoint.x - self.handleSize / 2,
                    currentPoint.y - self.handleSize / 2,
                    self.handleSize,
                    self.handleSize)
                
                // Init handle
                let currentHandle = UIView(frame: handleFrame)
                
                // Set options for handle view
                currentHandle.alpha              = self.handleAlphaBase
                currentHandle.backgroundColor    = UIColor.whiteColor()
                currentHandle.layer.borderColor  = self.lineColor.CGColor
                currentHandle.layer.borderWidth  = self.lineWidth
                currentHandle.layer.cornerRadius = self.handleSize / 2
                currentHandle.setTranslatesAutoresizingMaskIntoConstraints(false)
                
                // Hide the corner handles when cropping a field (unneeded and less clutter)
                if self.hideCorners {
                    currentHandle.hidden = true
                }
                
                // Add handle view to crop view
                self.addSubview(currentHandle)
                
                // Save reference to handle view
                self.cropHandles.append(currentHandle)
                
                // Add side handle at the midpoint between the current point and the next point:
                var nextIndex: Int = 0
                // Determine next point index
                if (index == cropPoints.count - 1) {
                    nextIndex = 0
                } else {
                    nextIndex = index + 1
                }
                
                let nextPoint = cropPoints[nextIndex]
                
                // Calculate midpoint
                let midPoint = CGPointMake((currentPoint.x + nextPoint.x) / 2,
                    (currentPoint.y + nextPoint.y) / 2)
                
                // Create the view for this mid handle
                let midFrame = CGRectMake(midPoint.x - handleSize / 2,
                    midPoint.y - handleSize / 2,
                    handleSize,
                    handleSize)
                
                let midHandle = UIView(frame: midFrame)
                
                midHandle.alpha              = handleAlphaBase
                midHandle.backgroundColor    = UIColor.whiteColor()
                midHandle.layer.borderColor  = lineColor.CGColor
                midHandle.layer.borderWidth  = lineWidth
                midHandle.layer.cornerRadius = handleSize / 2
                midHandle.setTranslatesAutoresizingMaskIntoConstraints(false)
                
                // Add to view
                self.addSubview(midHandle)
                self.cropHandles.append(midHandle)
            }
            
            // Average the x/y sums
            let centerX = xSum / 4
            let centerY = ySum / 4
            
            // Create the centroid view
            let centerFrame = CGRectMake(centerX - handleSize / 4,
                centerY - handleSize / 4,
                handleSize / 2,
                handleSize / 2)
            
            // Set options on centroid view
            centroid = UIView(frame: centerFrame)
            if let cent = centroid {
                cent.alpha              = 1.0
                cent.backgroundColor    = UIColor.whiteColor()
                cent.layer.borderColor  = self.lineColor.CGColor
                cent.layer.borderWidth  = self.lineWidth
                cent.layer.cornerRadius = self.handleSize / 2
                cent.setTranslatesAutoresizingMaskIntoConstraints(false)
                self.addSubview(cent)
            }
        }
        
        // No handle has been grabbed
        grabbedHandle = nil
        
        // Reset crop state
        doneCropping = false
    }
    
    func selectionContainsPoint(point: CGPoint) -> Bool {
        return CGPathContainsPoint(currentPath, nil, point, false)
    }
    
    public override func drawRect(rect: CGRect) {
        if !doneCropping {
            // Get current context and clear the frame for drawing
            let context = UIGraphicsGetCurrentContext()
            CGContextClearRect(context, self.frame)
            
            // Dim view - Only excluded region will display be dimmed
            CGContextSetFillColorWithColor(context, UIColor.clearColor().colorWithAlphaComponent(0.4).CGColor)
            CGContextFillRect(context, self.frame)
            
            // Get color values to set stroke
            let color = CGColorGetComponents(self.lineColor.CGColor)
            
            // Set options
            CGContextSetRGBStrokeColor(context, color[0], color[1], color[2], color[3])
            CGContextSetLineWidth(context, self.lineWidth);
            CGContextSetFillColorWithColor(context, UIColor.clearColor().CGColor)
            
            // Path being constructed
            let cropPath = CGPathCreateMutable()
            
            // Connect lines between all handles
            for var i = 0; i < self.cropHandles.count; i++ {
                let curHandle: UIView = self.cropHandles[i] as UIView
                if (i == 0) {
                    CGPathMoveToPoint(cropPath, nil,
                        curHandle.frame.origin.x + handleSize / 2,
                        curHandle.frame.origin.y + handleSize / 2)
                } else {
                    CGPathAddLineToPoint(cropPath, nil,
                        curHandle.frame.origin.x + handleSize / 2,
                        curHandle.frame.origin.y + handleSize / 2)
                }
            }
            
            // Close the path
            CGPathCloseSubpath(cropPath)
            
            // Save the path
            currentPath = CGPathCreateCopy(cropPath)
            
            // Set to blend clear for path fill
            CGContextSetBlendMode(context, kCGBlendModeClear)
            
            // Fill the path
            CGContextAddPath(context, cropPath)
            CGContextFillPath(context)
            
            // Reset blending
            CGContextSetBlendMode(context, kCGBlendModeNormal)
            
            // Stroke the path
            CGContextAddPath(context, cropPath)
            CGContextStrokePath(context)
        }
    }

}
