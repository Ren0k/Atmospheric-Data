//////////////////////////////////////////
// Atmospheric Data                     //
// By Ren0k                             //
//////////////////////////////////////////
@lazyGlobal off.

function getAtmosphericData {
    // PUBLIC getAtmosphericData :: body -> lexicon
    parameter       selectedBody is ship:body,
                    selectedShip is ship.

    local currentBody is selectedBody.
    local currentShip is selectedShip.

    local bodyParameters is lexicon().
    local molarmass is currentBody:atm:molarmass.
    local gasConstant is constant:idealgas.
    local adiabaticIndex is currentBody:atm:adiabaticindex.
    local SGC is (gasConstant/molarmass).
    local normFactor is 0.
    local t is 0.
    local index is 0.

    function hermiteInterpolator {
        // PRIVATE hermiteInterpolator :: float x7 -> float
        parameter       x0 is 0,
                        x1 is 1,
                        y0 is 0,
                        y1 is 1,
                        m0 is 0,
                        m1 is 0,
                        dataPoint is 1.

        // H(t)=(2t^3-3t^2+1)y0+(t^3-2t^2+t)m0+(-2t^3+3t^2)y1+(t^3-t^2)m1
        // This function returns the y value resulting from position t on the curve

        // x0 = start point
        // x1 = end point
        // y0 = start value
        // y1 = end value
        // m0 = start tangent
        // m1 = end tangent
        // dataPoint = float to get the y value

        set normFactor to (x1-x0).
        set t to (dataPoint-x0)/normFactor.
        set m0 to m0 * (normFactor).
        set m1 to m1 * (normFactor).
        return (2*t^3-3*t^2+1)*y0+(t^3-2*t^2+t)*m0+(-2*t^3+3*t^2)*y1+(t^3-t^2)*m1.
    }

    function getKeyValues {
        // PRIVATE getIndex :: float : 2D Array -> 2D Array
        parameter       inputNumber,
                        keyValues.
        set index to 0.
        for key in keyValues {
            if inputNumber <= key[0] {
                return list(keyValues[index-1], keyValues[index]).
            }
            set index to index+1.
        }
    }

    function getFloatCurves {   
        // PRIVATE getFloatCurves :: nothing -> nothing
        // There are only 5 stock planets with curves, hence some simple if statements
        if currentBody = BODY("Kerbin") {
            runpath("AtmoData/Library/Kerbin/getCurves.ks"). 
            set bodyParameters to getKerbinAtmosphere().
        }
        else if currentBody = BODY("Eve") {
            runpath("AtmoData/Library/Eve/getCurves.ks"). 
            set bodyParameters to getEveAtmosphere().
        }
        else if currentBody = BODY("Jool") {
            runpath("AtmoData/Library/Jool/getCurves.ks"). 
            set bodyParameters to getJoolAtmosphere().
        }
        else if currentBody = BODY("Duna") {
            runpath("AtmoData/Library/Duna/getCurves.ks"). 
            set bodyParameters to getDunaAtmosphere().
        }
        else if currentBody = BODY("Laythe") {
            runpath("AtmoData/Library/Laythe/getCurves.ks"). 
            set bodyParameters to getLaytheAtmosphere().
        }
        else set bodyParameters["Atmosphere"] to false.
    }

    function getTemperatureAltitude {
        // PRIVATE getTemperatureAltitude :: nothing -> kosDelegate
        ////////////////
        // NOT IN USE -> Same results as body:atm:alttemp(altitude)
        ////////////////
        local temperatureAltitudeCurve is bodyParameters["TC"]().
        local startX is temperatureAltitudeCurve[0][0].
        local endX is temperatureAltitudeCurve[temperatureAltitudeCurve:length-1][0].
        local startY is temperatureAltitudeCurve[0][1].
        local endY is temperatureAltitudeCurve[temperatureAltitudeCurve:length-1][1].
        local keyValues is getKeyValues(ship:altitude, temperatureAltitudeCurve).
        local beginKey is keyValues[0].
        local endKey is keyValues[1].
        local hermiteInterpolatorFunction is hermiteInterpolator@:bind(beginKey[0],endKey[0],beginKey[1],endKey[1],beginKey[3],endKey[2]).

        return {// kosDelegate :: float -> float
            parameter       shipAltitude is selectedShip:altitude.

            if (shipAltitude > endKey[0]) or (shipAltitude < beginKey[0]) {
                if shipAltitude <= startX return startY.
                else if shipAltitude >= endX return endY.
                set keyValues to getKeyValues(shipAltitude, temperatureAltitudeCurve).
                set beginKey to keyValues[0].
                set endKey to keyValues[1].
                set hermiteInterpolatorFunction to hermiteInterpolator@:bind(beginKey[0],endKey[0],beginKey[1],endKey[1],beginKey[3],endKey[2]).
            }
            return hermiteInterpolatorFunction(beginKey[0],endKey[0],beginKey[1],endKey[1],beginKey[3],endKey[2],abs(shipAltitude)). }.
    }

    function getTemperatureLatitudeBias {
        // PRIVATE getTemperatureLatitudeBias :: nothing -> kosDelegate
        // The amount by which temperature deviates per latitude
        local latitudeBiasCurve is bodyParameters["TLBC"]().
        local startX is latitudeBiasCurve[0][0].
        local endX is latitudeBiasCurve[latitudeBiasCurve:length-1][0].
        local startY is latitudeBiasCurve[0][1].
        local endY is latitudeBiasCurve[latitudeBiasCurve:length-1][1].
        local keyValues is getKeyValues(abs(selectedShip:geoposition:lat), latitudeBiasCurve).
        local beginKey is keyValues[0].
        local endKey is keyValues[1].
        local hermiteInterpolatorFunction is hermiteInterpolator@:bind(beginKey[0],endKey[0],beginKey[1],endKey[1],beginKey[3],endKey[2]).

        return {// kosDelegate :: float -> float
            parameter       shipLatitude is abs(selectedShip:geoposition:lat).

            if (shipLatitude > endKey[0]) or (shipLatitude < beginKey[0]) {
                if shipLatitude <= startX return startY.
                else if shipLatitude >= endX return endY.
                set keyValues to getKeyValues(shipLatitude, latitudeBiasCurve).
                set beginKey to keyValues[0].
                set endKey to keyValues[1].
                set hermiteInterpolatorFunction to hermiteInterpolator@:bind(beginKey[0],endKey[0],beginKey[1],endKey[1],beginKey[3],endKey[2]).
            }
            return hermiteInterpolatorFunction(abs(shipLatitude)). }.
    }

    function getTemperatureLatitudeSunMult {
        // PRIVATE getTemperatureLatitudeSunMult :: nothing -> kosDelegate
        // The amount of diurnal variation
        local temperatureLatitudeSunMultCurve is bodyParameters["TLSMC"]().
        local startX is temperatureLatitudeSunMultCurve[0][0].
        local endX is temperatureLatitudeSunMultCurve[temperatureLatitudeSunMultCurve:length-1][0].
        local startY is temperatureLatitudeSunMultCurve[0][1].
        local endY is temperatureLatitudeSunMultCurve[temperatureLatitudeSunMultCurve:length-1][1].
        local keyValues is getKeyValues(abs(selectedShip:geoposition:lat), temperatureLatitudeSunMultCurve).
        local beginKey is keyValues[0].
        local endKey is keyValues[1].
        local hermiteInterpolatorFunction is hermiteInterpolator@:bind(beginKey[0],endKey[0],beginKey[1],endKey[1],beginKey[3],endKey[2]).

        return {// kosDelegate :: float -> float
            parameter       shipLatitude is abs(selectedShip:geoposition:lat).
            if (shipLatitude > endKey[0]) or (shipLatitude < beginKey[0]) {
                if shipLatitude <= startX return startY.
                else if shipLatitude >= endX return endY.
                set keyValues to getKeyValues(shipLatitude, temperatureLatitudeSunMultCurve).
                set beginKey to keyValues[0].
                set endKey to keyValues[1].
                set hermiteInterpolatorFunction to hermiteInterpolator@:bind(beginKey[0],endKey[0],beginKey[1],endKey[1],beginKey[3],endKey[2]).
            }
            return hermiteInterpolatorFunction(abs(shipLatitude)). }.
    }

    function getTemperatureSunMult {
        // PRIVATE getTemperatureSunMult :: nothing -> kosDelegate
        // Defines how atmosphereTemperatureOffset varies with altitude
        local temperatureSunMultCurve is bodyParameters["TSMC"]().
        local startX is temperatureSunMultCurve[0][0].
        local endX is temperatureSunMultCurve[temperatureSunMultCurve:length-1][0].
        local startY is temperatureSunMultCurve[0][1].
        local endY is temperatureSunMultCurve[temperatureSunMultCurve:length-1][1].
        local keyValues is getKeyValues(10, temperatureSunMultCurve).
        local beginKey is keyValues[0].
        local endKey is keyValues[1].
        local hermiteInterpolatorFunction is hermiteInterpolator@:bind(beginKey[0],endKey[0],beginKey[1],endKey[1],beginKey[3],endKey[2]).

        return {// kosDelegate :: float -> float
            parameter       shipAltitude is selectedShip:altitude.
            if (shipAltitude > endKey[0]) or (shipAltitude < beginKey[0]) {
                if shipAltitude <= startX return startY.
                else if shipAltitude >= endX return endY.
                set keyValues to getKeyValues(shipAltitude, temperatureSunMultCurve).
                set beginKey to keyValues[0].
                set endKey to keyValues[1].
                set hermiteInterpolatorFunction to hermiteInterpolator@:bind(beginKey[0],endKey[0],beginKey[1],endKey[1],beginKey[3],endKey[2]).
            }
            return hermiteInterpolatorFunction(shipAltitude). }.
    }

    function getStaticAmbientTemperature {
        // PUBLIC getStaticAmbientTemperature :: bool -> kosDelegate
        // Returns static ambient temperature at selected altitude, geoposition and future time
        // fastMethod determines if the lighter version is used
        parameter       fastMethod is False.

        local getLatTemp is getTemperatureLatitudeBias().
        local getLatVarTemp is getTemperatureLatitudeSunMult().
        local getAltVarTemp is getTemperatureSunMult().
        local localTime is 0.
        local shipLatitude is 0.
        local altTemp is 0.
        local latTemp is 0.
        local latVarTemp is 0.
        local altVarTemp is 0.
        local atmosphereTemperatureOffset is 0.
        local counter is 1E10.
        
        if fastMethod return {// kosDelegate :: float : geoposition : float : float -> float
            // This method has an updateInterval parameter which determines how often latitude information is updated
            // This significantly decreases computation time
            parameter       shipAltitude is selectedShip:altitude,
                            shipLocation is selectedShip:geoposition,
                            timeToCalc is 0,
                            updateInterval is 10.

            if counter > updateInterval {
                set localTime to Timer:Scalar(shipLocation, timeToCalc, currentBody).
                set shipLatitude to abs(shipLocation:lat).
                set latTemp to getLatTemp(shipLatitude).
                set latVarTemp to getLatVarTemp(shipLatitude).
                set atmosphereTemperatureOffset to latTemp + (latVarTemp*localTime).
                set counter to 0.
            }
            set altTemp to currentBody:atm:alttemp(shipAltitude).
            set altVarTemp to getAltVarTemp(shipAltitude).

            set counter to counter + 1.
            return altTemp + (atmosphereTemperatureOffset*altVarTemp).
        }. 

        else return {// kosDelegate :: float : geoposition : float -> float
            // Checks all curves every update for the most accurate data, but slowest
            parameter       shipAltitude is selectedShip:altitude,
                            shipLocation is selectedShip:geoposition,
                            timeToCalc is 0,
                            updateInterval is 0. //not used here

            set localTime to Timer:Scalar(shipLocation, timeToCalc, currentBody).
            set shipLatitude to abs(shipLocation:lat).
            set altTemp to currentBody:atm:alttemp(shipAltitude).
            set latTemp to getLatTemp(shipLatitude).
            set latVarTemp to getLatVarTemp(shipLatitude).
            set atmosphereTemperatureOffset to latTemp + (latVarTemp*localTime).
            set altVarTemp to getAltVarTemp(shipAltitude).

            return altTemp + (atmosphereTemperatureOffset*altVarTemp).
        }.
    }

    function getInstantAmbientTemperature {
        // PUBLIC getStaticAmbientTemperature :: scalar : scalar -> kosDelegate
        // Returns static ambient temperature at the vessel's current state
        // This should be the fastest method of obtaining SAT
        parameter       timeToCalc is 0,
                        updateInterval is 10.

        local shipLocation is currentShip:geoposition.
        local getLatTemp is getTemperatureLatitudeBias().
        local getLatVarTemp is getTemperatureLatitudeSunMult().
        local getAltVarTemp is getTemperatureSunMult().
        local localTime is 0.
        local shipLatitude is 0.
        local altTemp is 0.
        local latTemp is 0.
        local latVarTemp is 0.
        local altVarTemp is 0.
        local atmosphereTemperatureOffset is 0.
        local counter is 1E10.
        
        return {// kosDelegate :: -> float
            if counter > updateInterval {
                set shipLocation to currentShip:geoposition.
                set localTime to Timer:InstScalar().
                set shipLatitude to abs(shipLocation:lat).
                set latTemp to getLatTemp(shipLatitude).
                set latVarTemp to getLatVarTemp(shipLatitude).
                set atmosphereTemperatureOffset to latTemp + (latVarTemp*localTime).
                set counter to 0.
            }
            set altTemp to currentBody:atm:alttemp(currentShip:altitude).
            set altVarTemp to getAltVarTemp(currentShip:altitude).

            set counter to counter + 1.
            return altTemp + (atmosphereTemperatureOffset*altVarTemp).
        }. 
    }

    function getFullAtmosphericData {
        // PUBLIC getFullAtmosphericData :: bool -> kosDelegate
        // Returns all atmospheric data
        parameter           fastMethod is false.

        local PRES is 0.
        local RHO is 0.
        local VM is 0.
        local MN is 0.
        local EAS is 0.
        local dynamicPressure is 0.
        local getSAT is getStaticAmbientTemperature(fastMethod).
        local SAT is 0.
        local OAT is 0.

        return {// kosDelegate :: float : float : geoposition : float : float -> lexicon
            parameter       TAS is ship:velocity:surface:mag,
                            shipAltitude is ship:altitude,
                            shipLocation is ship:geoposition,
                            timeToCalc is 0,
                            updateInterval is 10.

            set SAT to getSAT(shipAltitude, shipLocation, timeToCalc, updateInterval).
            set OAT to SAT-273.15.
            set PRES to max(currentBody:atm:altitudepressure(shipAltitude)*constant:atmtokpa*1000, 1E-10).
            set RHO to (PRES/(SGC*SAT)).
            set VM to (sqrt(adiabaticIndex * SGC * SAT)).
            set MN to TAS/VM.  
            set EAS to (TAS / sqrt(1.225/RHO)).
            set dynamicPressure to 0.5 * RHO * TAS^2.

            return lexicon(
                "SAT", SAT,
                "OAT", OAT,
                "PRES", PRES,
                "RHO", RHO,
                "VM", VM,
                "MN", MN,
                "EAS", EAS,
                "TAS", TAS,
                "Q", dynamicPressure
            ).
        }.
    }

    // Gets the float curves for the parameter body
    getFloatCurves().

    // Returns 2 delegates
    return lexicon(
        "getSAT", getStaticAmbientTemperature@,
        "InstSAT", getInstantAmbientTemperature@,
        "getDATA", getFullAtmosphericData@,
        "bodyParameters", bodyParameters
    ).
}

