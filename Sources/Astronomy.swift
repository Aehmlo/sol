import Foundation

#if os(Linux)
import Glibc
#else
import Darwin
#endif

let earthObliquity = 23.4397 * radianConversionFactor

typealias Angle = Double

// General solar stuff

// Orbit stuff

func solarMeanAnomaly(date date: NSDate) -> Angle { /// Returns the mean anomaly (position that Earth would be in relative to its perihelion in a circular orbit) for `date`.
	return (357.5291 + ((date.julianRepresentation - NSDate.Julian2000) * 0.98560028)) * radianConversionFactor
}

// Ecliptic coordinates

func eclipticLongitude(meanAnomaly anomaly: Angle) -> Angle { /// Returns the ecliptic longitude of the Earth given its mean anomaly.
	let center = (1.9148 * sin(anomaly) + 0.02 * sin(2 * anomaly) + 0.0003 * sin(3 * anomaly)) * radianConversionFactor
	let earthPerihelion = 102.9372 * radianConversionFactor

	return anomaly + center + earthPerihelion + π
}

func eclipticLongitude(date date: NSDate) -> Angle { /// Convenience method that returns ecliptic longitude given only a date by first calculating hte mean anomaly.
	return eclipticLongitude(meanAnomaly: solarMeanAnomaly(date: date))
}

// General position calculations

// Equatorial coordinates

func declination(eclipticLongitude longitude: Angle, eclipticLatitude latitude: Angle) -> Angle { /// Returns the declination (δ) of the Sun given ecliptic latitude and longitude.
	return asin((sin(latitude) * cos(earthObliquity)) + (cos(latitude) * sin(longitude) * sin(earthObliquity)))
}

func declination(date date: NSDate) -> Angle { /// Convenience method that returns the declination of the Sun at a given date.
	return declination(eclipticLongitude: eclipticLongitude(date: date), eclipticLatitude: 0)
}

func rightAscension(eclipticLongitude longitude: Angle, eclipticLatitude latitude: Angle) -> Angle { /// Returns the right ascension (α) of the Sun given ecliptic latitude and longitude.
	let y = sin(longitude) * cos(earthObliquity) - tan(latitude) * sin(earthObliquity)
	let x = cos(longitude)
	return atan(y/x) // TODO: Investigate to ensure this is actually correct
}

func rightAscension(date date: NSDate) -> Angle { /// Convenience method that returns the right ascension of the Sun at a given date.
	return rightAscension(eclipticLongitude: eclipticLongitude(date: date), eclipticLatitude: 0) // TODO: Verify that this works properly
}

// As seen by the observer on Earth

// Azimuth, altitude, sidereal time, and refraction

func azimuth(time time: Angle, latitude: Angle, declination: Angle) -> Angle {
	let y = sin(time)
	let x = (cos(time) * sin(latitude)) - (tan(declination) * cos(latitude))
	return atan(y/x)
}

func altitude(time time: Angle, latitude: Angle, declination: Angle) -> Angle {
	return asin((sin(latitude) * sin(declination)) + (cos(latitude) * cos(declination) * cos(time)))
}

func siderealTime(days days: Double, longitude: Double) -> Angle { /// Returns the sidereal time for the day `days` days after Julian 2000 at the given longitude.
	return (280.1600 + (360.9856235 * days) - longitude) * radianConversionFactor
}

func siderealTime(date date: NSDate, longitude: Double) -> Angle { /// Convenience method for `siderealTime(days:longitude:)`.
	return siderealTime(days: date.daysSince2000, longitude: longitude)
}

func refraction(altitude: Double) -> Double { /// Returns the astronomical refraction for the given altitude (in radians).
	let h = max(altitude, 0) // Positive altitudes only
	return 0.0002967 / tan(h + 0.00312536 / (h + 0.08901179)) // Here be dragons
}

// More stuff

func julianCycle(days days: Double, longitude: Angle) -> Double {
	return round(days - NSDate.Julian0 - (longitude / (2 * π)))
}

func julianCycle(date date: NSDate, longitude: Angle) -> Int {
	return julianCycle(days: date.daysSince2000, longitude: longitude)
}

func approximateTransit(time time: Angle, longitude: Angle, days: Double) -> Double {
	let n = julianCycle(days: days, longitude: longitude)
	return NSDate.Julian0 + ((time + longitude) / (2 * π)) + n
}

func approximateTransit(time time: Angle, longitude: Angle, date: NSDate) -> Double {
	return approximateTransit(time: time, longitude: longitude, days: date.daysSince2000)
}

func solarTransitDay(approximateTransit transit: Double, meanAnomaly anomaly: Angle, eclipticLongitude longitude: Angle) -> Double { /// Returns the Julian day of the solar transit in question
	return NSDate.Julian2000 + transit + (0.0053 * sin(anomaly)) - (0.0069 * sin(2 * longitude))
}

func hourAngle(altitude altitude: Angle, latitude: Angle, declination: Angle) -> Angle { /// Returns the hour angle for a given sun altitude and declination and at a certain latitude.
	return acos((sin(altitude) - (sin(latitude) * sin(declination))) / (cos(latitude) * cos(declination)))
}

func sunsetDay(altitude altitude: Angle, longitude: Angle, latitude: Angle, declination: Angle, days: Double, meanAnomaly: Angle, eclipticLongitude: Angle) -> Double { /// Returns the Julian day for sunset time 
	let transit = approximateTransit(time: hourAngle(altitude: altitude, latitude: latitude, declination: declination), longitude: longitude, days: days)
	return solarTransitDay(approximateTransit: transit, meanAnomaly: meanAnomaly, eclipticLongitude: eclipticLongitude)
}

// Structures to encapsulate coordinate and position information

struct SunCoordinates {

	let declination: Angle
	let rightAscension: Angle

	init(date d: NSDate?) {
		let date = d ?? NSDate()
		let longitude = eclipticLongitude(date: date)
		declination = declination(eclipticLongitude: longitude, eclipticLatitude: 0)
		rightAscension = rightAscension(eclipticLongitude: longitude, eclipticLatitude: 0)
	}

}

struct SunPosition {

	let azimuth: Double
	let altitude: Double

	init(date d: NSDate?, latitude lat: Double, longitude long: Double) { // Latitude, longitude in degrees
		let date = d ?? NSDate()
		let lat = radianConversionFactor * lat
		let long = radianConversionFactor * -long
		let coordinates = SunCoordinates(date: date)
		let longitude = long * radianConversionFactor
		let latitude = lat * radianConversionFactor
		let time = siderealTime(date: date, longitude: longitude) - coordinates.rightAscension
		azimuth = azimuth(time: time, latitude: latitude, declination: coordinates.declination)
		altitude = altitude(time: time, latitude: latitude, declination: coordinates.declination)
	}

}

// Time to set up the actual sunrise/sunset event stuff!

typealias Name = (String, String) // (MorningName, NightName)
typealias Event = [Angle: Name]

let significantEvents: [Event] = [ // https://github.com/mourner/suncalc/blob/master/suncalc.js#L103,L108
	[-0.833: ("sunrise", "sunset")],
	[-0.3: ("sunriseEnd", "sunsetStart")],
	[-6: ("dawn", "dusk")],
	[-12: ("nauticalDawn", "nauticalDusk")],
	[-18: ("nightEnd", "night")],
	[6: ("goldenHourEnd", "goldenHour")]
]