//
//  CatmullRom.swift
//  NoteTakerApp
//
//  Created by Alexandru Ariton on 03.07.2022.
//

#if os(iOS)
import UIKit

extension UIBezierPath {
	static func from(normalizedLine line: Stroke) -> UIBezierPath? {
		if line.points.count < 1 {
			return nil
		}
		let path = UIBezierPath()
		path.lineJoinStyle = .round
		path.lineCapStyle = .round
		path.lineWidth = 10
		path.move(to: line.points[0])
		var points = [CGPoint]()
		if line.points.count > 3 {
			for n in 1...line.points.count-2 {
				points.append((line.points[n-1] + line.points[n] + line.points[n+1]) / 3)
			}
		} else {
			points = line.points
		}
		
		for point in points {
			path.addLine(to: point)
		}
		return path
	}
}
#elseif os(macOS)


#endif
