# Atmospheric data model for all atmospheric planets

This method returns exact atmospheric data, using the same method that KSP uses, but re-created in kOS.  
Temperature in particular was the missing data unobtainable with kOS, and this is the main focus of this method.  

## Install  

Put the folder 'atmoData' in your KSP/Ships/Script folder.  

## Use  

See the example:
- Run both Time.ks and AtmoData.ks.
- Init the function you want
- To change to a different planet, reset the function with the required planet

## Quick Guide  

An example is provided, called 'useAtmoData.ks'. This should get you on your way.  
Use it by runpath("atmoData/useAtmoData.ks"). 

A method that can be used to speed up the calculations even more, is by reducing the amount of latitude curve updates, since they do not change a lot over time.  
The example provided will demonstrate how to do that.  

## How does it work?  

### Method
It uses the same method that KSP uses for getting temperature:  

1) altTemp = altTemp.floatcurve(shipAltitude)  
2) latTemp = latTemp.floatcurve(shipLatitude)  
3) latVarTemp = latVarTemp.floatcurve(shipLatitude)  
4) altVarTemp = altVarTemp.floatcurve(shipAltitude)  
5) localTime = (vdot(upVector-45lng, sunVector)+1)/2  
6) atmosphereTemperatureOffset = latTemp + (latVarTemp * localTime)  
7) SAT = altTemp + (atmosphereTemperatureOffset * altVarTemp)  

### Floatcurves  
I have explained these [curves](https://github.com/Ren0k/Project-Atmospheric-Drag) in another project.
