extends Resource
class_name SawbladeStats

## The number of sawblades orbiting the player
@export var amount: int = 2
## The size of the sawblades
@export var size: float = 1.0
## The radious at which the orbit
@export var radius := 2.5
## Orbiting speed in radians / second
@export var speed: float = 0.5
## sekunder mellan träffar på samma fiende
@export var rehit_interval := 0.5