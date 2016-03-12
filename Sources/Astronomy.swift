import Foundation

let earthObliquity = 23.4397 * radianConversionFactor

typealias Angle = Float

func solarMeanAnomoly(date date: NSDate) -> Angle { /// Returns the mean anomoly (position that Earth would be in relative to its perihelion in a circular orbit) for `date`.
	return (357.5291 + ((date.julianRepresentation - NSDate.Julian2000) * 0.98560028)) * radianConversionFactor
}