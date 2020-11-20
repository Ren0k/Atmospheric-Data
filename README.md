# Complete atmospheric data model for all atmospheric planets

This method returns exact atmospheric data, using the same method that KSP uses, but re-created in kOS.  
Temperature in particular was the missing data unobtainable with kOS, and this is the main focus of this method.  

## Install  

Simply put the folder 'atmoData' in your KSP/Ships/Script folder.  

## Use  

From a script enter runpath("atmoData/getAtmoData.ks"). 

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
4) altVarTemp = altVarTemp.floatcurve(shipLatitude)  

5) localTime = (vdot(upVector-45lng, sunVector)+1)/2  
6) atmosphereTemperatureOffset = latTemp + (latVarTemp * localTime)  

7) SAT = altTemp + (atmosphereTemperatureOffset * altVarTemp)  

### Floatcurves  
I have explained these [curves](https://github.com/Ren0k/Project-Atmospheric-Drag#hermite) in another project.
