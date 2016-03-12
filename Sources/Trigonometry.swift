#if os(Linux)
import Glibc
#else
import Darwin
#endif

public let π = M_PI
public let radianConversionFactor = π/180 // This is just as legible as an extension on number types would be, and less crowding.

