# Import math Library
import math

# https://www.youtube.com/watch?v=mZiR9Bd6bS8

class Vector():
    """Vector."""
    def __init__(self, x, y, z):
        self.x = round(x, 4)
        self.y = round(y, 4)
        self.z = round(z, 4)
    def __str__(self):
        return "(x="+str(self.x)+", y="+str(self.y)+", z="+str(self.z)+")"

    def __eq__(self, other):
        if isinstance(other, Vector):
            return (self.x == other.x) and (self.y == other.y) and (self.z == other.z)
        else:
            return false

class Record():
    """Record."""
    def __init__(self, vector, result):
        self.vector = vector
        self.result = result
    def __str__(self):
        return "v="+str(self.vector)+"; r="+str(self.result)

results= []
results.append(Record(Vector(0, 0 ,0), 					Vector(1.0, 0, 0)))
results.append(Record(Vector(math.pi/2, 0, 0), 			Vector(1.0, 0, 0)))
results.append(Record(Vector(0, math.pi/2, 0),			Vector(0, 0, -1.0)))
results.append(Record(Vector(0, 0, math.pi/2),			Vector(0, 1.0, 0)))
results.append(Record(Vector(0, 0, math.pi),			Vector(-1, 0, 0)))
results.append(Record(Vector(math.pi, 0, math.pi),		Vector(-1, 0, 0)))
results.append(Record(Vector(0, math.pi*3/4, 0),		Vector(-0.7071, 0, -0.7071)))
results.append(Record(Vector(0, math.pi*3/4, math.pi),	Vector(0.7071, 0, -0.7071)))
results.append(Record(Vector(math.pi*3/4, 0, math.pi/2),Vector(0, -0.7071, 0.7071)))
#results.append(Record(Vector(-3.141526, -0.554879, -3.141574),Vector(0, -0.7071, 0.7071)))

cos=math.cos;
sin=math.sin;
pi = math.pi;

"""
    b = z
    a = y
    g = x
"""

def rotate_vector(v):
    x,y,z=v.x,v.y, v.z;

    return Vector(
        cos(z)*cos(y),
        cos(x)*sin(z)*cos(y)+sin(x)*sin(y),
        sin(x)*sin(z)*cos(y)-cos(x)*sin(y)
    )

def check_vector(i, v, r):
    e = rotate_vector(v)
    if e == r:
        print("-PASS in " + str(i)+ " " + str(v)+ " = " + str(e)+ " = " + str(r));
        return True
    else:
        print("*Error in " + str(i)+ " " + str(v)+ " = " + str(e)+ " |= " + str(r));
        return False

def check_all():
    i = 0
    for rec in results:
        check_vector(i, rec.vector, rec.result)
        i = i + 1

"""
print(pi)
print(math.cos(0.0))
print(math.pi/2.0)
print(math.cos(math.pi/2.0))
print(math.cos(0.0)*math.cos(math.pi/2.0))
"""
check_all()