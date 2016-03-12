import Foundation

let earthObliquity = 23.4397 * radianConversionFactor

typealias Angle = Float

func solarMeanAnomaly(date date: NSDate) -> Angle { /// Returns the mean anomaly (position that Earth would be in relative to its perihelion in a circular orbit) for `date`.
	return (357.5291 + ((date.julianRepresentation - NSDate.Julian2000) * 0.98560028)) * radianConversionFactor
}

func eclipticLongitude(meanAnomaly anomaly: Float) -> Angle { /// Returns the ecliptic longitude of the Earth given its mean anomaly.
	let center = (1.9148 * sin(anomaly) + 0.02 * sin(2 * anomaly) + 0.0003 * sin(3 * anomaly)) * radianConversionFactor
	let earthPerihelion = 102.9372 * radianConversionFactor

	return anomaly + center + earthPerihelion + π
}

func eclipticLongitude(date date: NSDate) -> Angle { /// Convenience method that returns ecliptic longitude given only a date by first calculating hte mean anomaly.
	return eclipticLongitude(meanAnomaly: solarMeanAnomaly(date: date))
}