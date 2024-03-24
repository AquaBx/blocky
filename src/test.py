import numpy as np
from matplotlib import image, pyplot as plt
import cv2
import pygame
import random

a = 256
pas = int(a/2-1)

def generate_perlin_noise_2d(shape, res):
    def f(t):
        return 6*t**5 - 15*t**4 + 10*t**3

    delta = (res[0] / shape[0], res[1] / shape[1])
    d = (shape[0] // res[0], shape[1] // res[1])
    grid = np.mgrid[0:res[0]:delta[0],0:res[1]:delta[1]].transpose(1, 2, 0) % 1
    # Gradients
    angles = 2*np.pi*np.random.rand(res[0]+1, res[1]+1)
    gradients = np.dstack((np.cos(angles), np.sin(angles)))
    g00 = gradients[0:-1,0:-1].repeat(d[0], 0).repeat(d[1], 1)
    g10 = gradients[1:,0:-1].repeat(d[0], 0).repeat(d[1], 1)
    g01 = gradients[0:-1,1:].repeat(d[0], 0).repeat(d[1], 1)
    g11 = gradients[1:,1:].repeat(d[0], 0).repeat(d[1], 1)
    # Ramps
    n00 = np.sum(grid * g00, 2)
    n10 = np.sum(np.dstack((grid[:,:,0]-1, grid[:,:,1])) * g10, 2)
    n01 = np.sum(np.dstack((grid[:,:,0], grid[:,:,1]-1)) * g01, 2)
    n11 = np.sum(np.dstack((grid[:,:,0]-1, grid[:,:,1]-1)) * g11, 2)
    # Interpolation
    t = f(grid)
    n0 = n00*(1-t[:,:,0]) + t[:,:,0]*n10
    n1 = n01*(1-t[:,:,0]) + t[:,:,0]*n11
    return np.sqrt(2)*((1-t[:,:,1])*n0 + t[:,:,1]*n1)

# image = generate_perlin_noise_2d((256,256),(4,4))

def generateChunk(x,y,seed) :
    random.seed(seed+x+y*65535)
    return random.random()

def generateE(x,y,seed) :
    random.seed(seed+x+y*65535)
    return random.random()

def generateF(x,y,seed) :
    random.seed(seed+x+y*65535)
    return random.random()

def generateG(x,y,seed) :
    random.seed(seed+x+y*65535)
    return random.random()

def blur(x,y,i): 
    tot = 0
    sumat = 0
    for xi in range(0,i):
        for yi in range(0,i):

            chunkx = (x+xi) // i
            chunky = (y+yi) // i

            at = i - ( (xi - i/2 )**2 + (yi - i/2)**2 )**0.5

            sumat += at
            tot += generateChunk(chunkx,chunky,564654)*at
    return tot/sumat

def generateBlocksChunk(x,y) :

    return (blur(x,y,7) + blur(x,y,11) + blur(x,y,15))/3


image = []



for i in range(128):
    liste = []
    for j in range(128):
        liste.append( 100 + int( generateBlocksChunk(i,j) * 40 ) )
    image.append(liste)


plt.imshow(image,  cmap='Greys', interpolation='nearest')
plt.show()
