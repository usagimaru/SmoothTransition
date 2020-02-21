//
//  ViewController.swift
//  SmoothTransition
//
//  Created by usagimaru on 2020/02/22.
//  Copyright © 2020 usagimaru. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
	
	@IBOutlet weak var object: UIView!
	@IBOutlet var panGesture: UIPanGestureRecognizer!
	
	private let margin: CGFloat = 16
	private var gestureGap: CGPoint?

	override func viewDidLoad() {
		super.viewDidLoad()
		
		self.panGesture.addTarget(self, action: #selector(pan(_:)))
		
		self.object.backgroundColor = UIColor.systemBlue
		self.object.layer.cornerCurve = .continuous
		self.object.layer.cornerRadius = 20
	}
	
	@objc func pan(_ gesture: UIPanGestureRecognizer) {
		switch gesture.state {
		case .began:
			// ジェスチャ座標とオブジェクトの中心座標までの“ギャップ”を計算
			
			let location = gesture.location(in: self.view)
			let gap = CGPoint(x: self.object.center.x - location.x, y: self.object.center.y - location.y)
			self.gestureGap = gap
		
		case .ended:
			let lastObjectLocation = self.object.center
			let velocity = gesture.velocity(in: self.view) // points per second
			
			// 仮想の移動先を計算
			let projectedPosition = CGPoint(x: lastObjectLocation.x + project(initialVelocity: velocity.x, decelerationRate: .normal),
											y: lastObjectLocation.y + project(initialVelocity: velocity.y, decelerationRate: .normal))
			// 最適な移動先を計算
			let destination = nearestCornerPosition(projectedPosition)
			
			let initialVelocity = initialAnimationVelocity(for: velocity, from: self.object.center, to: destination)
			
			// iOSの一般的な動きに近い動きを再現
			let parameters = UISpringTimingParameters(dampingRatio: 0.5, initialVelocity: initialVelocity)
			let animator = UIViewPropertyAnimator(duration: 1.0, timingParameters: parameters)
			
			animator.addAnimations {
				self.object.center = destination
			}
			animator.startAnimation()
			
			self.gestureGap = nil
			
		default:
			// ジェスチャに合わせてオブジェクトをドラッグ
			
			let gestureGap = self.gestureGap ?? CGPoint.zero
			let location = gesture.location(in: self.view)
			let destination = CGPoint(x: location.x + gestureGap.x, y: location.y + gestureGap.y)
			self.object.center = destination

		}
	}
	
	
	// アニメーション開始時の変化率を計算
	private func initialAnimationVelocity(for gestureVelocity: CGPoint, from currentPosition: CGPoint, to finalPosition: CGPoint) -> CGVector {
		// https://developer.apple.com/documentation/uikit/uispringtimingparameters/1649909-initialvelocity
		
		var animationVelocity = CGVector.zero
		let xDistance = finalPosition.x - currentPosition.x
		let yDistance = finalPosition.y - currentPosition.y
		
		if xDistance != 0 {
			animationVelocity.dx = gestureVelocity.x / xDistance
		}
		if yDistance != 0 {
			animationVelocity.dy = gestureVelocity.y / yDistance
		}
		
		return animationVelocity
	}
	
	// 仮想の移動先を計算
	private func project(initialVelocity: CGFloat, decelerationRate: UIScrollView.DecelerationRate) -> CGFloat {
		// https://developer.apple.com/videos/play/wwdc2018/803/
		
		return (initialVelocity / 1000.0) * decelerationRate.rawValue / (1.0 - decelerationRate.rawValue)
	}
	
	// 引数にもっとも近い位置を返す
	private func nearestCornerPosition(_ projectedPosition: CGPoint) -> CGPoint {
		let destinations = cornerPositions()
		let nearestPosition = destinations.sorted(by: {
			return distance(from: $0, to: projectedPosition) < distance(from: $1, to: projectedPosition)
		}).first!
		
		print(#function, "\(nearestPosition), \(projectedPosition)")
		
		return nearestPosition
	}
	
	private func distance(from: CGPoint, to: CGPoint) -> CGFloat {
		return sqrt(pow(from.x - to.x, 2) + pow(from.y - to.y, 2))
	}
	
	private func cornerPositions() -> [CGPoint] {
		let viewSize = self.view.size
		let objectSize = self.object.size
		let xCenter = self.object.width / 2
		let yCenter = self.object.height / 2
		
		let top_left = CGPoint(x: self.margin + xCenter, y: self.margin + yCenter)
		let top_right = CGPoint(x: viewSize.width - objectSize.width - self.margin + xCenter, y: self.margin + yCenter)
		let bottom_left = CGPoint(x: self.margin + xCenter, y: viewSize.height - objectSize.height - self.margin + yCenter)
		let bottom_right = CGPoint(x: viewSize.width - objectSize.width - self.margin + xCenter, y: viewSize.height - objectSize.height - self.margin + yCenter)
		let destinations = [CGPoint](arrayLiteral: top_left, top_right, bottom_left, bottom_right)
		
		return destinations
	}

}

