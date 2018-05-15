# 3D_photo_controller
 Program for controlling stepper motor driver and shutter of camera to make 3D photo of goods
 controller ATtiny2313A
 internal oscillator used, configured for 8MHz
 ratio factor from motor shaft to platform thru gears 1/20
 signals from controller to driver are:
				pin 14 (PB2) - CLK
				pin 13 (PB1) - DIRECTION
				pin 11 (PD6) - ENABLE
				pin 16 (PB4) - SHUTTER OF CAMERA
 keyboard for controlling options:
				pin 2 (PD0)	 - 8 pictures around
				pin 17 (PB5) - 16 pictures around
				pin 18 (PB6) - 32 pict around
				pin 19 (PB7) - 50 pict around
				pin 3 (PD1)  - Reversal
				pin 6 (PD2)  - one step Clockwise
				pin 7 (PD3)	 - one step Counterclockise
				pin 8 (PD4)	 - Enable/Disable
				pin 12 (PB0) - Stop
  Created: 28.11.2013 13:48:31
