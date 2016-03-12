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

func declination(eclipticLongitude longitude: Angle, eclipticLatitude latitude: Angle) -> Angle { /// Returns the declination (δ) of the Sun given ecliptic latitude and longitude.
	return asin((sin(latitude) * cos(e)) + (cos(latitude) * sin(longitude) * sin(earthObliquity)))
}

func declination(date date: NSDate) -> Angle { /// Convenience method that returns the declination of the Sun at a given date.
	return declination(eclipticLongitude: eclipticLongitude(date: date), eclipticLatitude: eclipticLatitude(date: date))
}

func rightAscension(eclipticLongitude longitude: Angle, eclipticLatitude latitude: Angle) -> Angle { /// Returns the right ascension (α) of the Sun given ecliptic latitude and longitude.
	let y = sin(longitude) * cos(earthObliquity) - tan(latitude) * sin(earthObliquity)
	let x = cos(longitude)
	return atan(y/x) // TODO: Investigate to ensure this is actually correct
}

func rightAscension(date date: NSDate) -> Angle { /// Convenience method that returns the right ascension of the Sun at a given date.
	return rightAscension(eclipticLongitude: eclipticLongitude(date: date), eclipticLatitude: eclipticLatitude(date: date))
}

func azimuth(time time: Angle, latitude: Angle, declination: Angle) -> Angle {
	let y = sin(time)
	let x = (cos(time) * sin(latitude)) - (tan(declination) * cos(latitude))
	return atan(y/x)
}

func altitude(time time: Angle, latitude: Angle, declination: Angle) -> Angle {
	return asin((sin(latitude) * sin(declination)) + (cos(latitude) * cos(declination) * cos(time)))
}

func siderealTime(days days: Float, longitude: Float) -> Angle { /// Returns the sidereal time for the day `days` days after Julian 2000 at the given longitude.
	return (280.1600 + (360.9856235 * days) - longitude) * radianConversionFactor
}

func siderealTime(date date: NSDate, longitude: Float) -> Angle { /// Convenience method for `siderealTime(days:longitude:)`.
	return siderealTime(days: date.daysSince2000, longitude: longitude)
}

func refraction(altitude: Float) -> Float { /// Returns the astronomical refraction for the given altitude (in radians).
	let h = max(altitude, 0) // Positive altitudes only
	return 0.0002967 / tan(h + 0.00312536 / (h + 0.08901179)) // Here be dragons
}

struct SunCoordinates {

	let declination: Angle
	let rightAscension: Angle

	init(date d: NSDate?) {
		let date = d ?? NSDate()
		let longitude = eclipticLongitude(date: date)
		declination = declination(longitude, 0)
		rightAscension = rightAscension(longitude, 0)
	}

}

Struct SunPosition {

	let azimuth: Float
	let altitude: Float

	init(date d: NSDate?, latitude: Float) { // Latitude in degrees
		let date = d ?? NSDate()
		let latitude = radianConversionFactor * latitude
		let longitude = radianConversionFactor * -longitude
		let coordinates = SunCoordinates(date: date)
		let time = siderealTime(date: date, longitude: longitude) - coordinates.rightAscension
		azimuth = azimuth(time: time, latitude: latitude, declination: coordinates.declination)
		altitude = altitude(time: time, latitude: latitude, declination: coordinates.declination)
	}

}