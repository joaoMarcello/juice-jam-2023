from csv import reader
import cv2
import numpy as np
from tomlkit import string

frames = np.empty(shape=(3, 4))
frames = []
img = cv2.imread('./goomba.png')

with open('frames.txt') as file:
    csv_reader = reader(file)
    header = next(csv_reader)

    if header is not None:
        # Iterate over each row after the header in the csv
        for row in csv_reader:
            # row variable is a list that represents a row in csv
            print(row)
            list.append(frames, [int(i) for i in row])
frames = np.array(frames)

c = 1
cropped = []
for frame in frames:
    x = frame[0]
    y = frame[1]
    w = frame[2]
    h = frame[3]

    crop = np.copy(img)[y:y+h, x:x+w]
    list.append(cropped, crop)
    cv2.imwrite('frame_' + '{:0>4}'.format(c) + '.png', crop)
    c += 1


# print('maior: ', np.max(cropped))

# Y: Y + H,   X: X + W
# crop = np.copy(img)[19:19+70, 149:149+60]
# cv2.imshow('_', crop)
# cv2.imwrite('frame_test.png', crop)
# cv2.waitKey(0)
# cv2.destroyAllWindows()
