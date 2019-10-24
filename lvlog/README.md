# LabVIEW logging for vis3d

The `CubeLogger` class provides an interface to log heterogeneous data to a [.json/.cube binary format](SPEC.md) from LabVIEW applications.

### Features

* Compatible with [the MATLAB package](../ML) 
* Designed for *Actor Framework* applications
  * Actors or other types of state-machines commit logs based on a pre-determined 
  * Ensures correct log order under fully parallel operation

### Requirements

* [JKI JSON](https://github.com/JKISoftware/JKI-JSON-Serialization) for JSON encoding

