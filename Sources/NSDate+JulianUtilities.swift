import Foundation

extension NSDate {

	@nonobjc static let DayInMilliseconds: NSTimeInterval = 1000 * 60 * 60 * 24 /// Number of milliseconds in one day
	@nonobjc static let JulianUnixEpoch: NSTimeInterval = 2440588 /// The Julian representation of the Unix Epoch
	@nonobjc static let Julian2000: NSTimeInterval = 2451545 /// The Julian representation of the new millenium
	@nonobjc static let Julian0: NSTimeInterval = 0.0009

	var julianRepresentation: NSTimeInterval { /// Returns the Julian representation of `self`
		return timeIntervalSince1970 / NSDate.DayInMilliseconds - 0.5 + NSDate.JulianUnixEpoch
	}

	var daysSince2000: Double { /// Returns the number of Julian days since January 01, 2000 that `self` corresponds to.
		return julianRepresentation - NSDate.Julian2000
	}

	convenience init(julianDate: NSTimeInterval) { /// Initializes a proper NSDate from its Julian representation.
		self.init(timeIntervalSince1970: (julianDate + 0.5 - NSDate.JulianUnixEpoch) * NSDate.DayInMilliseconds)	
	}

}
