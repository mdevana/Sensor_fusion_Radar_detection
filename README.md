# Sensor_fusion_Radar_detection

## Goal
This repository contains Matlab files that illustrates Radar Detection of a target using methods like Doppler and CFAR cell averaging. In this project, the Radar behavior is modeled using sender and receiver signal. From this Signal, the position of a object needs to estimated using methods likes 1-D FFT, 2-D FFT and CA- CFAR. This project is executed as Udacity Sensor Fusion Nanodegree Program.


## Radar Perception
Radar technology is increasingly used for advanced driver assistance systems (ADAS) to detect objects in the vicinity of the car. The advancements in the RF technologies and Digital Signal processing have made it possible to design efficient radars at low cost and in smaller sizes. The radar's capability to determine the targets at long range with accurate velocity and spatial information make it an important sensor for self driving applications. Additionally, its capability to sense objects in dark and poor weather (rain, fog) conditions also help it cover the domains where LIDAR or camera may fail. 

## Principle of Radar
Radar works using the transmission and detection of electromagnetic waves. The electromagnetic waves are reflected if they meet an obstacle. If these reflected waves are received again at the place of their origin, then that means an obstacle is in the propagation direction.
The frequency of electromagnetic energy used for radar is unaffected by darkness and also penetrates fog and clouds. This permits radar systems to determine the position of road targets that are invisible to the naked eye because of distance, darkness, or weather.
## FMCW Radar
FMCW radar (Frequency-Modulated Continuous Wave radar) is a special type of radar sensor which radiates continuous transmission power. FMCW radar's ability to measure very small ranges to the target as well as its ability to measure simultaneously the target range and its relative velocity makes it the first choice type of radar for automotive applications.
## Fast Fourier Transform (FFT)
Fast Fourier Transform is used to convert the signal from time domain to frequency domain. Conversion to frequency domain is important to determine the shifts in frequency due to range and doppler. The traveling signal is in time domain. Time domain signal comprises multiple frequency components. In order to separate out all frequency components the FFT technique is used.
## Clutter
Radar not only receives the reflected signals from the objects of interest, but also from the environment and unwanted objects. The backscatter from these unwanted sources is called as clutter. It is important to filter out the clutter to successfully detect a target. Various techniques are used to filter out the clutter or noise. Some techniques include filtering out zero doppler velocity, fixed thresholding and dynamic thresholding.
## CFAR 
The false alarm issue can be resolved by implementing the constant false alarm rate. CFAR varies the detection threshold based on the vehicle surroundings. The CFAR technique estimates the level of interference in radar range and doppler cells "Training Cells" on either or both the side of the "Cell Under Test". The estimate is then used to decide if the target is in the Cell Under Test (CUT).
The process loops across all the range cells and decides the presence of target based on the noise estimate. The basis of the process is that when noise is present, the cells around the cell of interest will contain a good estimate of the noise, i.e. it assumes that the noise or interference is spatially or temporarily homogeneous. Theoretically it will produce a constant false alarm rate, which is independent of the noise or clutter level
## 2-D CFAR Implementation 
CFAR processing start with creation of Range Doppler Map using 2D FFT. To obtain Range Doppler Map ,the following steps are executed
1. Subtracting the received signal  from the transmitted signal to produce the beat signal or frequency shift which holds the values for both range as well as doppler.  This signal calculated as elementwise multiplication of transmit signal and received signal.
2. Reshaping the beat signal into number of chirps(Nd) and number of times a chirp is sampled(Nr). In this project, Nd is set as 128 and Nr as 1024.
3. On the reshaped the matrix , 2D FFT is executed followed by extracting only one side of range dimension with a frequency shift.
4. The resulting signals is then converted to logarithmic scale to create a Range Doppler Map.

# Selection of Training, guard cells and offset
1. For each Cell under Test (CUT) , we need a set of cells to average out the signal to detect the noise level. This is defined by the variable Tr and Td for both range and doppler dimentions. For this project a value of 8 and 6 are selected which is in proportion to Nr and Nd and gives adequate number of cells to average the noise.
2. For each Cell under Test (CUT) , we need a set of cells to seperate the training cells from the CUT cell. This is defined by the variables Gr and Gd which are set equally to 4, which ensures zero leakage of signal from CUT cell to training cell.
3. To set the threshold for target detection, a constant number or offset is added to average noise calculated from training cells. This offset is calculated such that a robust threshold value is obtained to detect the real target. The value set here is 10 in db.

# Suppression of non thresholded values
By computing the possible cell average of Range Doppler Matrix and applying the threshold, a thresholded block matrix is generated with 1's in cells where is signal is above the average noise level. This matrix is however smaller than Range Doppler matrix as CUT cannot be located at the edges of the matrix. The following code is will ensure the non-thresholded cells are set to zero as well.

```
off_threshold = 0;
block(1 : Tr + Gr,:) = off_threshold;
block(Nr/2 - (Tr + Gr) + 1 : end, : ) = off_threshold;
block(:, 1 : Td + Gd) = off_threshold;
block(:, Nd - (Td + Gd) + 1 : end  ) = off_threshold;
```

# Results
1. The image contains a frequency peak obtained using 1D - FFT at around 111 m from the current postion indicating a object.

![test](https://github.com/mdevana/Sensor_fusion_Radar_detection/blob/main/Images/FFT1_image.png)


2. The image shows the Range Doppler Map indicating a moving target at 111 m moving at 20 m/s 

![test](https://github.com/mdevana/Sensor_fusion_Radar_detection/blob/main/Images/FFt2_image.png)

3. The image shows result of CFAR processing of Range Doppler Map which indicates the presence of object at 111 m and velocity of 20 m/s 
and noise suppression.

![test](https://github.com/mdevana/Sensor_fusion_Radar_detection/blob/main/Images/Cfar_image.png)
