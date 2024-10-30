import math
import sys

############################ IMPORTANT NOTICE: ############################

# This is an incomplete script. It is not meant to be used to model accurate
# CORDIC results; do NOT use this script as a reference for your high-level
# script or for verilog verification; you must confirm your results with the
# CORDIC expected mathematical output (see doc/CORDIC_paper.pdf)

############################ IMPORTANT NOTICE: ############################


# Use:
# python3.11 cordic_sim.py
#
# Inputs are set in ./cordic_input
# Outputs are displayed in ./cordic_output


# Number of CORDIC Rotations to perform (12 in this case)
uRotations = 0,1,2,3,4,5,6,7,8,9,10,11

#Cordic Place Holder Values
k = 0.607352 # Set based on number of cordic rotations. Equavalent to 1/K_m
x_r = 1      # Placeholder
y_r = 2      # Placeholder
z_r = 3      # Placeholder
mode = 0     # Placeholder

# Open Input File and store lines
with open('cordic_input.txt') as f:
  lines = f.readlines()
# Open Output File to record outputs
f2 = open('cordic_output.txt', 'w')


for line in lines:
  # Parse Input File
  args = line.split(",")
  for arg in args:
    arg = arg.replace(" ", "")
    if arg.split("=")[0].__eq__("x"):
      x_r = float(arg.split("=")[1])
    elif arg.split("=")[0].__eq__("y"):
      y_r = float(arg.split("=")[1])
    elif arg.split("=")[0].__eq__("z"):
      z_r = float(arg.split("=")[1])
    elif arg.split("=")[0].__eq__("func"):
      if arg.split("=")[1].__eq__("rot"):
        mode = 0
      elif arg.split("=")[1].__eq__("vec"):
        mode = 1
      else: 
        print ("ERROR 2: NO VALID MODE")
        exit()
    else:
      print ("ERROR 1: NO VALID VARIABLE")
      exit()

  # Correct for overflow
  if not mode:
    if z_r > 1.74533:
      x_r = -x_r
      y_r = -y_r
      z_r -= math.pi
    elif z_r < -1.74533:
      x_r = -x_r
      y_r = -y_r
      z_r += math.pi

  if not mode:  # Mode == Rotation
    for rot in uRotations:
      
      # Set Sigma
      if z_r == 0:
        sigma = 1
      else:
        sigma = (z_r / abs(z_r))
    
      # Cordic Math
      y_r2 = y_r
      z_r = z_r - sigma * float("%.4f" % math.atan(2**(-rot)))
      y_r = y_r + sigma * (2**-rot) * x_r
      x_r = x_r - sigma * (2**-rot) * y_r2

  else:   # Mode == Vectoring
    for rot in uRotations:

      # Set Sigma
      if y_r == 0 and x_r == 0:
        sigma = -1
      elif y_r == 0:
        sigma = -(x_r / abs(x_r))
      elif x_r == 0:
        sigma = -(y_r / abs(y_r))
      else:
        sigma = -(y_r / abs(y_r) * x_r / abs(x_r))
      
      # Cordic Math
      y_r2 = y_r
      z_r = z_r - sigma * float("%.4f" % math.atan(2**(-rot)))
      y_r = y_r + sigma * (2**-rot) * x_r
      x_r = x_r - sigma * (2**-rot) * y_r2
  
  # Scale final output by 1/Km
  x_r = x_r * k
  y_r = y_r * k
  z_r = z_r

  # Write to output file
  with open('cordic_output.txt', 'a') as f2:
    print("x=" + "%.4f" % x_r + ", y=" + "%.4f" % y_r + ", z=" + "%.4f" %z_r, file=f2)
  
  # Print to Console
  print("x=" + "%.4f" % x_r + ", y=" + "%.4f" % y_r + ", z=" + "%.4f" %z_r)
