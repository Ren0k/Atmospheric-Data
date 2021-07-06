//////////////////////////////////////////
// Time Class                           //
// By Ren0k                             //
//////////////////////////////////////////
@LAZYGLOBAL off.

function ClassTime {
    parameter       selectedBody is ship:body,
                    selectedShip is ship.

    // Current State
    local currentBody is selectedBody.
    local currentShip is selectedShip.

    // Variables
    local sunBody is body("Sun").
    local locationUpVector is 0.
    local locationSunVector is 0.
    local locationSideVector is 0.
    local rotLngShift is 0.
    local obtLngShift is 0.
    local totLngShift is 0.
    local futureLocation is 0.
    local timeLocation is 0.
    local arcVal1 is 0.
    local arcVal2 is 0.
    local hourTime is 0.
    local minuteTime is 0.
    local secondTime is 0.
    local secondsInDay is 0.
    local secondsInHour is 0.

    // Strings
    local stringZeroFormat is "0{0}".
    local stringClockFormat is "{0}:{1}:{2}".

    function getTemperatureTime {
        parameter       location is currentShip:geoposition,
                        timeToCalc is 0,
                        curBody is currentBody,
                        curBodyPosition is currentBody:position.

        // Returns a float between 0-1 where Tmin is 0 and Tmax is 1.
        // Optionally a moment in the future, corrected for kerbins rotation and orbit

        if timeToCalc = 0 {
            set locationUpVector to (LatLng(0, location:lng-45):position-curBodyPosition):normalized.
            set locationSunVector to (sunBody:position - LatLng(0, location:lng):position):normalized.
            return (vdot(locationSunVector, locationUpVector)+1)/2.
        } else {
            set rotLngShift to (timeToCalc/curBody:rotationperiod)*360.
            set obtLngShift to (timeToCalc/curBody:orbit:period)*360.
            set totLngShift to rotLngShift+obtLngShift.
            set futureLocation to LatLng(0, location:lng+totLngShift).
            set locationUpVector to (LatLng(0, futureLocation:lng-45):position-curBodyPosition):normalized.
            set locationSunVector to (sunBody:position-futureLocation:position):normalized.
            return (vdot(locationSunVector,locationUpVector)+1)/2.
        }
    }

    function getInstantTemperatureTime {
        // Just returns the actual present scalar temperature time without parameters
        set futureLocation to currentShip:geoposition.
        set locationUpVector to (LatLng(0, futureLocation:lng-45):position-currentBody:position):normalized.
        set locationSunVector to (sunBody:position - LatLng(0, futureLocation:lng):position):normalized.
        return (vdot(locationSunVector, locationUpVector)+1)/2.
    }

    function getClockTime {
        parameter       location is currentShip:geoposition,
                        timeToCalc is 0,
                        curBody is currentBody,
                        curBodyPosition is currentBody:position.

        // Returns the local time in a string as a clock value
        // Optionally a moment in the future, corrected for kerbins rotation and orbit

        set timeLocation to location.

        if timeToCalc <> 0 {
            set rotLngShift to (timeToCalc/curBody:rotationperiod)*360.
            set obtLngShift to (timeToCalc/curBody:orbit:period)*360.
            set totLngShift to rotLngShift+obtLngShift.
            set timeLocation to LatLng(0, location:lng+totLngShift).
        }

        set locationUpVector to (LatLng(0, timeLocation:lng):position-curBodyPosition):normalized.
        set locationSideVector to (LatLng(0, timeLocation:lng-90):position-curBodyPosition):normalized.
        set locationSunVector to (sunBody:position - LatLng(0, timeLocation:lng):position):normalized.
        set arcVal1 to vdot(locationSunVector, locationSideVector).
        set arcVal2 to vdot(locationSunVector, locationUpVector).
        set hourTime to ((arctan2(arcVal1, arcVal2)+180)/360)*24.
        set minuteTime to (hourTime-floor(hourTime,0))*60.
        set secondTime to (minuteTime-floor(minuteTime,0))*60.
        set hourTime to floor(hourTime,0).
        set minuteTime to floor(minuteTime,0).
        set secondTime to floor(secondTime,0).
        if hourTime:tostring:length < 2 set hourTime to stringZeroFormat:format(hourTime).
        if minuteTime:tostring:length < 2 set minuteTime to stringZeroFormat:format(minuteTime).
        if secondTime:tostring:length < 2 set secondTime to stringZeroFormat:format(secondTime).
        return(stringClockFormat:format(hourTime, minuteTime, secondTime)).
    }

    function getInstantClockTime {
        // Returns the current local time in a string as a clock value without parameters -> fastest method
        set timeLocation to currentShip:geoposition.
        set locationUpVector to (LatLng(0, timeLocation:lng):position-currentBody:position):normalized.
        set locationSideVector to (LatLng(0, timeLocation:lng-90):position-currentBody:position):normalized.
        set locationSunVector to (sunBody:position - LatLng(0, timeLocation:lng):position):normalized.
        set arcVal1 to vdot(locationSunVector, locationSideVector).
        set arcVal2 to vdot(locationSunVector, locationUpVector).
        set hourTime to ((arctan2(arcVal1, arcVal2)+180)/360)*24.
        set minuteTime to (hourTime-floor(hourTime,0))*60.
        set secondTime to (minuteTime-floor(minuteTime,0))*60.
        set hourTime to floor(hourTime,0).
        set minuteTime to floor(minuteTime,0).
        set secondTime to floor(secondTime,0).
        if hourTime:tostring:length < 2 set hourTime to stringZeroFormat:format(hourTime).
        if minuteTime:tostring:length < 2 set minuteTime to stringZeroFormat:format(minuteTime).
        if secondTime:tostring:length < 2 set secondTime to stringZeroFormat:format(secondTime).
        return(stringClockFormat:format(hourTime, minuteTime, secondTime)).

    }

    function secondsToClock {
        parameter       seconds.

        set secondsInDay to mod(seconds, 86400).
        set secondsInHour to mod(secondsInDay, 3600).
        set hourTime to round(floor(secondsInDay/3600,0),0):tostring.
        set minuteTime to round(floor(secondsInHour/60, 0),0):tostring.
        set secondTime to round(mod(secondsInHour, 60),0):tostring.
        if hourTime:length < 2 set hourTime to stringZeroFormat:format(hourTime).
        if minuteTime:length < 2 set minuteTime to stringZeroFormat:format(minuteTime).
        if secondTime:length < 2 set secondTime to stringZeroFormat:format(secondTime).
        return(stringClockFormat:format(hourTime, minuteTime, secondTime)).
    }

    return lexicon(
        "Scalar", getTemperatureTime@,
        "InstScalar", getInstantTemperatureTime@,
        "Clock", getClockTime@,
        "InstClock", getInstantClockTime@,
        "SecondsToClock", secondsToClock@
    ).
}